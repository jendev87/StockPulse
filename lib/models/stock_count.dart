import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'stock_count.freezed.dart';
part 'stock_count.g.dart';

@freezed
abstract class StockCount with _$StockCount {
  const factory StockCount({
    required String id,
    required String stockTakeId,
    required String sku,
    required int physicalQty,
    required IdentificationMethod method,
    @Default(1.0) double confidence,
    required DateTime timestamp,
  }) = _StockCount;

  factory StockCount.fromJson(Map<String, dynamic> json) => _$StockCountFromJson(json);
}
