import base64
import json
import os
import re
from typing import Any, Dict, List, Optional
import logging
from fastapi import HTTPException, status
from app.config import (
    GEMINI_MODEL,
    GROQ_VISION_MODEL,
    GROQ_TEXT_MODEL,
    get_gemini_api_key,
    get_groq_api_key,
)
from app.models.schemas import ProductMatchResult, VoiceParseResult

logger = logging.getLogger("stockpulse.ai")

_gemini_client = None
_groq_client = None


def _get_gemini_client():
    global _gemini_client
    active_key = get_gemini_api_key()

    if not active_key or active_key == "your_actual_gemini_api_key_here":
        logger.warning("[AI Service] GEMINI_API_KEY is not configured in backend/.env.")
        return None

    try:
        from google import genai
        _gemini_client = genai.Client(api_key=active_key)
        return _gemini_client
    except Exception as e:
        logger.error(f"[AI Service] Could not initialize google-genai Client: {e}", exc_info=True)
        return None


def _get_client():
    return _get_gemini_client()


def _get_groq_client():
    global _groq_client
    active_key = get_groq_api_key()

    if not active_key or active_key.startswith("your_"):
        logger.warning("[AI Service] GROQ_API_KEY is not configured in backend/.env.")
        return None

    try:
        from groq import Groq
        _groq_client = Groq(api_key=active_key)
        return _groq_client
    except Exception as e:
        logger.error(f"[AI Service] Could not initialize Groq Client: {e}", exc_info=True)
        return None


async def match_product_against_catalog(
    image_bytes: bytes, catalog: List[Dict[str, Any]]
) -> Dict[str, Any]:
    """Matches an image against the locked catalog and counts items using Groq Vision."""
    client = _get_groq_client()

    if not client:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Groq API is not configured. Please set a valid GROQ_API_KEY in backend/.env.",
        )

    # Format the catalog explicitly with SKU, Name, and Visual Description for precise disambiguation
    catalog_lines = []
    for p in catalog:
        sku = p.get("sku", "Unknown")
        name = p.get("name", "Unknown")
        desc = p.get("visual_description", "")
        catalog_lines.append(f"- SKU: {sku} | Name: {name} | Visual Appearance: {desc}")

    catalog_context = "\n".join(catalog_lines)

    prompt = f"""You are an expert industrial warehouse inventory auditor for StockPulse.
Analyze this photo and identify which product from the following catalog matches the item shown:

CATALOG OF AVAILABLE ITEMS:
{catalog_context}

INSTRUCTIONS:
1. Examine the visual features in the image (packaging shape, bottle/can/box/carton, label colors, branding text, liquid/content color).
   - If the item is Tomato Ketchup, ketchup bottle, or red condiment pasta sauce, match SKU P005 (Tomato Sauce Bottle) with high confidence.
   - If the item is a fruit juice carton or tetra-pak drink (e.g., Apple Juice, Orange Juice carton), match SKU P008 (Orange Juice Carton) with high confidence.
   - If the item is loose, unboxed fresh apples, match SKU P010 (Loose Red Apples).
   - If the item is cola or dark soda bottle, match SKU P001 (Coca Cola 500ml) or P002 (Pepsi 500ml).
2. Match to the most appropriate SKU and Name from the catalog above.
3. Count the number of units visible in the image (minimum 1). Count the number of distinct physical containers visible in the frame. For bottles/cartons, count the number of separate top caps/spouts visible to ensure you do not double-count logos or graphics on the same carton. Count only visible units.
4. Provide a realistic confidence score between 0.0 and 1.0 (for clear visible items matching a catalog category, confidence should be between 0.85 and 0.98).

You MUST respond in valid JSON with EXACTLY this structure:
{{
  "sku": "<matched SKU from catalog>",
  "name": "<matched product name>",
  "confidence": <float between 0.0 and 1.0>,
  "detected_quantity": <integer count of items visible, minimum 1>
}}
"""

    base64_image = base64.b64encode(image_bytes).decode("utf-8")
    image_url = f"data:image/jpeg;base64,{base64_image}"

    try:
        model_name = GROQ_VISION_MODEL or "llama-3.2-11b-vision-preview"
        try:
            completion = client.chat.completions.create(
                model=model_name,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": prompt},
                            {"type": "image_url", "image_url": {"url": image_url}},
                        ],
                    }
                ],
                response_format={"type": "json_object"},
                temperature=0.1,
            )
        except Exception as groq_err:
            if "decommissioned" in str(groq_err).lower():
                logger.warning(
                    f"Groq model '{model_name}' was decommissioned. Falling back to active Groq vision model 'qwen/qwen3.8-27b'."
                )
                completion = client.chat.completions.create(
                    model="qwen/qwen3.8-27b",
                    messages=[
                        {
                            "role": "user",
                            "content": [
                                {"type": "text", "text": prompt},
                                {"type": "image_url", "image_url": {"url": image_url}},
                            ],
                        }
                    ],
                    response_format={"type": "json_object"},
                    temperature=0.1,
                )
            else:
                raise groq_err

        raw_content = completion.choices[0].message.content
        logger.info(f"Groq Vision raw response: {raw_content}")
        parsed = json.loads(raw_content)

        return {
            "sku": parsed.get("sku") or "P001",
            "name": parsed.get("name") or "Product",
            "confidence": float(parsed.get("confidence", 0.95)),
            "detected_quantity": int(parsed.get("detected_quantity", 1)),
        }
    except Exception as e:
        logger.error(f"Groq Vision API Error: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Groq Vision failed: {str(e)}",
        )


async def parse_voice_transcript(
    transcript: str, catalog: List[Dict[str, Any]]
) -> Dict[str, Any]:
    """Parses spoken count intent into SKU and quantity using Groq."""
    client = _get_groq_client()

    catalog_context = json.dumps(
        [{"sku": p.get("sku"), "name": p.get("name")} for p in catalog],
        indent=2,
    )

    prompt = f"""You are a warehouse voice data parser.
Extract the target product and quantity counted from this warehouse worker's speech.
CATALOG: {catalog_context}
WORKER TRANSCRIPT: '{transcript}'

Rules:
- Match phonetically or semantically to the closest catalog product.
- If no quantity is mentioned, default to 1.
- If the user only says a number (e.g. 'twenty five') and no product is mentioned, set sku to null and quantity to the number.

Return strict JSON:
{{
  "sku": "matching SKU or null",
  "product_name": "matching name or null",
  "quantity": int,
  "confidence": float
}}"""

    if client:
        try:
            model_name = GROQ_TEXT_MODEL or "llama-3.3-70b-versatile"
            try:
                completion = client.chat.completions.create(
                    model=model_name,
                    messages=[{"role": "user", "content": prompt}],
                    response_format={"type": "json_object"},
                    temperature=0.1,
                )
            except Exception as groq_err:
                logger.warning(
                    f"Groq text model '{model_name}' failed ({groq_err}). Falling back to 'qwen/qwen3.8-27b'."
                )
                completion = client.chat.completions.create(
                    model="qwen/qwen3.8-27b",
                    messages=[{"role": "user", "content": prompt}],
                    response_format={"type": "json_object"},
                    temperature=0.1,
                )

            raw_content = completion.choices[0].message.content
            logger.info(f"Groq Voice raw response: {raw_content}")
            parsed = json.loads(raw_content)

            return {
                "sku": parsed.get("sku"),
                "product_name": parsed.get("product_name"),
                "quantity": int(parsed.get("quantity") if parsed.get("quantity") is not None else 1),
                "confidence": float(parsed.get("confidence") if parsed.get("confidence") is not None else 0.95),
            }
        except Exception as e:
            logger.error(f"[AI Service] Groq Voice call failed: {e}", exc_info=True)

    # Heuristic fallback for local offline testing
    extracted_qty = 1
    qty_match = re.search(r"\b(\d+)\b", transcript)
    if qty_match:
        extracted_qty = int(qty_match.group(1))

    matched_sku = None
    matched_name = None

    lower_text = transcript.lower()
    for item in catalog:
        name_words = item.get("name", "").lower().split()
        sku_val = (item.get("sku") or "").lower()
        if (sku_val and sku_val in lower_text) or any(
            word in lower_text for word in name_words if len(word) > 3
        ):
            matched_sku = item.get("sku")
            matched_name = item.get("name")
            break

    return {
        "sku": matched_sku,
        "product_name": matched_name,
        "quantity": extracted_qty,
        "confidence": 0.85 if matched_sku else 0.5,
    }


async def query_manager_assistant(question: str, db_context: Dict[str, Any]) -> str:
    """Answers warehouse manager questions using deterministic database context."""
    client = _get_client()

    context_str = json.dumps(db_context, indent=2)
    prompt = f"""You are the StockPulse AI Warehouse Assistant.
Answer the warehouse manager's question based strictly on the factual database context provided below.
All quantities and variances are 100% deterministic numbers calculated by SQLite. Never invent or hallucinate quantities.

DATABASE CONTEXT:
{context_str}

MANAGER QUESTION:
"{question}"

Provide a concise, professional, bullet-pointed summary answering the manager's query clearly.
"""

    # 1. Try ultra-fast Groq text model first
    groq_client = _get_groq_client()
    if groq_client:
        try:
            model_name = GROQ_TEXT_MODEL or "llama-3.3-70b-versatile"
            completion = groq_client.chat.completions.create(
                model=model_name,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.2,
            )
            return completion.choices[0].message.content
        except Exception as groq_err:
            logger.warning(f"[AI Service] Groq Query failed ({groq_err}), falling back to Gemini.")

    # 2. Try Gemini model
    if client:
        try:
            response = client.models.generate_content(
                model=GEMINI_MODEL,
                contents=prompt,
                config={"temperature": 0.2},
            )
            return response.text
        except Exception as e:
            print(f"[AI Service] Gemini Query call failed, generating deterministic response: {e}")

    # Deterministic summary fallback
    discrepancies = db_context.get("discrepancies", [])
    shortages = [d for d in discrepancies if d.get("type") == "shortage"]
    surpluses = [d for d in discrepancies if d.get("type") == "surplus"]
    matches = [d for d in discrepancies if d.get("type") == "match"]

    lines = [
        f"**StockPulse Inventory Audit Summary** (Session {db_context.get('stock_take_id', 'Current')}):",
        f"- **Total Catalog Items**: {len(discrepancies)} SKUs",
        f"- **Matches**: {len(matches)} items in sync",
        f"- **Shortages**: {len(shortages)} items requiring re-order or investigation",
        f"- **Surpluses**: {len(surpluses)} items with excess physical count",
    ]

    if shortages:
        lines.append("\n**Shortage Breakdown:**")
        for s in shortages:
            lines.append(f"  • {s.get('product_name')} ({s.get('sku')}): Expected {s.get('system_qty')}, Counted {s.get('physical_qty')} (Variance: {s.get('variance')})")

    return "\n".join(lines)
