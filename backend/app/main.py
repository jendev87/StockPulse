from __future__ import annotations
import json
import uuid
from typing import Any, Dict, List, Optional
from fastapi import FastAPI, File, Form, HTTPException, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from app.config import HOST, PORT
from app.database import get_db, init_db
from app.models.schemas import (
    DiscrepancyResponse,
    ManagerQueryRequest,
    ProductResponse,
    ReconciliationSummaryResponse,
    StockCountCreate,
    StockCountResponse,
    StockTakeResponse,
    VoiceParseRequest,
)
from app.services import ai_service

app = FastAPI(
    title="StockPulse AI Backend",
    version="1.0.0",
    description="FastAPI + SQLite + Gemini AI stock-taking backend for StockPulse",
)

# Enable CORS for mobile application integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    init_db()


@app.get("/health", tags=["System"])
def health_check():
    return {"status": "ok", "app": "StockPulse AI Backend"}


@app.get("/products", response_model=List[ProductResponse], tags=["Catalog"])
def get_products():
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM products ORDER BY sku ASC;")
        rows = cursor.fetchall()
        return [dict(r) for r in rows]


@app.get("/products/{sku}", response_model=ProductResponse, tags=["Catalog"])
def get_product_by_sku(sku: str):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM products WHERE UPPER(sku) = UPPER(?);", (sku,))
        row = cursor.fetchone()
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Product with SKU '{sku}' not found in catalog.",
            )
        return dict(row)


@app.post("/stock-takes", response_model=StockTakeResponse, tags=["Stock Take"])
def create_stock_take():
    with get_db() as conn:
        cursor = conn.cursor()
        # Generate session sequence ID (e.g., ST-001)
        cursor.execute("SELECT COUNT(*) as count FROM stock_takes;")
        count = cursor.fetchone()["count"]
        session_id = f"ST-{(count + 1):03d}"

        cursor.execute(
            "INSERT INTO stock_takes (id, status) VALUES (?, ?);",
            (session_id, "in_progress"),
        )
        cursor.execute("SELECT * FROM stock_takes WHERE id = ?;", (session_id,))
        row = cursor.fetchone()
        return dict(row)


@app.post(
    "/stock-takes/{stock_take_id}/counts",
    response_model=StockCountResponse,
    tags=["Stock Take"],
)
def record_count(stock_take_id: str, count_in: StockCountCreate):
    with get_db() as conn:
        cursor = conn.cursor()

        # Validate stock take existence and status
        cursor.execute("SELECT * FROM stock_takes WHERE id = ?;", (stock_take_id,))
        stock_take = cursor.fetchone()
        if not stock_take:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Stock take session '{stock_take_id}' not found.",
            )

        # Validate product
        cursor.execute(
            "SELECT * FROM products WHERE UPPER(sku) = UPPER(?);", (count_in.sku,)
        )
        product = cursor.fetchone()
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Product '{count_in.sku}' does not exist.",
            )

        normalized_sku = product["sku"]
        count_id = f"count_{uuid.uuid4().hex[:8]}"

        # Upsert count by SKU
        cursor.execute(
            """
            INSERT INTO stock_counts (id, stock_take_id, sku, physical_qty, method, confidence)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(stock_take_id, sku) DO UPDATE SET
                physical_qty = excluded.physical_qty,
                method = excluded.method,
                confidence = excluded.confidence,
                created_at = CURRENT_TIMESTAMP;
            """,
            (
                count_id,
                stock_take_id,
                normalized_sku,
                count_in.physical_qty,
                count_in.method,
                count_in.confidence,
            ),
        )

        cursor.execute(
            "SELECT * FROM stock_counts WHERE stock_take_id = ? AND sku = ?;",
            (stock_take_id, normalized_sku),
        )
        row = cursor.fetchone()
        return dict(row)


@app.get(
    "/stock-takes/{stock_take_id}/reconciliation",
    response_model=ReconciliationSummaryResponse,
    tags=["Reconciliation"],
)
def get_reconciliation(stock_take_id: str):
    with get_db() as conn:
        cursor = conn.cursor()

        cursor.execute("SELECT * FROM stock_takes WHERE id = ?;", (stock_take_id,))
        stock_take = cursor.fetchone()
        if not stock_take:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Stock take session '{stock_take_id}' not found.",
            )

        # Retrieve all products
        cursor.execute("SELECT * FROM products ORDER BY sku ASC;")
        products = cursor.fetchall()

        # Retrieve recorded counts for this session
        cursor.execute(
            "SELECT * FROM stock_counts WHERE stock_take_id = ?;", (stock_take_id,)
        )
        counts_map = {row["sku"]: row["physical_qty"] for row in cursor.fetchall()}

        discrepancies: List[Dict[str, Any]] = []
        matched = 0
        shortage = 0
        surplus = 0

        for p in products:
            sku = p["sku"]
            system_qty = p["system_qty"]
            physical_qty = counts_map.get(sku, 0)
            variance = physical_qty - system_qty

            if variance == 0:
                disc_type = "match"
                matched += 1
            elif variance < 0:
                disc_type = "shortage"
                shortage += 1
            else:
                disc_type = "surplus"
                surplus += 1

            discrepancies.append(
                {
                    "sku": sku,
                    "product_name": p["name"],
                    "system_qty": system_qty,
                    "physical_qty": physical_qty,
                    "variance": variance,
                    "type": disc_type,
                }
            )

        return {
            "stock_take_id": stock_take_id,
            "status": stock_take["status"],
            "discrepancies": discrepancies,
            "matched_count": matched,
            "shortage_count": shortage,
            "surplus_count": surplus,
        }


@app.post("/stock-takes/{stock_take_id}/approve", tags=["Reconciliation"])
def approve_stock_take(stock_take_id: str):
    with get_db() as conn:
        cursor = conn.cursor()

        cursor.execute("SELECT * FROM stock_takes WHERE id = ?;", (stock_take_id,))
        stock_take = cursor.fetchone()
        if not stock_take:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Stock take '{stock_take_id}' not found.",
            )

        cursor.execute("SELECT * FROM stock_counts WHERE stock_take_id = ?;", (stock_take_id,))
        counts = cursor.fetchall()

        # Update product system quantities and record adjustments
        for c in counts:
            sku = c["sku"]
            phys_qty = c["physical_qty"]

            cursor.execute("SELECT system_qty FROM products WHERE sku = ?;", (sku,))
            prod = cursor.fetchone()
            if prod:
                old_qty = prod["system_qty"]
                variance = phys_qty - old_qty
                adj_id = f"adj_{uuid.uuid4().hex[:8]}"

                cursor.execute(
                    """
                    INSERT INTO adjustments (id, stock_take_id, sku, old_qty, new_qty, variance)
                    VALUES (?, ?, ?, ?, ?, ?);
                    """,
                    (adj_id, stock_take_id, sku, old_qty, phys_qty, variance),
                )
                cursor.execute(
                    "UPDATE products SET system_qty = ? WHERE sku = ?;",
                    (phys_qty, sku),
                )

        cursor.execute(
            "UPDATE stock_takes SET status = 'approved' WHERE id = ?;",
            (stock_take_id,),
        )

        return {
            "status": "approved",
            "stock_take_id": stock_take_id,
            "message": f"Stock Take {stock_take_id} approved and inventory synchronized successfully.",
            "synced_items_count": len(counts),
        }


# --- AI Endpoints ---


@app.post("/ai/identify-product", tags=["AI Endpoints"])
async def identify_product(
    file: UploadFile = File(...),
    catalog_json: Optional[str] = Form(None),
):
    """Identifies item and quantity from an uploaded photo against the catalog."""
    image_bytes = await file.read()
    file_size_kb = len(image_bytes) / 1024.0
    catalog_chars = len(catalog_json) if catalog_json else 0
    print(
        f"[AI Identify] Received upload file '{file.filename}': {file_size_kb:.2f} KB | catalog_json length: {catalog_chars} chars"
    )

    catalog: List[Dict[str, Any]] = []
    if catalog_json:
        try:
            catalog = json.loads(catalog_json)
        except Exception as e:
            print(f"[AI Identify] Warning: could not parse catalog_json: {e}")

    if not catalog:
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT sku, name, visual_description FROM products;")
            catalog = [dict(r) for r in cursor.fetchall()]

    print(f"[AI Identify] Analyzing image against {len(catalog)} catalog items...")
    result = await ai_service.match_product_against_catalog(image_bytes, catalog)
    print(f"[AI Identify] Result: SKU={result.get('sku')}, Name='{result.get('name')}', Confidence={result.get('confidence')}, Qty={result.get('detected_quantity')}")
    return result


@app.post("/ai/parse-voice", tags=["AI Endpoints"])
async def parse_voice(request: VoiceParseRequest):
    """Parses spoken natural language transcript into inventory SKU and count."""
    catalog = request.catalog
    if not catalog:
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT sku, name FROM products;")
            catalog = [dict(r) for r in cursor.fetchall()]

    result = await ai_service.parse_voice_transcript(request.transcript, catalog)
    return result


@app.post("/ai/query", tags=["AI Endpoints"])
async def query_manager(request: ManagerQueryRequest):
    """Answers warehouse manager questions using deterministic database context."""
    db_context: Dict[str, Any] = {}

    session_id = request.stock_take_id
    if not session_id:
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT id FROM stock_takes ORDER BY created_at DESC LIMIT 1;"
            )
            latest = cursor.fetchone()
            if latest:
                session_id = latest["id"]

    if session_id:
        try:
            reconciliation = get_reconciliation(session_id)
            db_context = reconciliation
        except Exception as e:
            logger.warning(f"Could not load reconciliation for {session_id}: {e}")
            with get_db() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT sku, name, system_qty FROM products;")
                db_context = {"catalog": [dict(r) for r in cursor.fetchall()]}
    else:
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT sku, name, system_qty FROM products;")
            db_context = {"catalog": [dict(r) for r in cursor.fetchall()]}

    answer = await ai_service.query_manager_assistant(request.question, db_context)
    return {
        "question": request.question,
        "stock_take_id": request.stock_take_id or session_id,
        "response": answer,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host=HOST, port=PORT, reload=True)
