// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discrepancy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Discrepancy _$DiscrepancyFromJson(Map<String, dynamic> json) => _Discrepancy(
  sku: json['sku'] as String,
  productName: json['productName'] as String,
  systemQty: (json['systemQty'] as num).toInt(),
  physicalQty: (json['physicalQty'] as num).toInt(),
  variance: (json['variance'] as num).toInt(),
  type: $enumDecode(_$DiscrepancyTypeEnumMap, json['type']),
);

Map<String, dynamic> _$DiscrepancyToJson(_Discrepancy instance) =>
    <String, dynamic>{
      'sku': instance.sku,
      'productName': instance.productName,
      'systemQty': instance.systemQty,
      'physicalQty': instance.physicalQty,
      'variance': instance.variance,
      'type': _$DiscrepancyTypeEnumMap[instance.type]!,
    };

const _$DiscrepancyTypeEnumMap = {
  DiscrepancyType.match: 'match',
  DiscrepancyType.shortage: 'shortage',
  DiscrepancyType.surplus: 'surplus',
};
