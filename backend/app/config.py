from __future__ import annotations
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Locate and load .env file from backend directory
BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / ".env"

if ENV_PATH.exists():
    load_dotenv(dotenv_path=ENV_PATH)
else:
    load_dotenv()

def get_gemini_api_key() -> str:
    """Reloads .env if present and returns the active API key."""
    if ENV_PATH.exists():
        load_dotenv(dotenv_path=ENV_PATH, override=True)
    return os.getenv("GEMINI_API_KEY", "").strip()

def get_groq_api_key() -> str:
    """Reloads .env if present and returns the active Groq API key."""
    if ENV_PATH.exists():
        load_dotenv(dotenv_path=ENV_PATH, override=True)
    return os.getenv("GROQ_API_KEY", "").strip()

GEMINI_API_KEY = get_gemini_api_key()
GROQ_API_KEY = get_groq_api_key()
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-3.5-flash").strip()
GROQ_VISION_MODEL = os.getenv("GROQ_VISION_MODEL", "llama-3.2-11b-vision-preview").strip()
GROQ_TEXT_MODEL = os.getenv("GROQ_TEXT_MODEL", "llama-3.3-70b-versatile").strip()
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", "8000"))
DATABASE_PATH = BASE_DIR / "stockpulse.db"

if not GEMINI_API_KEY or GEMINI_API_KEY == "your_actual_gemini_api_key_here":
    print(
        "[WARNING] GEMINI_API_KEY is not set or contains the default placeholder in backend/.env.\n"
        "AI endpoints will require a valid Gemini API key to operate.",
        file=sys.stderr,
    )
