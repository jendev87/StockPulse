import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockpulse/main.dart';
import 'package:stockpulse/repositories/inventory_repository.dart';
import 'package:stockpulse/repositories/mock_inventory_repository.dart';

void main() {
  group('Dual-Persona Role Switcher Dashboard Tests', () {
    late MockInventoryRepository repository;

    setUp(() {
      repository = MockInventoryRepository();
    });

    Widget createTestApp({InventoryRepository? repo}) {
      return StockPulseApp(inventoryRepository: repo ?? repository);
    }

    testWidgets('Dashboard renders dual role cards defaulting to Floor Associate',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Persona Switcher Cards
      expect(find.text('Floor Associate'), findsOneWidget);
      expect(find.text('Store Manager'), findsOneWidget);
      expect(find.text('Counting & Multi-Modal Capture'), findsOneWidget);
      expect(find.text('Discrepancy Audit & ERP Commit'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);

      // Floor Associate View elements
      expect(find.text('STOCK-TAKE WORKFLOW'), findsOneWidget);
      expect(find.text("Start Today's Stock Take"), findsOneWidget);
    });

    testWidgets('Toggling to Store Manager shows Manager Audit & Reconciliation Hub',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap Store Manager card
      await tester.tap(find.text('Store Manager'));
      await tester.pumpAndSettle();

      // Should display Manager Hub
      expect(find.text('MANAGER AUDIT & RECONCILIATION HUB'), findsOneWidget);
      expect(find.text('No sessions pending review'), findsOneWidget);
      expect(find.text('Switch to Floor Associate'), findsOneWidget);

      // Tap Switch to Floor Associate button
      await tester.tap(find.text('Switch to Floor Associate'));
      await tester.pumpAndSettle();

      // Reverts back to Associate view
      expect(find.text('STOCK-TAKE WORKFLOW'), findsOneWidget);
      expect(find.text("Start Today's Stock Take"), findsOneWidget);
    });

    testWidgets('Associate view displays Quick Tool Row & Submit for Manager Audit',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 1. Start stock take
      await tester.tap(find.text("Start Today's Stock Take"));
      await tester.pumpAndSettle();

      // On StockTakeScreen, verify Associate top badge
      expect(find.text('👷 Associate Floor Mode'), findsOneWidget);

      // Count Coca Cola
      await tester.tap(find.text('Coca Cola 500ml'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('+5'));
      await tester.tap(find.text('+5'));
      await tester.pump();
      await tester.ensureVisible(find.text('Save Count'));
      await tester.tap(find.text('Save Count'));
      await tester.pumpAndSettle();

      // Pop back to Dashboard
      final NavigatorState navigator = tester.state(find.byType(Navigator).first);
      navigator.pop();
      await tester.pumpAndSettle();

      // Back on Dashboard in Associate mode:
      expect(find.text('Continue Stock Take'), findsOneWidget);
      expect(find.text('AI Vision Capture'), findsOneWidget);

      // Scroll ListView slightly to bring Submit to Manager button into view
      await tester.drag(find.byType(ListView), const Offset(0, -250));
      await tester.pumpAndSettle();

      expect(find.text('Submit to Manager for Audit'), findsOneWidget);

      // Tap Submit to Manager for Audit
      await tester.tap(find.text('Submit to Manager for Audit'));
      await tester.pumpAndSettle();



      // Confirmation dialog
      expect(find.text('Submit for Manager Audit'), findsOneWidget);
      await tester.tap(find.text('Submit & Notify Manager'));
      await tester.pumpAndSettle();

      // Prompts user with option to toggle to Store Manager
      expect(find.textContaining('Toggle to Store Manager'), findsOneWidget);
      expect(find.text('Switch to Manager'), findsWidgets);

      // Tap Switch to Manager on SnackBar / Card
      await tester.tap(find.text('Switch to Manager').first);
      await tester.pumpAndSettle();


      // Now on Manager Hub with metrics
      expect(find.text('MANAGER AUDIT & RECONCILIATION HUB'), findsOneWidget);
      expect(find.text('Review Discrepancies & Approve'), findsOneWidget);
      expect(find.text('✨ Ask AI Copilot'), findsOneWidget);
    });

    testWidgets('Manager Hub displays discrepancy metrics and navigates to Reconciliation',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Start today's stock take
      await tester.tap(find.text("Start Today's Stock Take"));
      await tester.pumpAndSettle();

      // Pop back to Dashboard
      final NavigatorState nav = tester.state(find.byType(Navigator).first);
      nav.pop();
      await tester.pumpAndSettle();

      // Switch to Manager
      await tester.tap(find.text('Store Manager'));
      await tester.pumpAndSettle();

      // Summary metrics cards
      expect(find.text('MANAGER AUDIT & RECONCILIATION HUB'), findsOneWidget);
      expect(find.text('Total Items'), findsOneWidget);
      expect(find.text('Shortages'), findsOneWidget);
      expect(find.text('Surpluses'), findsOneWidget);
      expect(find.text('Matches'), findsOneWidget);

      // Verify actions
      expect(find.text('Review Discrepancies & Approve'), findsOneWidget);
      expect(find.text('✨ Ask AI Copilot'), findsOneWidget);

      // Tap Review Discrepancies & Approve
      await tester.tap(find.text('Review Discrepancies & Approve'));
      await tester.pumpAndSettle();

      // Should be on Reconciliation screen with Manager badge
      expect(find.text('Reconciliation Review'), findsOneWidget);
      expect(find.text('👔 Manager Approval Mode'), findsOneWidget);
      expect(find.text('Approve & Commit to ERP'), findsOneWidget);
    });
  });
}

