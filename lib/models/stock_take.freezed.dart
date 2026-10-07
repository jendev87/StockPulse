// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_take.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StockTake {

 String get id; StockTakeStatus get status; DateTime get createdAt; List<StockCount> get counts;
/// Create a copy of StockTake
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockTakeCopyWith<StockTake> get copyWith => _$StockTakeCopyWithImpl<StockTake>(this as StockTake, _$identity);

  /// Serializes this StockTake to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StockTake;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockTake&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&const DeepCollectionEquality().equals(other.counts, _this.counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StockTake;
  return Object.hash(runtimeType,_this.id,_this.status,_this.createdAt,const DeepCollectionEquality().hash(_this.counts));
}

@override
String toString() {
  final _this = this as StockTake;
  return 'StockTake(id: ${_this.id}, status: ${_this.status}, createdAt: ${_this.createdAt}, counts: ${_this.counts})';
}


}

/// @nodoc
abstract mixin class $StockTakeCopyWith<$Res>  {
  factory $StockTakeCopyWith(StockTake value, $Res Function(StockTake) _then) = _$StockTakeCopyWithImpl;
@useResult
$Res call({
 String id, StockTakeStatus status, DateTime createdAt, List<StockCount> counts
});




}
/// @nodoc
class _$StockTakeCopyWithImpl<$Res>
    implements $StockTakeCopyWith<$Res> {
  _$StockTakeCopyWithImpl(this._self, this._then);

  final StockTake _self;
  final $Res Function(StockTake) _then;

/// Create a copy of StockTake
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? createdAt = null,Object? counts = null,}) {
  return _then(StockTake(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StockTakeStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as List<StockCount>,
  ));
}

}


/// Adds pattern-matching-related methods to [StockTake].
extension StockTakePatterns on StockTake {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockTake value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockTake() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockTake value)  $default,){
final _that = this;
switch (_that) {
case _StockTake():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockTake value)?  $default,){
final _that = this;
switch (_that) {
case _StockTake() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  StockTakeStatus status,  DateTime createdAt,  List<StockCount> counts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockTake() when $default != null:
return $default(_that.id,_that.status,_that.createdAt,_that.counts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  StockTakeStatus status,  DateTime createdAt,  List<StockCount> counts)  $default,) {final _that = this;
switch (_that) {
case _StockTake():
return $default(_that.id,_that.status,_that.createdAt,_that.counts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  StockTakeStatus status,  DateTime createdAt,  List<StockCount> counts)?  $default,) {final _that = this;
switch (_that) {
case _StockTake() when $default != null:
return $default(_that.id,_that.status,_that.createdAt,_that.counts);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _StockTake implements StockTake {
  const _StockTake({required this.id, required this.status, required this.createdAt, required  List<StockCount> counts}): _counts = counts;
  factory _StockTake.fromJson(Map<String, dynamic> json) => _$StockTakeFromJson(json);

@override final  String id;
@override final  StockTakeStatus status;
@override final  DateTime createdAt;
 final  List<StockCount> _counts;
@override List<StockCount> get counts {
  if (_counts is EqualUnmodifiableListView) return _counts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_counts);
}


/// Create a copy of StockTake
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockTakeCopyWith<_StockTake> get copyWith => __$StockTakeCopyWithImpl<_StockTake>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockTakeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockTake&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.counts, _counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,status,createdAt,const DeepCollectionEquality().hash(_counts));
}

@override
String toString() {
    return 'StockTake(id: $id, status: $status, createdAt: $createdAt, counts: $counts)';
}


}

/// @nodoc
abstract mixin class _$StockTakeCopyWith<$Res> implements $StockTakeCopyWith<$Res> {
  factory _$StockTakeCopyWith(_StockTake value, $Res Function(_StockTake) _then) = __$StockTakeCopyWithImpl;
@override @useResult
$Res call({
 String id, StockTakeStatus status, DateTime createdAt, List<StockCount> counts
});




}
/// @nodoc
class __$StockTakeCopyWithImpl<$Res>
    implements _$StockTakeCopyWith<$Res> {
  __$StockTakeCopyWithImpl(this._self, this._then);

  final _StockTake _self;
  final $Res Function(_StockTake) _then;

/// Create a copy of StockTake
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? createdAt = null,Object? counts = null,}) {
  return _then(_StockTake(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StockTakeStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as List<StockCount>,
  ));
}


}

// dart format on
