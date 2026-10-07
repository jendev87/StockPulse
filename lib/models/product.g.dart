// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  sku: json['sku'] as String,
  name: json['name'] as String,
  barcode: json['barcode'] as String?,
  hasBarcode: json['hasBarcode'] as bool,
  systemQty: (json['systemQty'] as num).toInt(),
  visualDescription: json['visualDescription'] as String,
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'sku': instance.sku,
  'name': instance.name,
  'barcode': instance.barcode,
  'hasBarcode': instance.hasBarcode,
  'systemQty': instance.systemQty,
  'visualDescription': instance.visualDescription,
};
