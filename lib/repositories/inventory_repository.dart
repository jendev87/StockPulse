import '../models/discrepancy.dart';
import '../models/product.dart';
import '../models/stock_count.dart';
import '../models/stock_take.dart';

abstract class InventoryRepository {
  Future<List<Product>> getProducts();
  Future<Product?> getProductBySku(String sku);
  Future<Product?> getProductByBarcode(String barcode);
  Future<StockTake> startStockTake();
  Future<StockTake?> getActiveStockTake();
  Future<void> recordCount(StockCount count);
  Future<List<Discrepancy>> getReconciliation(String stockTakeId);
  Future<void> approveStockTake(String stockTakeId);
  Future<void> submitForApproval(String stockTakeId);
}

