import '../models/discrepancy.dart';
import '../models/enums.dart';
import '../models/product.dart';
import '../models/stock_count.dart';
import '../models/stock_take.dart';
import 'inventory_repository.dart';

class MockInventoryRepository implements InventoryRepository {
  MockInventoryRepository({List<Product>? initialProducts}) {
    _products = initialProducts ?? _seedCatalog();
  }

  static final MockInventoryRepository instance = MockInventoryRepository();

  static List<Product> _seedCatalog() {
    return const [
      Product(
        sku: 'P001',
        name: 'Coca Cola 500ml',
        barcode: '5449000000996',
        hasBarcode: true,
        systemQty: 25,
        visualDescription:
            'Red label, cylindrical plastic bottle with black liquid and white script logo',
      ),
      Product(
        sku: 'P002',
        name: 'Pepsi 500ml',
        barcode: '012000000133',
        hasBarcode: true,
        systemQty: 20,
        visualDescription:
            'Blue bottle/can with circular red, white, and blue globe logo',
      ),
      Product(
        sku: 'P003',
        name: 'Lays Classic Chips',
        barcode: '028400017145',
        hasBarcode: true,
        systemQty: 15,
        visualDescription:
            'Bright yellow bag with circular red and yellow Lay\'s sun logo',
      ),
      Product(
        sku: 'P004',
        name: 'KitKat 4-Finger',
        barcode: '5000159461122',
        hasBarcode: true,
        systemQty: 30,
        visualDescription:
            'Red rectangular candy bar pack with white oval KitKat logo',
      ),
      Product(
        sku: 'P005',
        name: 'Tomato Sauce Bottle',
        barcode: null,
        hasBarcode: false,
        systemQty: 12,
        visualDescription:
            'Glass or squeeze bottle with red condiment sauce and green cap',
      ),
      Product(
        sku: 'P006',
        name: 'Digestive Biscuits',
        barcode: null,
        hasBarcode: false,
        systemQty: 18,
        visualDescription:
            'Cylindrical roll pack of wheat biscuits in brown/tan packaging',
      ),
      Product(
        sku: 'P007',
        name: 'Mineral Water 1L',
        barcode: '8901764012235',
        hasBarcode: true,
        systemQty: 40,
        visualDescription:
            'Clear transparent plastic water bottle with blue label and blue cap',
      ),
      Product(
        sku: 'P008',
        name: 'Orange Juice Carton',
        barcode: null,
        hasBarcode: false,
        systemQty: 10,
        visualDescription:
            'Rectangular paper carton with pictures of oranges and screw-on cap',
      ),
      Product(
        sku: 'P009',
        name: 'Dairy Milk Chocolate',
        barcode: '7622210286153',
        hasBarcode: true,
        systemQty: 22,
        visualDescription:
            'Deep purple wrapper with Cadbury gold cursive lettering',
      ),
      Product(
        sku: 'P010',
        name: 'Loose Red Apples',
        barcode: null,
        hasBarcode: false,
        systemQty: 16,
        visualDescription:
            'Fresh round red fruit/produce without packaging',
      ),
    ];
  }

  late List<Product> _products;
  final Map<String, StockTake> _stockTakes = {};
  StockTake? _activeStockTake;
  int _sessionCounter = 1;

  Future<void> _simulateLatency() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<List<Product>> getProducts() async {
    await _simulateLatency();
    return List.unmodifiable(_products);
  }

  @override
  Future<Product?> getProductBySku(String sku) async {
    await _simulateLatency();
    try {
      return _products.firstWhere((p) => p.sku.toUpperCase() == sku.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    await _simulateLatency();
    try {
      return _products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StockTake> startStockTake() async {
    await _simulateLatency();
    final id = 'ST-${_sessionCounter.toString().padLeft(3, '0')}';
    _sessionCounter++;

    final stockTake = StockTake(
      id: id,
      status: StockTakeStatus.inProgress,
      createdAt: DateTime.now(),
      counts: const [],
    );

    _stockTakes[id] = stockTake;
    _activeStockTake = stockTake;
    return stockTake;
  }

  @override
  Future<StockTake?> getActiveStockTake() async {
    await _simulateLatency();
    return _activeStockTake;
  }

  @override
  Future<void> recordCount(StockCount count) async {
    await _simulateLatency();
    final active = _activeStockTake;
    if (active == null) {
      throw StateError('Cannot record count without an active stock take');
    }

    final updatedCounts = List<StockCount>.from(active.counts);
    final existingIndex = updatedCounts.indexWhere((c) => c.sku == count.sku);

    if (existingIndex >= 0) {
      updatedCounts[existingIndex] = count;
    } else {
      updatedCounts.add(count);
    }

    final updatedStockTake = active.copyWith(counts: updatedCounts);
    _stockTakes[updatedStockTake.id] = updatedStockTake;
    _activeStockTake = updatedStockTake;
  }

  @override
  Future<List<Discrepancy>> getReconciliation(String stockTakeId) async {
    await _simulateLatency();
    final stockTake = _stockTakes[stockTakeId] ?? _activeStockTake;
    final countsMap = <String, StockCount>{};

    if (stockTake != null) {
      for (final count in stockTake.counts) {
        countsMap[count.sku] = count;
      }
    }

    return _products.map((product) {
      final count = countsMap[product.sku];
      final physicalQty = count?.physicalQty ?? 0;
      return Discrepancy.calculate(product: product, physicalQty: physicalQty);
    }).toList();
  }

  @override
  Future<void> approveStockTake(String stockTakeId) async {
    await _simulateLatency();
    final stockTake = _stockTakes[stockTakeId];
    if (stockTake == null) {
      throw StateError('Stock take with id $stockTakeId not found');
    }

    final approvedStockTake = stockTake.copyWith(status: StockTakeStatus.approved);
    _stockTakes[stockTakeId] = approvedStockTake;
    if (_activeStockTake?.id == stockTakeId) {
      _activeStockTake = approvedStockTake;
    }

    // Update in-memory product list: systemQty becomes physicalQty for counted items
    final countsMap = {for (final c in stockTake.counts) c.sku: c.physicalQty};
    _products = _products.map((product) {
      if (countsMap.containsKey(product.sku)) {
        return product.copyWith(systemQty: countsMap[product.sku]!);
      }
      return product;
    }).toList();
  }

  @override
  Future<void> submitForApproval(String stockTakeId) async {
    await _simulateLatency();
    final stockTake = _stockTakes[stockTakeId] ?? _activeStockTake;
    if (stockTake == null) return;
    final updated = stockTake.copyWith(status: StockTakeStatus.pendingApproval);
    _stockTakes[stockTakeId] = updated;
    if (_activeStockTake?.id == stockTakeId) {
      _activeStockTake = updated;
    }
  }
}

