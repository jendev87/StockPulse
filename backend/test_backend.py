from __future__ import annotations
import sys
import os
import asyncio

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database import init_db, get_db
import httpx
from app.main import app


async def test_full_backend():
    print("=" * 60)
    print("StockPulse AI Backend Verification Test")
    print("=" * 60)

    # 1. Initialize SQLite Database
    print("\n[Step 1] Initializing SQLite database...")
    init_db()

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) as count FROM products;")
        prod_count = cursor.fetchone()["count"]
        print(f"  ✓ Products table seeded with {prod_count} items (expected 10).")
        assert prod_count == 10, f"Expected 10 products, found {prod_count}"

    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as client:
        # 2. Test GET /health
        print("\n[Step 2] Testing GET /health...")
        resp = await client.get("/health")
        print(f"  Response ({resp.status_code}): {resp.json()}")
        assert resp.status_code == 200
        assert resp.json()["status"] == "ok"
        print("  ✓ Health check passed.")

        # 3. Test GET /products
        print("\n[Step 3] Testing GET /products...")
        resp = await client.get("/products")
        products = resp.json()
        print(f"  ✓ Retrieved {len(products)} products from /products.")
        assert resp.status_code == 200
        assert len(products) == 10

        # Verify P001 & P005 details
        p001 = next(p for p in products if p["sku"] == "P001")
        assert p001["name"] == "Coca Cola 500ml"
        assert p001["has_barcode"] is True
        assert p001["system_qty"] == 25
        print(f"  ✓ P001 verified: {p001['name']} (System Qty: {p001['system_qty']})")

        p005 = next(p for p in products if p["sku"] == "P005")
        assert p005["name"] == "Tomato Sauce Bottle"
        assert p005["has_barcode"] is False
        assert p005["system_qty"] == 12
        print(f"  ✓ P005 verified: {p005['name']} (System Qty: {p005['system_qty']})")

        # 4. Test GET /products/{sku}
        print("\n[Step 4] Testing GET /products/P003...")
        resp = await client.get("/products/P003")
        assert resp.status_code == 200
        p003 = resp.json()
        assert p003["name"] == "Lays Classic Chips"
        print(f"  ✓ Specific SKU query verified: {p003['name']}")

        # 5. Test Stock Take Creation: POST /stock-takes
        print("\n[Step 5] Testing POST /stock-takes...")
        resp = await client.post("/stock-takes")
        assert resp.status_code == 200
        stock_take = resp.json()
        st_id = stock_take["id"]
        print(f"  ✓ Created stock take session: {st_id} (status: {stock_take['status']})")

        # 6. Test Record Count: POST /stock-takes/{id}/counts
        print(f"\n[Step 6] Testing POST /stock-takes/{st_id}/counts...")
        # Record P001 (Match: 25)
        resp = await client.post(
            f"/stock-takes/{st_id}/counts",
            json={"sku": "P001", "physical_qty": 25, "method": "barcode", "confidence": 1.0},
        )
        assert resp.status_code == 200
        print("  ✓ Counted P001: 25 units (method: barcode)")

        # Record P002 (Shortage: 18 vs 20)
        resp = await client.post(
            f"/stock-takes/{st_id}/counts",
            json={"sku": "P002", "physical_qty": 18, "method": "manual", "confidence": 1.0},
        )
        assert resp.status_code == 200
        print("  ✓ Counted P002: 18 units (method: manual)")

        # Record P003 (Surplus: 19 vs 15)
        resp = await client.post(
            f"/stock-takes/{st_id}/counts",
            json={"sku": "P003", "physical_qty": 19, "method": "ai", "confidence": 0.95},
        )
        assert resp.status_code == 200
        print("  ✓ Counted P003: 19 units (method: ai)")

        # 7. Test Reconciliation: GET /stock-takes/{id}/reconciliation
        print(f"\n[Step 7] Testing GET /stock-takes/{st_id}/reconciliation...")
        resp = await client.get(f"/stock-takes/{st_id}/reconciliation")
        assert resp.status_code == 200
        reconciliation = resp.json()
        discs = reconciliation["discrepancies"]
        assert len(discs) == 10
        print(f"  ✓ Full reconciliation generated for all {len(discs)} items:")
        print(f"    - Matched: {reconciliation['matched_count']}")
        print(f"    - Shortage: {reconciliation['shortage_count']}")
        print(f"    - Surplus: {reconciliation['surplus_count']}")

        p001_d = next(d for d in discs if d["sku"] == "P001")
        assert p001_d["variance"] == 0
        assert p001_d["type"] == "match"

        p002_d = next(d for d in discs if d["sku"] == "P002")
        assert p002_d["variance"] == -2
        assert p002_d["type"] == "shortage"

        p003_d = next(d for d in discs if d["sku"] == "P003")
        assert p003_d["variance"] == 4
        assert p003_d["type"] == "surplus"

        # 8. Test Stock Take Approval: POST /stock-takes/{id}/approve
        print(f"\n[Step 8] Testing POST /stock-takes/{st_id}/approve...")
        resp = await client.post(f"/stock-takes/{st_id}/approve")
        assert resp.status_code == 200
        print(f"  ✓ Approved stock take {st_id}: {resp.json()['message']}")

        # Verify inventory system_qty sync
        resp_p002 = await client.get("/products/P002")
        assert resp_p002.json()["system_qty"] == 18
        print(f"  ✓ P002 system_qty updated to 18 (ERP sync simulated).")

        # 9. Test AI Voice Parsing: POST /ai/parse-voice
        print("\n[Step 9] Testing POST /ai/parse-voice...")
        resp = await client.post(
            "/ai/parse-voice",
            json={"transcript": "Found 12 bottles of Coca Cola"},
        )
        assert resp.status_code == 200
        voice_res = resp.json()
        print(f"  ✓ Voice parser result: {voice_res}")
        assert voice_res["sku"] == "P001"
        assert voice_res["quantity"] == 12

        # 10. Test AI Manager Assistant: POST /ai/query
        print("\n[Step 10] Testing POST /ai/query...")
        resp = await client.post(
            "/ai/query",
            json={"question": "What is the status of our inventory count?", "stock_take_id": st_id},
        )
        assert resp.status_code == 200
        query_res = resp.json()
        print(f"  ✓ Manager assistant responded ({len(query_res['response'])} chars):\n")
        print(query_res["response"])

    print("\n" + "=" * 60)
    print("ALL BACKEND VERIFICATION TESTS PASSED SUCCESSFULLY!")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(test_full_backend())
