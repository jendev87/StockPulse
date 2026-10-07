import '../../../models/discrepancy.dart';
import '../../../models/enums.dart';
import '../../../models/product.dart';
import '../../../models/stock_count.dart';
import '../../../models/stock_take.dart';

enum StockTakeStatusState {
  initial,
  loading,
  active,
  reconciling,
  completed,
  error,
}

class StockTakeState {
  final StockTakeStatusState status;
  final StockTake? activeStockTake;
  final List<Product> products;
  final Map<String, StockCount> counts;
  final List<Discrepancy> discrepancies;
  final String? errorMessage;
  final String? successMessage;
  final String? lastApprovedSessionId;
  final String? erpTransactionId;
  final AppRole currentRole;

  const StockTakeState({
    this.status = StockTakeStatusState.initial,
    this.activeStockTake,
    this.products = const [],
    this.counts = const {},
    this.discrepancies = const [],
    this.errorMessage,
    this.successMessage,
    this.lastApprovedSessionId,
    this.erpTransactionId,
    this.currentRole = AppRole.associate,
  });

  int get countedItemsCount => counts.length;
  int get totalItemsCount => products.length;
  double get progress =>
      products.isEmpty ? 0.0 : (counts.length / products.length).clamp(0.0, 1.0);

  StockTakeState copyWith({
    StockTakeStatusState? status,
    StockTake? activeStockTake,
    bool clearActiveStockTake = false,
    List<Product>? products,
    Map<String, StockCount>? counts,
    List<Discrepancy>? discrepancies,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    String? lastApprovedSessionId,
    bool clearLastApprovedSessionId = false,
    String? erpTransactionId,
    bool clearErpTransactionId = false,
    AppRole? currentRole,
  }) {
    return StockTakeState(
      status: status ?? this.status,
      activeStockTake:
          clearActiveStockTake ? null : (activeStockTake ?? this.activeStockTake),
      products: products ?? this.products,
      counts: counts ?? this.counts,
      discrepancies: discrepancies ?? this.discrepancies,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      lastApprovedSessionId: clearLastApprovedSessionId
          ? null
          : (lastApprovedSessionId ?? this.lastApprovedSessionId),
      erpTransactionId: clearErpTransactionId
          ? null
          : (erpTransactionId ?? this.erpTransactionId),
      currentRole: currentRole ?? this.currentRole,
    );
  }
}

