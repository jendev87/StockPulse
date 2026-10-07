import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockpulse/core/router/app_router.dart';
import 'package:stockpulse/features/stock_take/widgets/barcode_scan_bottom_sheet.dart';
import 'package:stockpulse/main.dart';
import 'package:stockpulse/repositories/mock_inventory_repository.dart';

void main() {
  group('CountScreen Multimodal and Dynamic Count Tests', () {
    late MockInventoryRepository repository;

    setUp(() {
      repository = MockInventoryRepository();
      AppRouter.router.go('/');
    });

    testWidgets('Tapping product card navigates to CountScreen with AI Camera & Voice actions',
        (WidgetTester tester) async {
      await tester.pumpWidget(StockPulseApp(inventoryRepository: repository));
      await tester.pumpAndSettle();

      // Start Stock Take
      if (find.text("Start Today's Stock Take").evaluate().isNotEmpty) {
        await tester.tap(find.text("Start Today's Stock Take"));
      } else if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
      }
      await tester.pumpAndSettle();

      // Tap on Lays Classic Chips
      await tester.tap(find.text('Lays Classic Chips'));
      await tester.pumpAndSettle();

      // Verify Count Screen for P003
      expect(find.text('Count: P003'), findsOneWidget);
      expect(find.text('Lays Classic Chips'), findsOneWidget);
      expect(find.text('AI MULTIMODAL COUNTING'), findsOneWidget);
      expect(find.text('AI Camera'), findsOneWidget);
      expect(find.text('AI Voice'), findsOneWidget);

      // Verify quick chips
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
      expect(find.text('+10'), findsOneWidget);
      expect(find.text('Expected (15)'), findsOneWidget);
      expect(find.text('Reset (0)'), findsOneWidget);

      // Tap Reset (0) to set count to 0
      await tester.ensureVisible(find.text('Reset (0)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset (0)'));
      await tester.pumpAndSettle();

      // Verify text field now shows 0
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      final textController = (tester.widget(textField) as TextField).controller;
      expect(textController?.text, '0');

      // Tap +10
      await tester.tap(find.text('+10'));
      await tester.pumpAndSettle();
      expect(textController?.text, '10');

      // Tap +5
      await tester.tap(find.text('+5'));
      await tester.pumpAndSettle();
      expect(textController?.text, '15');

      // Tap Decrement (-)
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(textController?.text, '14');

      // Tap Increment (+)
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(textController?.text, '15');

      // Enter manual text
      await tester.enterText(textField, '22');
      await tester.pumpAndSettle();
      expect(textController?.text, '22');

      // Tap Save Count
      final saveBtn = find.text('Save Count');
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Back on Physical Stock Count screen
      expect(find.text('Physical Stock Count'), findsOneWidget);
      expect(find.text('22'), findsOneWidget);
      expect(find.text('Counted'), findsOneWidget);
    });

    testWidgets('Barcoded items show Barcode Verification card and trigger scan to increment count',
        (WidgetTester tester) async {
      await tester.pumpWidget(StockPulseApp(inventoryRepository: repository));
      await tester.pumpAndSettle();

      // Start or Continue Stock Take
      if (find.text("Start Today's Stock Take").evaluate().isNotEmpty) {
        await tester.tap(find.text("Start Today's Stock Take"));
      } else if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
      }
      await tester.pumpAndSettle();

      // Tap on Coca Cola 500ml (P001 - has barcode 5449000000996)
      await tester.tap(find.text('Coca Cola 500ml'));
      await tester.pumpAndSettle();

      expect(find.text('Count: P001'), findsOneWidget);
      expect(find.text('BARCODE VERIFICATION'), findsOneWidget);
      expect(find.text('5449000000996'), findsOneWidget);
      expect(find.text('Scan Barcode (+1)'), findsOneWidget);
      expect(find.text('AI MULTIMODAL COUNTING'), findsOneWidget);

      // Verify Barcode card appears before AI Multimodal card in layout
      final barcodeTop = tester.getTopLeft(find.text('BARCODE VERIFICATION')).dy;
      final aiTop = tester.getTopLeft(find.text('AI MULTIMODAL COUNTING')).dy;
      expect(barcodeTop, lessThan(aiTop));

      // Tap Scan Barcode button
      await tester.tap(find.text('Scan Barcode (+1)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // BarcodeScanBottomSheet is displayed
      expect(find.text('Scan Item Barcode'), findsOneWidget);
      expect(find.text('Expected: 5449000000996'), findsOneWidget);

      // Trigger barcode detection programmatically in test
      final sheetState = tester.state<BarcodeScanBottomSheetState>(
        find.byType(BarcodeScanBottomSheet),
      );
      sheetState.testTriggerDetection('5449000000996');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Dismiss bottom sheet
      await tester.tap(find.text('Done (1)'));
      await tester.pumpAndSettle();

      // Quantity incremented by 1 (starts at 0 fresh count, now 1)
      final textField = find.byType(TextField);
      final textController = (tester.widget(textField) as TextField).controller;
      expect(textController?.text, '1');
      expect(find.text('BARCODE'), findsOneWidget);
    });

    testWidgets('Non-barcoded items cleanly omit Barcode Verification card',
        (WidgetTester tester) async {
      await tester.pumpWidget(StockPulseApp(inventoryRepository: repository));
      await tester.pumpAndSettle();

      // Start or Continue Stock Take
      if (find.text("Start Today's Stock Take").evaluate().isNotEmpty) {
        await tester.tap(find.text("Start Today's Stock Take"));
      } else if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
      }
      await tester.pumpAndSettle();

      // Scroll to find Tomato Sauce Bottle (P005 - hasBarcode: false)
      await tester.scrollUntilVisible(find.text('Tomato Sauce Bottle'), 100);
      await tester.tap(find.text('Tomato Sauce Bottle'));
      await tester.pumpAndSettle();

      expect(find.text('Count: P005'), findsOneWidget);
      // Barcode verification card must NOT be displayed
      expect(find.text('BARCODE VERIFICATION'), findsNothing);
      expect(find.text('Scan Barcode (+1)'), findsNothing);
      // AI Multimodal card is displayed
      expect(find.text('AI MULTIMODAL COUNTING'), findsOneWidget);
    });
  });
}
