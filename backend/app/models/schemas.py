from __future__ import annotations
from typing import Optional, List
from pydantic import BaseModel, Field


class ProductResponse(BaseModel):
    id: int
    sku: str
    name: str
    barcode: Optional[str] = None
    has_barcode: bool
    system_qty: int
    visual_description: str


class StockTakeResponse(BaseModel):
    id: str
    status: str
    created_at: str


class StockCountCreate(BaseModel):
    sku: str
    physical_qty: int = Field(ge=0)
    method: str = "manual"
    confidence: float = 1.0


class StockCountResponse(BaseModel):
    id: str
    stock_take_id: str
    sku: str
    physical_qty: int
    method: str
    confidence: float
    created_at: str


class DiscrepancyResponse(BaseModel):
    sku: str
    product_name: str
    system_qty: int
    physical_qty: int
    variance: int
    type: str  # 'match', 'shortage', 'surplus'


class ReconciliationSummaryResponse(BaseModel):
    stock_take_id: str
    status: str
    discrepancies: List[DiscrepancyResponse]
    matched_count: int
    shortage_count: int
    surplus_count: int


class ProductMatchResult(BaseModel):
    sku: str
    name: str
    confidence: float
    detected_quantity: int


class VoiceParseRequest(BaseModel):
    transcript: str
    catalog: Optional[List[dict]] = None


class VoiceParseResult(BaseModel):
    sku: Optional[str] = None
    product_name: Optional[str] = None
    quantity: int = 1
    confidence: float = 1.0


class ManagerQueryRequest(BaseModel):
    question: str
    stock_take_id: Optional[str] = None
