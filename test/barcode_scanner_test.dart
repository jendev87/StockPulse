import 'package:flutter_test/flutter_test.dart';
import 'package:stockpulse/main.dart';
import 'package:stockpulse/repositories/mock_inventory_repository.dart';

void main() {
  group('Barcode Scanner & Resolution Tests', () {
    late MockInventoryRepository repository;

    setUp(() {
      repository = MockInventoryRepository();
    });

    test('Query barcode returns correct product for known barcodes', () async {
      // P001: Coca Cola 500ml
      final coke = await repository.getProductByBarcode('5449000000996');
      expect(coke, isNotNull);
      expect(coke!.sku, 'P001');
      expect(coke.name, 'Coca Cola 500ml');

      // P002: Pepsi 500ml
      final pepsi = await repository.getProductByBarcode('012000000133');
      expect(pepsi, isNotNull);
      expect(pepsi!.sku, 'P002');
      expect(pepsi.name, 'Pepsi 500ml');

      // P003: Lays Classic Chips
      final lays = await repository.getProductByBarcode('028400017145');
      expect(lays, isNotNull);
      expect(lays!.sku, 'P003');

      // P004: KitKat 4-Finger
      final kitkat = await repository.getProductByBarcode('5000159461122');
      expect(kitkat, isNotNull);
      expect(kitkat!.sku, 'P004');

      // P007: Mineral Water 1L
      final water = await repository.getProductByBarcode('8901764012235');
      expect(water, isNotNull);
      expect(water!.sku, 'P007');

      // P009: Dairy Milk Chocolate
      final cadbury = await repository.getProductByBarcode('7622210286153');
      expect(cadbury, isNotNull);
      expect(cadbury!.sku, 'P009');
    });

    test('Query barcode returns null for unknown barcodes or null-barcode items', () async {
      final unknown = await repository.getProductByBarcode('9999999999999');
      expect(unknown, isNull);

      final empty = await repository.getProductByBarcode('');
      expect(empty, isNull);
    });

    testWidgets('StockTakeScreen contains Scan Barcode actions', (WidgetTester tester) async {
      await tester.pumpWidget(StockPulseApp(inventoryRepository: repository));
      await tester.pumpAndSettle();

      // Start stock take to reach stock take screen
      await tester.tap(find.text("Start Today's Stock Take"));
      await tester.pumpAndSettle();

      // Check for Scan Barcode FAB
      expect(find.text('Scan Barcode'), findsOneWidget);
    });
  });
}
