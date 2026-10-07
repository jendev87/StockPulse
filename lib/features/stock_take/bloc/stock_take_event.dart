import 'package:flutter/foundation.dart';
import '../../../models/enums.dart';

@immutable
abstract class StockTakeEvent {
  const StockTakeEvent();
}

class LoadActiveStockTake extends StockTakeEvent {
  const LoadActiveStockTake();
}

class StartNewStockTake extends StockTakeEvent {
  const StartNewStockTake();
}

class UpdateCount extends StockTakeEvent {
  final String sku;
  final int physicalQty;
  final IdentificationMethod method;

  const UpdateCount({
    required this.sku,
    required this.physicalQty,
    this.method = IdentificationMethod.manual,
  });
}

class LoadReconciliation extends StockTakeEvent {
  final String stockTakeId;

  const LoadReconciliation(this.stockTakeId);
}

class ApproveStockTake extends StockTakeEvent {
  final String stockTakeId;

  const ApproveStockTake(this.stockTakeId);
}

class SwitchRole extends StockTakeEvent {
  final AppRole role;

  const SwitchRole(this.role);
}

class SubmitStockTakeForApproval extends StockTakeEvent {
  final String stockTakeId;

  const SubmitStockTakeForApproval(this.stockTakeId);
}

