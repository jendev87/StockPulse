// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Product {

 String get sku; String get name; String? get barcode; bool get hasBarcode; int get systemQty; String get visualDescription;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Product;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.sku, _this.sku) || other.sku == _this.sku)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.barcode, _this.barcode) || other.barcode == _this.barcode)&&(identical(other.hasBarcode, _this.hasBarcode) || other.hasBarcode == _this.hasBarcode)&&(identical(other.systemQty, _this.systemQty) || other.systemQty == _this.systemQty)&&(identical(other.visualDescription, _this.visualDescription) || other.visualDescription == _this.visualDescription));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Product;
  return Object.hash(runtimeType,_this.sku,_this.name,_this.barcode,_this.hasBarcode,_this.systemQty,_this.visualDescription);
}

@override
String toString() {
  final _this = this as Product;
  return 'Product(sku: ${_this.sku}, name: ${_this.name}, barcode: ${_this.barcode}, hasBarcode: ${_this.hasBarcode}, systemQty: ${_this.systemQty}, visualDescription: ${_this.visualDescription})';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 String sku, String name, String? barcode, bool hasBarcode, int systemQty, String visualDescription
});




}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sku = null,Object? name = null,Object? barcode = freezed,Object? hasBarcode = null,Object? systemQty = null,Object? visualDescription = null,}) {
  return _then(Product(
sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,hasBarcode: null == hasBarcode ? _self.hasBarcode : hasBarcode // ignore: cast_nullable_to_non_nullable
as bool,systemQty: null == systemQty ? _self.systemQty : systemQty // ignore: cast_nullable_to_non_nullable
as int,visualDescription: null == visualDescription ? _self.visualDescription : visualDescription // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sku,  String name,  String? barcode,  bool hasBarcode,  int systemQty,  String visualDescription)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.sku,_that.name,_that.barcode,_that.hasBarcode,_that.systemQty,_that.visualDescription);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sku,  String name,  String? barcode,  bool hasBarcode,  int systemQty,  String visualDescription)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.sku,_that.name,_that.barcode,_that.hasBarcode,_that.systemQty,_that.visualDescription);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sku,  String name,  String? barcode,  bool hasBarcode,  int systemQty,  String visualDescription)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.sku,_that.name,_that.barcode,_that.hasBarcode,_that.systemQty,_that.visualDescription);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Product implements Product {
  const _Product({required this.sku, required this.name, this.barcode, required this.hasBarcode, required this.systemQty, required this.visualDescription});
  factory _Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

@override final  String sku;
@override final  String name;
@override final  String? barcode;
@override final  bool hasBarcode;
@override final  int systemQty;
@override final  String visualDescription;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.name, name) || other.name == name)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.hasBarcode, hasBarcode) || other.hasBarcode == hasBarcode)&&(identical(other.systemQty, systemQty) || other.systemQty == systemQty)&&(identical(other.visualDescription, visualDescription) || other.visualDescription == visualDescription));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sku,name,barcode,hasBarcode,systemQty,visualDescription);
}

@override
String toString() {
    return 'Product(sku: $sku, name: $name, barcode: $barcode, hasBarcode: $hasBarcode, systemQty: $systemQty, visualDescription: $visualDescription)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 String sku, String name, String? barcode, bool hasBarcode, int systemQty, String visualDescription
});




}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sku = null,Object? name = null,Object? barcode = freezed,Object? hasBarcode = null,Object? systemQty = null,Object? visualDescription = null,}) {
  return _then(_Product(
sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,hasBarcode: null == hasBarcode ? _self.hasBarcode : hasBarcode // ignore: cast_nullable_to_non_nullable
as bool,systemQty: null == systemQty ? _self.systemQty : systemQty // ignore: cast_nullable_to_non_nullable
as int,visualDescription: null == visualDescription ? _self.visualDescription : visualDescription // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
