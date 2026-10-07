# StockPulse — 4-Day AI Stock Take POC Guidelines

## 1. Project Identity & Purpose
- **App Name**: StockPulse (`com.stockpulse.app`)
- **Mission**: Replace manual clipboard/spreadsheet inventory counts with a guided digital workflow:
  Physical Capture (Barcode / Vision / Voice / Manual) 
    → Deterministic Variance Reconciliation 
    → Manager Discrepancy Review & NL Assistant 
    → ERP/System Update.

---

## 2. Technical Stack & Architectural Layers
- **Client**: Flutter 3.x (Dart) with `flutter_bloc`, `go_router`, `freezed`, `dio`.
- **Backend (Day 4 Target)**: FastAPI (Python) + SQLite + Gemini API.
- **Current Mode (Days 1–3)**: Standalone offline-first. All data operations MUST pass through the abstract `InventoryRepository` interface backed initially by `MockInventoryRepository`.
- **State Management**: BLoC pattern only. UI widgets never directly mutate repository data or store business calculation logic.

---

## 3. Strict Operating Guardrails for AI Agent
1. **Dependency Lock**: DO NOT add any third-party Flutter packages or plugins to `pubspec.yaml` unless explicitly instructed in a prompt.
2. **Deterministic Reconciliation**: Variances (`physicalQty - systemQty`) and discrepancy types (`match`, `shortage`, `surplus`) are 100% deterministic math. NEVER use an LLM or probabilistic model to calculate quantities or differences.
3. **API Key Security**: The Gemini API key will NEVER be embedded in the Flutter client. All AI calls flow through FastAPI (`/ai/*`) on Day 4.
4. **No Premature Backend Integration**: Keep Day 1–3 strictly running against `MockInventoryRepository` until the Day 4 API cutover prompt.

---

## 4. Frozen 10-Item Master Catalog
All mock repositories, database seeds, tests, vision prompts, and barcode matches MUST strictly adhere to this exact 10-SKU catalog:

| SKU | Product Name | Barcode | Has Barcode | System Qty | Visual Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **P001** | Coca Cola 500ml | 5449000000996 | true | 25 | Red label, cylindrical bottle, black liquid, white script |
| **P002** | Pepsi 500ml | 012000000133 | true | 20 | Blue bottle/can, circular red/white/blue globe logo |
| **P003** | Lays Classic Chips | 028400017145 | true | 15 | Bright yellow bag, red/yellow circular sun logo |
| **P004** | KitKat 4-Finger | 5000159461122 | true | 30 | Red rectangular bar pack, white oval KitKat logo |
| **P005** | Tomato Sauce Bottle | *None* | false | 12 | Glass/squeeze bottle, red condiment sauce, green cap |
| **P006** | Digestive Biscuits | *None* | false | 18 | Cylindrical roll pack of wheat biscuits, brown wrapping |
| **P007** | Mineral Water 1L | 8901764012235 | true | 40 | Clear bottle, transparent liquid, blue label and cap |
| **P008** | Orange Juice Carton | *None* | false | 10 | Rectangular paper carton, orange fruit illustration |
| **P009** | Dairy Milk Chocolate | 7622210286153 | true | 22 | Deep purple foil wrapper, Cadbury gold cursive text |
| **P010** | Loose Red Apples | *None* | false | 16 | Fresh unbagged round red produce |

---

## 5. Visual Theme & Color Token Standards
- **Background**: `#121418` (Dark industrial slate)
- **Cards/Surfaces**: `#1E222B`
- **Primary / Action**: `#3B82F6` (Electric Blue)
- **Status - Match**: `#10B981` (Emerald Green)
- **Status - Shortage**: `#EF4444` (Crimson Red)
- **Status - Surplus**: `#F59E0B` (Amber Gold)
