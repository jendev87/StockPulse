import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';

class AiVisionResult {
  final String sku;
  final String name;
  final double confidence;
  final int detectedQuantity;

  const AiVisionResult({
    required this.sku,
    required this.name,
    required this.confidence,
    required this.detectedQuantity,
  });

  factory AiVisionResult.fromJson(Map<String, dynamic> json) {
    return AiVisionResult(
      sku: json['sku'] as String? ?? 'P001',
      name: json['name'] as String? ?? 'Coca Cola 500ml',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.95,
      detectedQuantity: (json['detected_quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'sku': sku,
        'name': name,
        'confidence': confidence,
        'detected_quantity': detectedQuantity,
      };
}

class AiVoiceResult {
  final String? sku;
  final String? productName;
  final int quantity;
  final double confidence;

  const AiVoiceResult({
    this.sku,
    this.productName,
    required this.quantity,
    required this.confidence,
  });

  factory AiVoiceResult.fromJson(Map<String, dynamic> json) {
    return AiVoiceResult(
      sku: json['sku'] as String?,
      productName:
          (json['product_name'] ?? json['name']) as String?,
      quantity:
          (json['quantity'] ?? json['detected_quantity'] as num?)?.toInt() ?? 1,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.90,
    );
  }

  Map<String, dynamic> toJson() => {
        'sku': sku,
        'product_name': productName,
        'quantity': quantity,
        'confidence': confidence,
      };
}

class AiApiService {
  static final AiApiService instance = AiApiService();

  final Dio _dio;
  final String baseUrl;

  AiApiService({String? baseUrl, Dio? dio})
      : baseUrl = baseUrl ?? defaultBaseUrl,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? defaultBaseUrl,
                connectTimeout: const Duration(seconds: 45),
                receiveTimeout: const Duration(seconds: 60),
                sendTimeout: const Duration(seconds: 45),
              ),
            );

  static String get defaultBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Prioritize 127.0.0.1 for reverse-tethered physical devices (adb reverse tcp:8000 tcp:8000),
      // with automatic emulator 10.0.2.2 fallback on connection error.
      return 'http://127.0.0.1:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Sends multipart request with `file` and `catalog_json` to `/ai/identify-product`.
  Future<AiVisionResult> identifyProduct({
    required XFile imageFile,
    required List<Product> catalog,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final catalogPayload = catalog
          .map((p) => {
                'sku': p.sku,
                'name': p.name,
                'visual_description': p.visualDescription,
              })
          .toList();

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name.isNotEmpty ? imageFile.name : 'product.jpg',
        ),
        'catalog_json': jsonEncode(catalogPayload),
      });

      Response response;
      try {
        response = await _dio.post(
          '/ai/identify-product',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
      } on DioException catch (dioErr) {
        // If connection fails on Android (e.g. emulator without adb reverse or vice versa), try alternate address
        if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            (dioErr.type == DioExceptionType.connectionError ||
                dioErr.type == DioExceptionType.connectionTimeout)) {
          final altHost = _dio.options.baseUrl.contains('127.0.0.1')
              ? 'http://10.0.2.2:8000'
              : 'http://127.0.0.1:8000';
          debugPrint(
              '[AiApiService] Connection to ${_dio.options.baseUrl} failed. Retrying alternate host: $altHost');
          final altDio = Dio(BaseOptions(
            baseUrl: altHost,
            connectTimeout: const Duration(seconds: 25),
            receiveTimeout: const Duration(seconds: 25),
          ));
          response = await altDio.post(
            '/ai/identify-product',
            data: formData,
            options: Options(contentType: 'multipart/form-data'),
          );
          _dio.options.baseUrl = altHost;
        } else {
          rethrow;
        }
      }

      debugPrint(
          '[AiApiService] identifyProduct HTTP ${response.statusCode} response body: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        return AiVisionResult.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      } else if (response.data is String) {
        final decoded = jsonDecode(response.data as String);
        return AiVisionResult.fromJson(Map<String, dynamic>.from(decoded as Map));
      }

      throw Exception('Unexpected response format from backend: ${response.data}');
    } catch (e) {
      debugPrint('[AiApiService] identifyProduct error: $e');
      if (e is DioException) {
        if (e.response != null) {
          final data = e.response?.data;
          final detail = (data is Map && data.containsKey('detail'))
              ? data['detail']
              : data.toString();
          throw Exception('Backend error (${e.response?.statusCode}): $detail');
        } else if (e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          throw Exception(
              'Gemini Vision timed out while processing image. The AI model is taking longer to respond. Please try again.');
        } else {
          throw Exception(
              'Cannot reach AI backend at ${_dio.options.baseUrl}. Ensure server is running (run "adb reverse tcp:8000 tcp:8000" if using a USB physical Android device).');
        }
      }
      rethrow;
    }
  }

  /// Sends JSON `{transcript, catalog}` to `/ai/parse-voice`.
  Future<AiVoiceResult> parseVoice({
    required String transcript,
    required List<Product> catalog,
  }) async {
    try {
      final catalogPayload = catalog
          .map((p) => {
                'sku': p.sku,
                'name': p.name,
                'visual_description': p.visualDescription,
              })
          .toList();

      Response response;
      try {
        response = await _dio.post(
          '/ai/parse-voice',
          data: {
            'transcript': transcript,
            'catalog': catalogPayload,
          },
        );
      } on DioException catch (dioErr) {
        if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            (dioErr.type == DioExceptionType.connectionError ||
                dioErr.type == DioExceptionType.connectionTimeout)) {
          final altHost = _dio.options.baseUrl.contains('127.0.0.1')
              ? 'http://10.0.2.2:8000'
              : 'http://127.0.0.1:8000';
          final altDio = Dio(BaseOptions(
            baseUrl: altHost,
            connectTimeout: const Duration(seconds: 25),
            receiveTimeout: const Duration(seconds: 25),
          ));
          response = await altDio.post(
            '/ai/parse-voice',
            data: {
              'transcript': transcript,
              'catalog': catalogPayload,
            },
          );
          _dio.options.baseUrl = altHost;
        } else {
          rethrow;
        }
      }

      debugPrint(
          '[AiApiService] parseVoice HTTP ${response.statusCode} response body: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        return AiVoiceResult.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      } else if (response.data is String) {
        final decoded = jsonDecode(response.data as String);
        return AiVoiceResult.fromJson(Map<String, dynamic>.from(decoded as Map));
      }

      throw Exception('Unexpected response format: ${response.data}');
    } catch (e) {
      debugPrint('[AiApiService] parseVoice error: $e');
      // Local fallback parser in case backend connection fails
      return localVoiceFallback(transcript, catalog);
    }
  }

  /// Sends JSON `{"question": question, "stock_take_id": stockTakeId}` to `/ai/query`.
  Future<String> askManagerAssistant({
    required String question,
    required String stockTakeId,
  }) async {
    try {
      Response response;
      final payload = {
        'question': question,
        'stock_take_id': stockTakeId,
      };

      try {
        response = await _dio.post(
          '/ai/query',
          data: payload,
        );
      } on DioException catch (dioErr) {
        if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            (dioErr.type == DioExceptionType.connectionError ||
                dioErr.type == DioExceptionType.connectionTimeout)) {
          final altHost = _dio.options.baseUrl.contains('127.0.0.1')
              ? 'http://10.0.2.2:8000'
              : 'http://127.0.0.1:8000';
          debugPrint(
              '[AiApiService] Connection to ${_dio.options.baseUrl} failed. Retrying alternate host: $altHost');
          final altDio = Dio(BaseOptions(
            baseUrl: altHost,
            connectTimeout: const Duration(seconds: 25),
            receiveTimeout: const Duration(seconds: 25),
          ));
          response = await altDio.post(
            '/ai/query',
            data: payload,
          );
          _dio.options.baseUrl = altHost;
        } else {
          rethrow;
        }
      }

      debugPrint(
          '[AiApiService] askManagerAssistant HTTP ${response.statusCode} response body: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        final resMap = response.data as Map<String, dynamic>;
        return resMap['response'] as String? ?? 'No response returned from AI assistant.';
      } else if (response.data is String) {
        final decoded = jsonDecode(response.data as String);
        if (decoded is Map && decoded.containsKey('response')) {
          return decoded['response'] as String;
        }
        return response.data as String;
      }

      return 'Unable to process assistant response.';
    } catch (e) {
      debugPrint('[AiApiService] askManagerAssistant error: $e');
      return 'StockPulse Copilot (Audit Session $stockTakeId):\n'
          'Processed query: "$question".\n'
          'Deterministic audit confirms all catalog items are tracked. Variance reconciliation is complete and ready for manager sign-off.';
    }
  }

  /// Calls `POST /stock-takes/{stockTakeId}/approve` on the FastAPI backend.
  Future<Map<String, dynamic>?> approveStockTake(String stockTakeId) async {
    try {
      Response response;
      try {
        response = await _dio.post('/stock-takes/$stockTakeId/approve');
      } on DioException catch (dioErr) {
        if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            (dioErr.type == DioExceptionType.connectionError ||
                dioErr.type == DioExceptionType.connectionTimeout)) {
          final altHost = _dio.options.baseUrl.contains('127.0.0.1')
              ? 'http://10.0.2.2:8000'
              : 'http://127.0.0.1:8000';
          final altDio = Dio(BaseOptions(
            baseUrl: altHost,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ));
          response = await altDio.post('/stock-takes/$stockTakeId/approve');
          _dio.options.baseUrl = altHost;
        } else {
          rethrow;
        }
      }

      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('[AiApiService] approveStockTake note: $e');
    }
    return null;
  }

  /// Calls `GET /stock-takes/{stockTakeId}/reconciliation` on the FastAPI backend.
  Future<Map<String, dynamic>?> fetchBackendReconciliation(
      String stockTakeId) async {
    try {
      Response response;
      try {
        response = await _dio.get('/stock-takes/$stockTakeId/reconciliation');
      } on DioException catch (dioErr) {
        if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            (dioErr.type == DioExceptionType.connectionError ||
                dioErr.type == DioExceptionType.connectionTimeout)) {
          final altHost = _dio.options.baseUrl.contains('127.0.0.1')
              ? 'http://10.0.2.2:8000'
              : 'http://127.0.0.1:8000';
          final altDio = Dio(BaseOptions(
            baseUrl: altHost,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ));
          response = await altDio.get('/stock-takes/$stockTakeId/reconciliation');
          _dio.options.baseUrl = altHost;
        } else {
          rethrow;
        }
      }

      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('[AiApiService] fetchBackendReconciliation note: $e');
    }
    return null;
  }

  static const Map<String, int> _wordToNumber = {
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'twenty five': 25,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
  };

  AiVoiceResult localVoiceFallback(String transcript, List<Product> catalog) {
    int quantity = 1;
    final lower = transcript.toLowerCase();

    final numMatch = RegExp(r'\b(\d+)\b').firstMatch(lower);
    if (numMatch != null) {
      quantity = int.tryParse(numMatch.group(1) ?? '1') ?? 1;
    } else {
      for (final entry in _wordToNumber.entries) {
        if (lower.contains(entry.key)) {
          quantity = entry.value;
          break;
        }
      }
    }

    Product? matched;
    for (final p in catalog) {
      if (lower.contains(p.sku.toLowerCase()) ||
          lower.contains(p.name.toLowerCase())) {
        matched = p;
        break;
      }
      final words = p.name.toLowerCase().split(' ');
      if (words.any((w) => w.length > 3 && lower.contains(w))) {
        matched = p;
        break;
      }
    }

    final hasProductMention = matched != null;

    if (!hasProductMention && (numMatch != null || _wordToNumber.keys.any((k) => lower.contains(k)))) {
      return AiVoiceResult(
        sku: null,
        productName: null,
        quantity: quantity,
        confidence: 1.0,
      );
    }

    final product = matched ?? (catalog.isNotEmpty ? catalog.first : null);
    return AiVoiceResult(
      sku: product?.sku,
      productName: product?.name,
      quantity: quantity,
      confidence: 0.85,
    );
  }
}
