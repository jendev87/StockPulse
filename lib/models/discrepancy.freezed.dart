// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discrepancy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Discrepancy {

 String get sku; String get productName; int get systemQty; int get physicalQty; int get variance; DiscrepancyType get type;
/// Create a copy of Discrepancy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscrepancyCopyWith<Discrepancy> get copyWith => _$DiscrepancyCopyWithImpl<Discrepancy>(this as Discrepancy, _$identity);

  /// Serializes this Discrepancy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Discrepancy;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Discrepancy&&(identical(other.sku, _this.sku) || other.sku == _this.sku)&&(identical(other.productName, _this.productName) || other.productName == _this.productName)&&(identical(other.systemQty, _this.systemQty) || other.systemQty == _this.systemQty)&&(identical(other.physicalQty, _this.physicalQty) || other.physicalQty == _this.physicalQty)&&(identical(other.variance, _this.variance) || other.variance == _this.variance)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Discrepancy;
  return Object.hash(runtimeType,_this.sku,_this.productName,_this.systemQty,_this.physicalQty,_this.variance,_this.type);
}

@override
String toString() {
  final _this = this as Discrepancy;
  return 'Discrepancy(sku: ${_this.sku}, productName: ${_this.productName}, systemQty: ${_this.systemQty}, physicalQty: ${_this.physicalQty}, variance: ${_this.variance}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $DiscrepancyCopyWith<$Res>  {
  factory $DiscrepancyCopyWith(Discrepancy value, $Res Function(Discrepancy) _then) = _$DiscrepancyCopyWithImpl;
@useResult
$Res call({
 String sku, String productName, int systemQty, int physicalQty, int variance, DiscrepancyType type
});




}
/// @nodoc
class _$DiscrepancyCopyWithImpl<$Res>
    implements $DiscrepancyCopyWith<$Res> {
  _$DiscrepancyCopyWithImpl(this._self, this._then);

  final Discrepancy _self;
  final $Res Function(Discrepancy) _then;

/// Create a copy of Discrepancy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sku = null,Object? productName = null,Object? systemQty = null,Object? physicalQty = null,Object? variance = null,Object? type = null,}) {
  return _then(Discrepancy(
sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,systemQty: null == systemQty ? _self.systemQty : systemQty // ignore: cast_nullable_to_non_nullable
as int,physicalQty: null == physicalQty ? _self.physicalQty : physicalQty // ignore: cast_nullable_to_non_nullable
as int,variance: null == variance ? _self.variance : variance // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DiscrepancyType,
  ));
}

}


/// Adds pattern-matching-related methods to [Discrepancy].
extension DiscrepancyPatterns on Discrepancy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Discrepancy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Discrepancy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Discrepancy value)  $default,){
final _that = this;
switch (_that) {
case _Discrepancy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Discrepancy value)?  $default,){
final _that = this;
switch (_that) {
case _Discrepancy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sku,  String productName,  int systemQty,  int physicalQty,  int variance,  DiscrepancyType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Discrepancy() when $default != null:
return $default(_that.sku,_that.productName,_that.systemQty,_that.physicalQty,_that.variance,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sku,  String productName,  int systemQty,  int physicalQty,  int variance,  DiscrepancyType type)  $default,) {final _that = this;
switch (_that) {
case _Discrepancy():
return $default(_that.sku,_that.productName,_that.systemQty,_that.physicalQty,_that.variance,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sku,  String productName,  int systemQty,  int physicalQty,  int variance,  DiscrepancyType type)?  $default,) {final _that = this;
switch (_that) {
case _Discrepancy() when $default != null:
return $default(_that.sku,_that.productName,_that.systemQty,_that.physicalQty,_that.variance,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Discrepancy implements Discrepancy {
  const _Discrepancy({required this.sku, required this.productName, required this.systemQty, required this.physicalQty, required this.variance, required this.type});
  factory _Discrepancy.fromJson(Map<String, dynamic> json) => _$DiscrepancyFromJson(json);

@override final  String sku;
@override final  String productName;
@override final  int systemQty;
@override final  int physicalQty;
@override final  int variance;
@override final  DiscrepancyType type;

/// Create a copy of Discrepancy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscrepancyCopyWith<_Discrepancy> get copyWith => __$DiscrepancyCopyWithImpl<_Discrepancy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiscrepancyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Discrepancy&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.systemQty, systemQty) || other.systemQty == systemQty)&&(identical(other.physicalQty, physicalQty) || other.physicalQty == physicalQty)&&(identical(other.variance, variance) || other.variance == variance)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sku,productName,systemQty,physicalQty,variance,type);
}

@override
String toString() {
    return 'Discrepancy(sku: $sku, productName: $productName, systemQty: $systemQty, physicalQty: $physicalQty, variance: $variance, type: $type)';
}


}

/// @nodoc
abstract mixin class _$DiscrepancyCopyWith<$Res> implements $DiscrepancyCopyWith<$Res> {
  factory _$DiscrepancyCopyWith(_Discrepancy value, $Res Function(_Discrepancy) _then) = __$DiscrepancyCopyWithImpl;
@override @useResult
$Res call({
 String sku, String productName, int systemQty, int physicalQty, int variance, DiscrepancyType type
});




}
/// @nodoc
class __$DiscrepancyCopyWithImpl<$Res>
    implements _$DiscrepancyCopyWith<$Res> {
  __$DiscrepancyCopyWithImpl(this._self, this._then);

  final _Discrepancy _self;
  final $Res Function(_Discrepancy) _then;

/// Create a copy of Discrepancy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sku = null,Object? productName = null,Object? systemQty = null,Object? physicalQty = null,Object? variance = null,Object? type = null,}) {
  return _then(_Discrepancy(
sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,systemQty: null == systemQty ? _self.systemQty : systemQty // ignore: cast_nullable_to_non_nullable
as int,physicalQty: null == physicalQty ? _self.physicalQty : physicalQty // ignore: cast_nullable_to_non_nullable
as int,variance: null == variance ? _self.variance : variance // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DiscrepancyType,
  ));
}


}

// dart format on
