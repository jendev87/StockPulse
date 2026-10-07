import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockpulse/core/theme/app_theme.dart';
import 'package:stockpulse/features/scanner/screens/ai_vision_screen.dart';
import 'package:stockpulse/features/stock_take/bloc/stock_take_bloc.dart';
import 'package:stockpulse/features/stock_take/screens/stock_take_screen.dart';
import 'package:stockpulse/features/stock_take/widgets/voice_count_bottom_sheet.dart';
import 'package:stockpulse/models/product.dart';
import 'package:stockpulse/repositories/inventory_repository.dart';
import 'package:stockpulse/repositories/mock_inventory_repository.dart';
import 'package:stockpulse/services/ai_api_service.dart';

import 'package:image_picker/image_picker.dart';
import 'package:stockpulse/models/enums.dart';

void main() {
  group('AiApiService Unit Tests', () {
    test('Default base URLs adhere to platform configurations', () {
      final service = AiApiService();
      expect(service.baseUrl, isNotEmpty);
      expect(service.baseUrl.contains('8000'), isTrue);
    });

    test('parseVoice fallback parses transcript and extracts quantities correctly',
        () async {
      final service = AiApiService(baseUrl: 'http://invalid-unreachable-host:9999');
      final catalog = [
        const Product(
          sku: 'P005',
          name: 'Tomato Sauce 500g',
          hasBarcode: true,
          barcode: '9300601234560',
          systemQty: 25,
          visualDescription: 'Glass jar of red tomato pasta sauce',
        ),
        const Product(
          sku: 'P001',
          name: 'Coca Cola 500ml',
          hasBarcode: true,
          barcode: '9300601234567',
          systemQty: 50,
          visualDescription: 'Red label plastic bottle',
        ),
      ];

      final result = await service.parseVoice(
        transcript: 'twelve bottles of tomato sauce',
        catalog: catalog,
      );

      expect(result.sku, 'P005');
      expect(result.productName, 'Tomato Sauce 500g');
      expect(result.quantity, 12);
      expect(result.confidence, greaterThan(0.5));
    });

    test('parseVoice fallback parses number-only transcripts returning null SKU',
        () async {
      final service = AiApiService(baseUrl: 'http://invalid-unreachable-host:9999');
      final catalog = [
        const Product(
          sku: 'P001',
          name: 'Coca Cola 500ml',
          hasBarcode: true,
          barcode: '9300601234567',
          systemQty: 50,
          visualDescription: 'Red label plastic bottle',
        ),
      ];

      final result = await service.parseVoice(
        transcript: 'forty',
        catalog: catalog,
      );

      expect(result.sku, isNull);
      expect(result.productName, isNull);
      expect(result.quantity, 40);
    });
  });

  group('AI Vision & Voice UI Widget Tests', () {
    late InventoryRepository repository;

    setUp(() {
      repository = MockInventoryRepository();
    });

    Widget createTestApp(Widget child) {
      return RepositoryProvider<InventoryRepository>.value(
        value: repository,
        child: BlocProvider<StockTakeBloc>(
          lazy: false,
          create: (context) => StockTakeBloc(repository: repository)
            ..add(const StartNewStockTake()),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: child,
          ),
        ),
      );
    }

    testWidgets('StockTakeScreen renders AI Visual Scan FAB and mic button in AppBar',
        (tester) async {
      await tester.pumpWidget(createTestApp(const StockTakeScreen()));
      await tester.pumpAndSettle();

      // Check for AI Visual Scan FAB
      expect(find.text('AI Visual Scan'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

      // Check for mic button in AppBar
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('AiVisionScreen renders capture prompt and camera/gallery buttons',
        (tester) async {
      await tester.pumpWidget(createTestApp(const AiVisionScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AI Vision Auditor'), findsOneWidget);
      expect(find.text('AI Visual Item Detection'), findsOneWidget);
      expect(find.text('Capture with Camera'), findsOneWidget);
      expect(find.text('Upload from Photo Library'), findsOneWidget);
    });

    testWidgets('VoiceCountBottomSheet displays waveform, chips, and resolves count',
        (tester) async {
      final fakeAiService = FakeAiApiService();

      await tester.pumpWidget(createTestApp(
        Builder(
          builder: (context) => Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () => VoiceCountBottomSheet.show(
                context,
                aiApiService: fakeAiService,
              ),
              child: const Icon(Icons.mic),
            ),
          ),
        ),
      ));
      // Allow StartNewStockTake to complete loading products
      await tester.pump(const Duration(milliseconds: 200));

      // Open bottom sheet
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AI Voice Count Entry'), findsOneWidget);
      expect(find.text('12 bottles of Tomato Sauce'), findsOneWidget);

      // Tap sample voice chip
      await tester.tap(find.text('12 bottles of Tomato Sauce'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Resolved card should display identified SKU & quantity
      expect(find.textContaining('Tomato Sauce'), findsWidgets);
      expect(find.text('Confirm & Save Count'), findsOneWidget);

      // Tap Confirm & Save Count
      await tester.tap(find.text('Confirm & Save Count'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Modal dismissed
      expect(find.text('Confirm & Save Count'), findsNothing);
    });

    testWidgets('AiVisionScreen accumulates new vision count when previous count exists (15 + 12 = 27)',
        (tester) async {
      final fakeAiService = FakeAiApiService();
      final fakePicker = FakeImagePicker();

      late StockTakeBloc stockTakeBloc;

      await tester.pumpWidget(
        RepositoryProvider<InventoryRepository>.value(
          value: repository,
          child: BlocProvider<StockTakeBloc>(
            lazy: false,
            create: (context) {
              stockTakeBloc = StockTakeBloc(repository: repository)
                ..add(const StartNewStockTake());
              return stockTakeBloc;
            },
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: AiVisionScreen(
                aiApiService: fakeAiService,
                imagePicker: fakePicker,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Pre-record 15 apples for P010
      stockTakeBloc.add(const UpdateCount(
        sku: 'P010',
        physicalQty: 15,
        method: IdentificationMethod.manual,
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Capture with Camera
      await tester.tap(find.text('Capture with Camera'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify detected Loose Red Apples and accumulation UI
      expect(find.text('Loose Red Apples'), findsOneWidget);
      expect(find.text('Previous Count: 15 units'), findsOneWidget);
      expect(find.text('+12 in photo'), findsOneWidget);
      expect(find.text('➕ Add (27 Total)'), findsOneWidget);

      // Verify dynamic action button
      expect(find.text('Add (+12 → 27 Total)'), findsOneWidget);

      // Scroll into view & tap Add button
      await tester.ensureVisible(find.text('Add (+12 → 27 Total)'));
      await tester.pump();
      await tester.tap(find.text('Add (+12 → 27 Total)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify that bloc recorded 27 units
      expect(stockTakeBloc.state.counts['P010']?.physicalQty, 27);

      // Verify SnackBar message is shown without overflow
      expect(find.text('Added 12 units to Loose Red Apples (Total: 27)'), findsOneWidget);
    });
  });
}

class FakeAiApiService extends AiApiService {
  @override
  Future<AiVoiceResult> parseVoice({
    required String transcript,
    required List<Product> catalog,
  }) async {
    return localVoiceFallback(transcript, catalog);
  }

  @override
  Future<AiVisionResult> identifyProduct({
    required XFile imageFile,
    required List<Product> catalog,
  }) async {
    return const AiVisionResult(
      sku: 'P010',
      name: 'Loose Red Apples',
      confidence: 0.95,
      detectedQuantity: 12,
    );
  }
}

class FakeImagePicker extends ImagePicker {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return XFile('test/fake_apples.jpg');
  }
}
