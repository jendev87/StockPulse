// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_count.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StockCount {

 String get id; String get stockTakeId; String get sku; int get physicalQty; IdentificationMethod get method; double get confidence; DateTime get timestamp;
/// Create a copy of StockCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockCountCopyWith<StockCount> get copyWith => _$StockCountCopyWithImpl<StockCount>(this as StockCount, _$identity);

  /// Serializes this StockCount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StockCount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockCount&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.stockTakeId, _this.stockTakeId) || other.stockTakeId == _this.stockTakeId)&&(identical(other.sku, _this.sku) || other.sku == _this.sku)&&(identical(other.physicalQty, _this.physicalQty) || other.physicalQty == _this.physicalQty)&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.confidence, _this.confidence) || other.confidence == _this.confidence)&&(identical(other.timestamp, _this.timestamp) || other.timestamp == _this.timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StockCount;
  return Object.hash(runtimeType,_this.id,_this.stockTakeId,_this.sku,_this.physicalQty,_this.method,_this.confidence,_this.timestamp);
}

@override
String toString() {
  final _this = this as StockCount;
  return 'StockCount(id: ${_this.id}, stockTakeId: ${_this.stockTakeId}, sku: ${_this.sku}, physicalQty: ${_this.physicalQty}, method: ${_this.method}, confidence: ${_this.confidence}, timestamp: ${_this.timestamp})';
}


}

/// @nodoc
abstract mixin class $StockCountCopyWith<$Res>  {
  factory $StockCountCopyWith(StockCount value, $Res Function(StockCount) _then) = _$StockCountCopyWithImpl;
@useResult
$Res call({
 String id, String stockTakeId, String sku, int physicalQty, IdentificationMethod method, double confidence, DateTime timestamp
});




}
/// @nodoc
class _$StockCountCopyWithImpl<$Res>
    implements $StockCountCopyWith<$Res> {
  _$StockCountCopyWithImpl(this._self, this._then);

  final StockCount _self;
  final $Res Function(StockCount) _then;

/// Create a copy of StockCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stockTakeId = null,Object? sku = null,Object? physicalQty = null,Object? method = null,Object? confidence = null,Object? timestamp = null,}) {
  return _then(StockCount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stockTakeId: null == stockTakeId ? _self.stockTakeId : stockTakeId // ignore: cast_nullable_to_non_nullable
as String,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,physicalQty: null == physicalQty ? _self.physicalQty : physicalQty // ignore: cast_nullable_to_non_nullable
as int,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as IdentificationMethod,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [StockCount].
extension StockCountPatterns on StockCount {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockCount() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockCount value)  $default,){
final _that = this;
switch (_that) {
case _StockCount():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockCount value)?  $default,){
final _that = this;
switch (_that) {
case _StockCount() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String stockTakeId,  String sku,  int physicalQty,  IdentificationMethod method,  double confidence,  DateTime timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockCount() when $default != null:
return $default(_that.id,_that.stockTakeId,_that.sku,_that.physicalQty,_that.method,_that.confidence,_that.timestamp);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String stockTakeId,  String sku,  int physicalQty,  IdentificationMethod method,  double confidence,  DateTime timestamp)  $default,) {final _that = this;
switch (_that) {
case _StockCount():
return $default(_that.id,_that.stockTakeId,_that.sku,_that.physicalQty,_that.method,_that.confidence,_that.timestamp);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String stockTakeId,  String sku,  int physicalQty,  IdentificationMethod method,  double confidence,  DateTime timestamp)?  $default,) {final _that = this;
switch (_that) {
case _StockCount() when $default != null:
return $default(_that.id,_that.stockTakeId,_that.sku,_that.physicalQty,_that.method,_that.confidence,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockCount implements StockCount {
  const _StockCount({required this.id, required this.stockTakeId, required this.sku, required this.physicalQty, required this.method, this.confidence = 1.0, required this.timestamp});
  factory _StockCount.fromJson(Map<String, dynamic> json) => _$StockCountFromJson(json);

@override final  String id;
@override final  String stockTakeId;
@override final  String sku;
@override final  int physicalQty;
@override final  IdentificationMethod method;
@override@JsonKey() final  double confidence;
@override final  DateTime timestamp;

/// Create a copy of StockCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockCountCopyWith<_StockCount> get copyWith => __$StockCountCopyWithImpl<_StockCount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockCountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockCount&&(identical(other.id, id) || other.id == id)&&(identical(other.stockTakeId, stockTakeId) || other.stockTakeId == stockTakeId)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.physicalQty, physicalQty) || other.physicalQty == physicalQty)&&(identical(other.method, method) || other.method == method)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,stockTakeId,sku,physicalQty,method,confidence,timestamp);
}

@override
String toString() {
    return 'StockCount(id: $id, stockTakeId: $stockTakeId, sku: $sku, physicalQty: $physicalQty, method: $method, confidence: $confidence, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$StockCountCopyWith<$Res> implements $StockCountCopyWith<$Res> {
  factory _$StockCountCopyWith(_StockCount value, $Res Function(_StockCount) _then) = __$StockCountCopyWithImpl;
@override @useResult
$Res call({
 String id, String stockTakeId, String sku, int physicalQty, IdentificationMethod method, double confidence, DateTime timestamp
});




}
/// @nodoc
class __$StockCountCopyWithImpl<$Res>
    implements _$StockCountCopyWith<$Res> {
  __$StockCountCopyWithImpl(this._self, this._then);

  final _StockCount _self;
  final $Res Function(_StockCount) _then;

/// Create a copy of StockCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stockTakeId = null,Object? sku = null,Object? physicalQty = null,Object? method = null,Object? confidence = null,Object? timestamp = null,}) {
  return _then(_StockCount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stockTakeId: null == stockTakeId ? _self.stockTakeId : stockTakeId // ignore: cast_nullable_to_non_nullable
as String,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,physicalQty: null == physicalQty ? _self.physicalQty : physicalQty // ignore: cast_nullable_to_non_nullable
as int,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as IdentificationMethod,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
