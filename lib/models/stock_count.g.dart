// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_count.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StockCount _$StockCountFromJson(Map<String, dynamic> json) => _StockCount(
  id: json['id'] as String,
  stockTakeId: json['stockTakeId'] as String,
  sku: json['sku'] as String,
  physicalQty: (json['physicalQty'] as num).toInt(),
  method: $enumDecode(_$IdentificationMethodEnumMap, json['method']),
  confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$StockCountToJson(_StockCount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'stockTakeId': instance.stockTakeId,
      'sku': instance.sku,
      'physicalQty': instance.physicalQty,
      'method': _$IdentificationMethodEnumMap[instance.method]!,
      'confidence': instance.confidence,
      'timestamp': instance.timestamp.toIso8601String(),
    };

const _$IdentificationMethodEnumMap = {
  IdentificationMethod.barcode: 'barcode',
  IdentificationMethod.ai: 'ai',
  IdentificationMethod.voice: 'voice',
  IdentificationMethod.manual: 'manual',
};
