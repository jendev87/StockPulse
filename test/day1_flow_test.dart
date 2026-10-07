import 'package:flutter_test/flutter_test.dart';
import 'package:stockpulse/main.dart';
import 'package:stockpulse/repositories/mock_inventory_repository.dart';

void main() {
  testWidgets('Complete Day 1 Stock Take UI Flow', (WidgetTester tester) async {
    final repository = MockInventoryRepository();

    // 1. Boot App
    await tester.pumpWidget(StockPulseApp(inventoryRepository: repository));
    await tester.pumpAndSettle();

    // Verify Dashboard
    expect(find.text('StockPulse'), findsWidgets);
    expect(find.text('Warehouse Store #104'), findsOneWidget);
    expect(find.text("Start Today's Stock Take"), findsOneWidget);

    // 2. Start Stock Take
    await tester.tap(find.text("Start Today's Stock Take"));
    await tester.pumpAndSettle();

    // Verify Stock Take Screen
    expect(find.text('Physical Stock Count'), findsOneWidget);
    expect(find.text('Coca Cola 500ml'), findsOneWidget);
    expect(find.text('Pepsi 500ml'), findsOneWidget);

    // 3. Tap on Coca Cola 500ml to Count
    await tester.tap(find.text('Coca Cola 500ml'));
    await tester.pumpAndSettle();

    // Verify Count Screen
    expect(find.text('Count: P001'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);

    // Ensure +5 chip is visible and tap twice to increment
    await tester.ensureVisible(find.text('+5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+5'));
    await tester.pump();
    await tester.tap(find.text('+5'));
    await tester.pump();

    // Ensure Save Count button is visible on test viewport and tap it
    final saveButton = find.text('Save Count');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // 4. Back on Stock Take Screen - should be counted
    expect(find.text('Physical Stock Count'), findsOneWidget);
    expect(find.text('Counted'), findsOneWidget);

    // Allow any transient snackbars to dismiss
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // 5. Navigate to Reconciliation
    final reviewButton = find.text('Review Reconciliation');
    expect(reviewButton, findsOneWidget);
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();

    // Verify Reconciliation Screen
    expect(find.text('Reconciliation Review'), findsOneWidget);
    expect(find.text('Matched'), findsOneWidget);
    expect(find.text('Shortages'), findsOneWidget);
    expect(find.text('Surpluses'), findsOneWidget);

    // 6. Submit for Manager Approval / Commit to ERP
    final approveButton = find.text('Approve & Commit to ERP');
    expect(approveButton, findsOneWidget);
    await tester.tap(approveButton);
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Commit to ERP'), findsOneWidget);
    expect(
      find.text('This will commit stock adjustments to SQLite system inventory.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirm & Commit'));
    await tester.pumpAndSettle();

    // 7. Back on Dashboard with success banner
    expect(find.text('Warehouse Store #104'), findsOneWidget);
    expect(find.textContaining('Approved'), findsWidgets);
    expect(find.text('Approved & Synced'), findsOneWidget);
    expect(find.textContaining('Mock ERP ID: ERP-SYNC'), findsOneWidget);
    expect(find.text('SYNCED'), findsWidgets);
  });
}
