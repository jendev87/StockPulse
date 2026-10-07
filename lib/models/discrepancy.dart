import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';
import 'product.dart';

part 'discrepancy.freezed.dart';
part 'discrepancy.g.dart';

@freezed
abstract class Discrepancy with _$Discrepancy {
  const factory Discrepancy({
    required String sku,
    required String productName,
    required int systemQty,
    required int physicalQty,
    required int variance,
    required DiscrepancyType type,
  }) = _Discrepancy;

  factory Discrepancy.fromJson(Map<String, dynamic> json) => _$DiscrepancyFromJson(json);

  factory Discrepancy.calculate({
    required Product product,
    required int physicalQty,
  }) {
    final variance = physicalQty - product.systemQty;
    DiscrepancyType type;
    if (variance > 0) {
      type = DiscrepancyType.surplus;
    } else if (variance < 0) {
      type = DiscrepancyType.shortage;
    } else {
      type = DiscrepancyType.match;
    }

    return Discrepancy(
      sku: product.sku,
      productName: product.name,
      systemQty: product.systemQty,
      physicalQty: physicalQty,
      variance: variance,
      type: type,
    );
  }
}
