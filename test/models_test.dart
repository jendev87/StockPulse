import 'package:flutter_test/flutter_test.dart';
import 'package:stockpulse/models/enums.dart';
import 'package:stockpulse/models/product.dart';
import 'package:stockpulse/models/stock_count.dart';
import 'package:stockpulse/models/stock_take.dart';
import 'package:stockpulse/models/discrepancy.dart';

void main() {
  group('Domain Models & Discrepancy Tests', () {
    const testProduct = Product(
      sku: 'P001',
      name: 'Coca Cola 500ml',
      barcode: '5449000000996',
      hasBarcode: true,
      systemQty: 25,
      visualDescription: 'Red bottle with Coca Cola logo',
    );

    test('Discrepancy.calculate returns Match when physical == system', () {
      final discrepancy = Discrepancy.calculate(
        product: testProduct,
        physicalQty: 25,
      );

      expect(discrepancy.variance, 0);
      expect(discrepancy.type, DiscrepancyType.match);
      expect(discrepancy.sku, 'P001');
      expect(discrepancy.productName, 'Coca Cola 500ml');
    });

    test('Discrepancy.calculate returns Shortage when physical < system', () {
      final discrepancy = Discrepancy.calculate(
        product: testProduct,
        physicalQty: 20,
      );

      expect(discrepancy.variance, -5);
      expect(discrepancy.type, DiscrepancyType.shortage);
    });

    test('Discrepancy.calculate returns Surplus when physical > system', () {
      final discrepancy = Discrepancy.calculate(
        product: testProduct,
        physicalQty: 30,
      );

      expect(discrepancy.variance, 5);
      expect(discrepancy.type, DiscrepancyType.surplus);
    });

    test('JSON serialization round-trip works for models', () {
      final count = StockCount(
        id: 'c1',
        stockTakeId: 'st1',
        sku: 'P001',
        physicalQty: 25,
        method: IdentificationMethod.barcode,
        confidence: 1.0,
        timestamp: DateTime(2026, 9, 30, 12, 0),
      );

      final json = count.toJson();
      final fromJson = StockCount.fromJson(json);

      expect(fromJson.sku, count.sku);
      expect(fromJson.physicalQty, 25);
      expect(fromJson.method, IdentificationMethod.barcode);

      final stockTake = StockTake(
        id: 'st1',
        status: StockTakeStatus.inProgress,
        createdAt: DateTime(2026, 9, 30, 11, 0),
        counts: [count],
      );

      final stJson = stockTake.toJson();
      final stFromJson = StockTake.fromJson(stJson);

      expect(stFromJson.id, 'st1');
      expect(stFromJson.status, StockTakeStatus.inProgress);
      expect(stFromJson.counts.length, 1);
    });
  });
}
