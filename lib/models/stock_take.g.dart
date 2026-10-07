// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_take.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StockTake _$StockTakeFromJson(Map<String, dynamic> json) => _StockTake(
  id: json['id'] as String,
  status: $enumDecode(_$StockTakeStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  counts: (json['counts'] as List<dynamic>)
      .map((e) => StockCount.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$StockTakeToJson(_StockTake instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$StockTakeStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'counts': instance.counts.map((e) => e.toJson()).toList(),
    };

const _$StockTakeStatusEnumMap = {
  StockTakeStatus.draft: 'draft',
  StockTakeStatus.inProgress: 'inProgress',
  StockTakeStatus.pendingApproval: 'pendingApproval',
  StockTakeStatus.approved: 'approved',
  StockTakeStatus.completed: 'completed',
};
