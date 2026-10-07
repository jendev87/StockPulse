import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';
import 'stock_count.dart';

part 'stock_take.freezed.dart';
part 'stock_take.g.dart';

@freezed
abstract class StockTake with _$StockTake {
  @JsonSerializable(explicitToJson: true)
  const factory StockTake({
    required String id,
    required StockTakeStatus status,
    required DateTime createdAt,
    required List<StockCount> counts,
  }) = _StockTake;

  factory StockTake.fromJson(Map<String, dynamic> json) => _$StockTakeFromJson(json);
}
