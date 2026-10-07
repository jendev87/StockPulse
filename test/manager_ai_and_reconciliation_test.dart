import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stockpulse/core/theme/app_theme.dart';
import 'package:stockpulse/features/ai_assistant/widgets/manager_ai_sheet.dart';
import 'package:stockpulse/features/reconciliation/screens/reconciliation_screen.dart';
import 'package:stockpulse/features/stock_take/bloc/stock_take_bloc.dart';
import 'package:stockpulse/models/enums.dart';
import 'package:stockpulse/models/stock_count.dart';
import 'package:stockpulse/repositories/inventory_repository.dart';
import 'package:stockpulse/repositories/mock_inventory_repository.dart';
import 'package:stockpulse/services/ai_api_service.dart';

class FakeManagerAiService extends AiApiService {
  String lastQuestion = '';
  String lastStockTakeId = '';

  @override
  Future<String> askManagerAssistant({
    required String question,
    required String stockTakeId,
  }) async {
    lastQuestion = question;
    lastStockTakeId = stockTakeId;
    if (question.contains('short')) {
      return 'Found 7 short items for session #$stockTakeId: KitKat 4-Finger, Tomato Sauce Bottle, etc.';
    } else if (question.contains('surplus')) {
      return 'Found 0 surplus items for session #$stockTakeId.';
    } else {
      return 'Inventory accuracy for #$stockTakeId: 3 matched, 7 shortages.';
    }
  }
}

void main() {
  group('AiApiService askManagerAssistant Tests', () {
    test('askManagerAssistant fallback returns deterministic summary when offline',
        () async {
      final service =
          AiApiService(baseUrl: 'http://invalid-unreachable-host:9999');
      final result = await service.askManagerAssistant(
        question: 'Which items are short?',
        stockTakeId: 'ST-001',
      );

      expect(result, isNotEmpty);
      expect(result.contains('StockPulse Copilot'), isTrue);
      expect(result.contains('ST-001'), isTrue);
    });
  });

  group('ManagerAiSheet Widget Tests', () {
    testWidgets(
        'ManagerAiSheet displays header, session indicator, quick chips, and responds to prompt',
        (WidgetTester tester) async {
      final fakeAi = FakeManagerAiService();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ManagerAiSheet.show(
                  context,
                  stockTakeId: 'ST-001',
                  aiService: fakeAi,
                ),
                child: const Text('Open Copilot'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Copilot'));
      await tester.pumpAndSettle();

      // Verify Header & Session
      expect(find.text('✨ StockPulse Copilot'), findsOneWidget);
      expect(find.text('Auditing Session #ST-001'), findsOneWidget);

      // Verify 3 Quick Prompt recommendation chips
      expect(find.text('Which items are short?'), findsOneWidget);
      expect(find.text('Show me all surpluses'), findsOneWidget);
      expect(find.text('Summarize inventory accuracy'), findsOneWidget);

      // Tap "Which items are short?" chip
      await tester.tap(find.text('Which items are short?'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      // Should render user question and assistant answer
      expect(fakeAi.lastQuestion, 'Which items are short?');
      expect(fakeAi.lastStockTakeId, 'ST-001');
      expect(find.textContaining('Found 7 short items'), findsOneWidget);

      // Input field test
      final inputField =
          find.byWidgetPredicate((w) => w is TextField);
      expect(inputField, findsOneWidget);
      await tester.enterText(inputField, 'Summarize inventory accuracy');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Inventory accuracy for #ST-001'), findsOneWidget);
    });
  });

  group('Reconciliation Screen Polish Tests', () {
    late InventoryRepository repository;

    setUp(() async {
      repository = MockInventoryRepository();
      await repository.startStockTake();
      // Record a count with AI Vision and one with Voice
      await repository.recordCount(
        StockCount(
          id: 'count_1',
          stockTakeId: 'ST-001',
          sku: 'P001',
          physicalQty: 27, // Surplus (+2)
          method: IdentificationMethod.ai,
          confidence: 0.95,
          timestamp: DateTime.now(),
        ),
      );
      await repository.recordCount(
        StockCount(
          id: 'count_2',
          stockTakeId: 'ST-001',
          sku: 'P002',
          physicalQty: 16, // Shortage (-4)
          method: IdentificationMethod.voice,
          confidence: 0.90,
          timestamp: DateTime.now(),
        ),
      );
    });

    Widget createTestApp() {
      final testRouter = GoRouter(
        initialLocation: '/reconciliation',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('Mock Dashboard Root'),
            ),
          ),
          GoRoute(
            path: '/reconciliation',
            builder: (context, state) => const ReconciliationScreen(),
          ),
        ],
      );

      return RepositoryProvider<InventoryRepository>.value(
        value: repository,
        child: BlocProvider<StockTakeBloc>(
          lazy: false,
          create: (context) => StockTakeBloc(repository: repository)
            ..add(const LoadActiveStockTake())
            ..add(const LoadReconciliation('ST-001')),
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: testRouter,
          ),
        ),
      );
    }

    testWidgets('ReconciliationScreen displays summary banner, cards with badges and delta tags',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Top Summary Banner
      expect(find.text('Total Items'), findsOneWidget);
      expect(find.text('Matched'), findsOneWidget);
      expect(find.text('Shortages'), findsOneWidget);
      expect(find.text('Surpluses'), findsOneWidget);

      // Method Badges
      expect(find.text('AI Vision'), findsOneWidget);
      expect(find.text('Voice'), findsOneWidget);

      // Delta Tags (+2 SURPLUS and -4 SHORTAGE)
      expect(find.text('+2 SURPLUS'), findsOneWidget);
      expect(find.text('-4 SHORTAGE'), findsOneWidget);

      // Prominent Floating Button "Ask AI Assistant"
      expect(find.text('Ask AI Assistant'), findsOneWidget);

      // Commit & Sync Footer Button
      final approveBtn = find.text('Approve & Commit to ERP');
      expect(approveBtn, findsOneWidget);

      // Tap Commit Button
      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      // Confirmation Dialog
      expect(find.text('Commit to ERP'), findsOneWidget);
      expect(
        find.text(
            'This will commit stock adjustments to SQLite system inventory.'),
        findsOneWidget,
      );

      // Confirm commit
      await tester.tap(find.text('Confirm & Commit'));
      await tester.pumpAndSettle();

      // Navigates to dashboard root
      expect(find.text('Mock Dashboard Root'), findsOneWidget);
      expect(find.textContaining('Stock Take Approved & Committed'), findsOneWidget);
    });
  });
}
