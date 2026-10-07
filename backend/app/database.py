from __future__ import annotations
import sqlite3
from contextlib import contextmanager
from typing import Generator
from app.config import DATABASE_PATH

FROZEN_CATALOG = [
    (
        "P001",
        "Coca Cola 500ml",
        "5449000000996",
        1,
        25,
        "Red label, cylindrical plastic bottle with black liquid and white script logo",
    ),
    (
        "P002",
        "Pepsi 500ml",
        "012000000133",
        1,
        20,
        "Blue bottle/can with circular red, white, and blue globe logo",
    ),
    (
        "P003",
        "Lays Classic Chips",
        "028400017145",
        1,
        15,
        "Bright yellow bag with circular red and yellow Lay's sun logo",
    ),
    (
        "P004",
        "KitKat 4-Finger",
        "5000159461122",
        1,
        30,
        "Red rectangular candy bar pack with white oval KitKat logo",
    ),
    (
        "P005",
        "Tomato Sauce Bottle",
        None,
        0,
        12,
        "Glass or squeeze bottle with red condiment sauce and green cap",
    ),
    (
        "P006",
        "Digestive Biscuits",
        None,
        0,
        18,
        "Cylindrical roll pack of wheat biscuits in brown/tan packaging",
    ),
    (
        "P007",
        "Mineral Water 1L",
        "8901764012235",
        1,
        40,
        "Clear transparent plastic water bottle with blue label and blue cap",
    ),
    (
        "P008",
        "Orange Juice Carton",
        None,
        0,
        10,
        "Rectangular paper carton with pictures of oranges and screw-on cap",
    ),
    (
        "P009",
        "Dairy Milk Chocolate",
        "7622210286153",
        1,
        22,
        "Deep purple wrapper with Cadbury gold cursive lettering",
    ),
    (
        "P010",
        "Loose Red Apples",
        None,
        0,
        16,
        "Fresh round red fruit/produce without packaging",
    ),
]


def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    return conn


@contextmanager
def get_db() -> Generator[sqlite3.Connection, None, None]:
    conn = get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def init_db() -> None:
    with get_db() as conn:
        cursor = conn.cursor()

        # 1. Products table
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sku TEXT UNIQUE NOT NULL,
                name TEXT NOT NULL,
                barcode TEXT,
                has_barcode BOOLEAN NOT NULL,
                system_qty INTEGER NOT NULL,
                visual_description TEXT NOT NULL
            );
            """
        )

        # 2. Stock takes table
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS stock_takes (
                id TEXT PRIMARY KEY,
                status TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """
        )

        # 3. Stock counts table
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS stock_counts (
                id TEXT PRIMARY KEY,
                stock_take_id TEXT NOT NULL,
                sku TEXT NOT NULL,
                physical_qty INTEGER NOT NULL,
                method TEXT NOT NULL,
                confidence REAL NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (stock_take_id) REFERENCES stock_takes(id),
                UNIQUE(stock_take_id, sku)
            );
            """
        )

        # 4. Adjustments table
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS adjustments (
                id TEXT PRIMARY KEY,
                stock_take_id TEXT NOT NULL,
                sku TEXT NOT NULL,
                old_qty INTEGER NOT NULL,
                new_qty INTEGER NOT NULL,
                variance INTEGER NOT NULL,
                approved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (stock_take_id) REFERENCES stock_takes(id)
            );
            """
        )

        # Seed frozen 10-item catalog if products table is empty
        cursor.execute("SELECT COUNT(*) as count FROM products;")
        count = cursor.fetchone()["count"]

        if count == 0:
            cursor.executemany(
                """
                INSERT INTO products (sku, name, barcode, has_barcode, system_qty, visual_description)
                VALUES (?, ?, ?, ?, ?, ?);
                """,
                FROZEN_CATALOG,
            )
            print(f"[DB] Initialized database and seeded {len(FROZEN_CATALOG)} frozen catalog products.")
