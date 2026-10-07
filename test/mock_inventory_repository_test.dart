import 'package:flutter_test/flutter_test.dart';
import 'package:stockpulse/models/enums.dart';
import 'package:stockpulse/models/stock_count.dart';
import 'package:stockpulse/repositories/mock_inventory_repository.dart';

void main() {
  group('MockInventoryRepository Tests', () {
    late MockInventoryRepository repository;

    setUp(() {
      repository = MockInventoryRepository();
    });

    test('Seeded catalog contains exactly 10 frozen items', () async {
      final products = await repository.getProducts();
      expect(products.length, 10);

      final skus = products.map((p) => p.sku).toList();
      expect(skus, [
        'P001',
        'P002',
        'P003',
        'P004',
        'P005',
        'P006',
        'P007',
        'P008',
        'P009',
        'P010',
      ]);

      final p001 = await repository.getProductBySku('P001');
      expect(p001, isNotNull);
      expect(p001!.name, 'Coca Cola 500ml');
      expect(p001.barcode, '5449000000996');
      expect(p001.hasBarcode, true);
      expect(p001.systemQty, 25);

      final p005 = await repository.getProductBySku('P005');
      expect(p005, isNotNull);
      expect(p005!.name, 'Tomato Sauce Bottle');
      expect(p005.barcode, isNull);
      expect(p005.hasBarcode, false);
      expect(p005.systemQty, 12);
    });

    test('Lookup by barcode returns correct product or null', () async {
      final p003 = await repository.getProductByBarcode('028400017145');
      expect(p003, isNotNull);
      expect(p003!.sku, 'P003');
      expect(p003.name, 'Lays Classic Chips');

      final unknown = await repository.getProductByBarcode('999999999');
      expect(unknown, isNull);
    });

    test('Stock take lifecycle: start, recordCount, reconciliation, approval', () async {
      // 1. Start stock take
      final stockTake = await repository.startStockTake();
      expect(stockTake.id, startsWith('ST-'));
      expect(stockTake.status, StockTakeStatus.inProgress);
      expect(stockTake.counts, isEmpty);

      final active = await repository.getActiveStockTake();
      expect(active?.id, stockTake.id);

      // 2. Record count for P001 (Match: system=25, count=25)
      await repository.recordCount(
        StockCount(
          id: 'c1',
          stockTakeId: stockTake.id,
          sku: 'P001',
          physicalQty: 25,
          method: IdentificationMethod.barcode,
          timestamp: DateTime.now(),
        ),
      );

      // 3. Record count for P002 (Shortage: system=20, count=18)
      await repository.recordCount(
        StockCount(
          id: 'c2',
          stockTakeId: stockTake.id,
          sku: 'P002',
          physicalQty: 18,
          method: IdentificationMethod.manual,
          timestamp: DateTime.now(),
        ),
      );

      // 4. Record count for P003 (Surplus: system=15, count=17)
      await repository.recordCount(
        StockCount(
          id: 'c3',
          stockTakeId: stockTake.id,
          sku: 'P003',
          physicalQty: 17,
          method: IdentificationMethod.ai,
          timestamp: DateTime.now(),
        ),
      );

      // Test upsert: re-count P002 to 19
      await repository.recordCount(
        StockCount(
          id: 'c2-updated',
          stockTakeId: stockTake.id,
          sku: 'P002',
          physicalQty: 19,
          method: IdentificationMethod.barcode,
          timestamp: DateTime.now(),
        ),
      );

      // 5. Get reconciliation
      final reconciliation = await repository.getReconciliation(stockTake.id);
      expect(reconciliation.length, 10);

      final p001Disc = reconciliation.firstWhere((d) => d.sku == 'P001');
      expect(p001Disc.type, DiscrepancyType.match);
      expect(p001Disc.physicalQty, 25);
      expect(p001Disc.variance, 0);

      final p002Disc = reconciliation.firstWhere((d) => d.sku == 'P002');
      expect(p002Disc.type, DiscrepancyType.shortage);
      expect(p002Disc.physicalQty, 19);
      expect(p002Disc.variance, -1);

      final p003Disc = reconciliation.firstWhere((d) => d.sku == 'P003');
      expect(p003Disc.type, DiscrepancyType.surplus);
      expect(p003Disc.physicalQty, 17);
      expect(p003Disc.variance, 2);

      // Uncounted items should default physicalQty to 0 (Shortage)
      final p004Disc = reconciliation.firstWhere((d) => d.sku == 'P004');
      expect(p004Disc.type, DiscrepancyType.shortage);
      expect(p004Disc.physicalQty, 0);
      expect(p004Disc.variance, -30);

      // 6. Approve stock take
      await repository.approveStockTake(stockTake.id);

      final updatedP001 = await repository.getProductBySku('P001');
      expect(updatedP001!.systemQty, 25);

      final updatedP002 = await repository.getProductBySku('P002');
      expect(updatedP002!.systemQty, 19); // Updated to physicalQty

      final updatedP003 = await repository.getProductBySku('P003');
      expect(updatedP003!.systemQty, 17); // Updated to physicalQty

      final uncountedP004 = await repository.getProductBySku('P004');
      expect(uncountedP004!.systemQty, 30); // Unchanged because not counted
    });
  });
}
