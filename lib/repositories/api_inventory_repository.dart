
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/discrepancy.dart';
import '../models/enums.dart';
import '../models/product.dart';
import '../models/stock_count.dart';
import '../models/stock_take.dart';
import 'inventory_repository.dart';

class ApiInventoryRepository implements InventoryRepository {
  final Dio _dio;
  StockTake? _activeStockTake;

  ApiInventoryRepository({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl ?? _defaultBaseUrl,
              connectTimeout: const Duration(seconds: 4), // Fast fail for fallback
              receiveTimeout: const Duration(seconds: 15),
            )) {
    if (dio == null && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onError: (DioException e, ErrorInterceptorHandler handler) async {
            if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
              final currentHost = _dio.options.baseUrl;
              final altHost = currentHost.contains('127.0.0.1')
                  ? 'http://10.0.2.2:8000'
                  : 'http://127.0.0.1:8000';
              
              _dio.options.baseUrl = altHost;
              debugPrint('[ApiInventoryRepository] Retrying connection to $altHost');

              try {
                final opts = Options(method: e.requestOptions.method, headers: e.requestOptions.headers);
                final retryResponse = await _dio.request(
                  e.requestOptions.path,
                  options: opts,
                  data: e.requestOptions.data,
                  queryParameters: e.requestOptions.queryParameters,
                );
                return handler.resolve(retryResponse);
              } catch (_) {
                // If retry also fails, revert base URL and pass original error
                _dio.options.baseUrl = currentHost;
              }
            }
            return handler.next(e);
          },
        ),
      );
    }
  }

  static String get _defaultBaseUrl {
    // 127.0.0.1 works natively for iOS Simulator, Web, and Android Physical Devices (with adb reverse).
    // The interceptor above handles the fallback to 10.0.2.2 for Android Emulators.
    return 'http://127.0.0.1:8000';
  }

  // Convert snake_case from API to camelCase for the Product model
  Product _mapProduct(Map<String, dynamic> json) {
    return Product(
      sku: json['sku'] as String,
      name: json['name'] as String,
      barcode: json['barcode'] as String?,
      hasBarcode: json['has_barcode'] as bool? ?? false,
      systemQty: (json['system_qty'] as num).toInt(),
      visualDescription: json['visual_description'] as String? ?? '',
    );
  }

  @override
  Future<List<Product>> getProducts() async {
    final response = await _dio.get('/products');
    final List<dynamic> data = response.data;
    return data.map((json) => _mapProduct(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<Product?> getProductBySku(String sku) async {
    try {
      final response = await _dio.get('/products/$sku');
      return _mapProduct(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    // Matches locally from getProducts() as the backend doesn't have a /products/barcode endpoint
    final products = await getProducts();
    try {
      return products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StockTake> startStockTake() async {
    final response = await _dio.post('/stock-takes');
    final data = response.data as Map<String, dynamic>;
    
    // Parse status string to enum
    final statusStr = data['status'] as String? ?? 'in_progress';
    StockTakeStatus status = StockTakeStatus.inProgress;
    if (statusStr == 'approved') {
      status = StockTakeStatus.approved;
    } else if (statusStr == 'pending_approval' || statusStr == 'pendingApproval') {
      status = StockTakeStatus.pendingApproval;
    }

    final stockTake = StockTake(
      id: data['id'] as String,
      status: status,
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : DateTime.now(),
      counts: const [],
    );

    _activeStockTake = stockTake;
    return stockTake;
  }

  @override
  Future<StockTake?> getActiveStockTake() async {
    return _activeStockTake;
  }

  @override
  Future<void> recordCount(StockCount count) async {
    if (_activeStockTake == null) {
      throw StateError('Cannot record count without an active stock take');
    }

    final payload = {
      "sku": count.sku,
      "physical_qty": count.physicalQty,
      "method": count.method.name,
      "confidence": count.confidence,
    };

    final response = await _dio.post(
      '/stock-takes/${_activeStockTake!.id}/counts',
      data: payload,
    );

    // Update the active stock take's counts in memory
    final data = response.data as Map<String, dynamic>;
    final newCount = StockCount(
      id: data['id'] as String? ?? count.id,
      stockTakeId: data['stock_take_id'] as String? ?? count.stockTakeId,
      sku: data['sku'] as String? ?? count.sku,
      physicalQty: (data['physical_qty'] as num?)?.toInt() ?? count.physicalQty,
      method: count.method, // Use original method as backend string may differ
      confidence: (data['confidence'] as num?)?.toDouble() ?? count.confidence,
      timestamp: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : DateTime.now(),
    );

    final updatedCounts = List<StockCount>.from(_activeStockTake!.counts);
    final existingIndex = updatedCounts.indexWhere((c) => c.sku == count.sku);

    if (existingIndex >= 0) {
      updatedCounts[existingIndex] = newCount;
    } else {
      updatedCounts.add(newCount);
    }

    _activeStockTake = _activeStockTake!.copyWith(counts: updatedCounts);
  }

  @override
  Future<List<Discrepancy>> getReconciliation(String stockTakeId) async {
    final response = await _dio.get('/stock-takes/$stockTakeId/reconciliation');
    final data = response.data as Map<String, dynamic>;
    final discrepanciesList = data['discrepancies'] as List<dynamic>? ?? [];
    
    return discrepanciesList.map((json) {
      final discMap = json as Map<String, dynamic>;
      
      final typeStr = discMap['type'] as String? ?? 'match';
      DiscrepancyType type = DiscrepancyType.match;
      if (typeStr == 'shortage') {
        type = DiscrepancyType.shortage;
      } else if (typeStr == 'surplus') {
        type = DiscrepancyType.surplus;
      }

      return Discrepancy(
        sku: discMap['sku'] as String,
        productName: discMap['product_name'] as String,
        systemQty: (discMap['system_qty'] as num).toInt(),
        physicalQty: (discMap['physical_qty'] as num).toInt(),
        variance: (discMap['variance'] as num).toInt(),
        type: type,
      );
    }).toList();
  }

  @override
  Future<void> approveStockTake(String stockTakeId) async {
    await _dio.post('/stock-takes/$stockTakeId/approve');
    if (_activeStockTake?.id == stockTakeId) {
      _activeStockTake = _activeStockTake!.copyWith(status: StockTakeStatus.approved);
    }
  }

  @override
  Future<void> submitForApproval(String stockTakeId) async {
    if (_activeStockTake?.id == stockTakeId) {
      _activeStockTake = _activeStockTake!.copyWith(status: StockTakeStatus.pendingApproval);
    }
  }
}
