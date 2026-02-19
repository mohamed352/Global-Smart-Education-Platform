// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DashboardState {
  List<User> get users => throw _privateConstructorUsedError;
  List<Lesson> get lessons => throw _privateConstructorUsedError;
  List<Progress> get progresses => throw _privateConstructorUsedError;
  int get pendingSyncCount => throw _privateConstructorUsedError;
  ConnectivityState get connectivity => throw _privateConstructorUsedError;
  SyncEngineStatus get syncStatus => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DashboardStateCopyWith<DashboardState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardStateCopyWith<$Res> {
  factory $DashboardStateCopyWith(
    DashboardState value,
    $Res Function(DashboardState) then,
  ) = _$DashboardStateCopyWithImpl<$Res, DashboardState>;
  @useResult
  $Res call({
    List<User> users,
    List<Lesson> lessons,
    List<Progress> progresses,
    int pendingSyncCount,
    ConnectivityState connectivity,
    SyncEngineStatus syncStatus,
    String? errorMessage,
  });
}

/// @nodoc
class _$DashboardStateCopyWithImpl<$Res, $Val extends DashboardState>
    implements $DashboardStateCopyWith<$Res> {
  _$DashboardStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? users = null,
    Object? lessons = null,
    Object? progresses = null,
    Object? pendingSyncCount = null,
    Object? connectivity = null,
    Object? syncStatus = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            users: null == users
                ? _value.users
                : users // ignore: cast_nullable_to_non_nullable
                      as List<User>,
            lessons: null == lessons
                ? _value.lessons
                : lessons // ignore: cast_nullable_to_non_nullable
                      as List<Lesson>,
            progresses: null == progresses
                ? _value.progresses
                : progresses // ignore: cast_nullable_to_non_nullable
                      as List<Progress>,
            pendingSyncCount: null == pendingSyncCount
                ? _value.pendingSyncCount
                : pendingSyncCount // ignore: cast_nullable_to_non_nullable
                      as int,
            connectivity: null == connectivity
                ? _value.connectivity
                : connectivity // ignore: cast_nullable_to_non_nullable
                      as ConnectivityState,
            syncStatus: null == syncStatus
                ? _value.syncStatus
                : syncStatus // ignore: cast_nullable_to_non_nullable
                      as SyncEngineStatus,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DashboardStateImplCopyWith<$Res>
    implements $DashboardStateCopyWith<$Res> {
  factory _$$DashboardStateImplCopyWith(
    _$DashboardStateImpl value,
    $Res Function(_$DashboardStateImpl) then,
  ) = __$$DashboardStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<User> users,
    List<Lesson> lessons,
    List<Progress> progresses,
    int pendingSyncCount,
    ConnectivityState connectivity,
    SyncEngineStatus syncStatus,
    String? errorMessage,
  });
}

/// @nodoc
class __$$DashboardStateImplCopyWithImpl<$Res>
    extends _$DashboardStateCopyWithImpl<$Res, _$DashboardStateImpl>
    implements _$$DashboardStateImplCopyWith<$Res> {
  __$$DashboardStateImplCopyWithImpl(
    _$DashboardStateImpl _value,
    $Res Function(_$DashboardStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? users = null,
    Object? lessons = null,
    Object? progresses = null,
    Object? pendingSyncCount = null,
    Object? connectivity = null,
    Object? syncStatus = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$DashboardStateImpl(
        users: null == users
            ? _value._users
            : users // ignore: cast_nullable_to_non_nullable
                  as List<User>,
        lessons: null == lessons
            ? _value._lessons
            : lessons // ignore: cast_nullable_to_non_nullable
                  as List<Lesson>,
        progresses: null == progresses
            ? _value._progresses
            : progresses // ignore: cast_nullable_to_non_nullable
                  as List<Progress>,
        pendingSyncCount: null == pendingSyncCount
            ? _value.pendingSyncCount
            : pendingSyncCount // ignore: cast_nullable_to_non_nullable
                  as int,
        connectivity: null == connectivity
            ? _value.connectivity
            : connectivity // ignore: cast_nullable_to_non_nullable
                  as ConnectivityState,
        syncStatus: null == syncStatus
            ? _value.syncStatus
            : syncStatus // ignore: cast_nullable_to_non_nullable
                  as SyncEngineStatus,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$DashboardStateImpl implements _DashboardState {
  const _$DashboardStateImpl({
    final List<User> users = const <User>[],
    final List<Lesson> lessons = const <Lesson>[],
    final List<Progress> progresses = const <Progress>[],
    this.pendingSyncCount = 0,
    this.connectivity = ConnectivityState.offline,
    this.syncStatus = SyncEngineStatus.idle,
    this.errorMessage,
  }) : _users = users,
       _lessons = lessons,
       _progresses = progresses;

  final List<User> _users;
  @override
  @JsonKey()
  List<User> get users {
    if (_users is EqualUnmodifiableListView) return _users;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_users);
  }

  final List<Lesson> _lessons;
  @override
  @JsonKey()
  List<Lesson> get lessons {
    if (_lessons is EqualUnmodifiableListView) return _lessons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lessons);
  }

  final List<Progress> _progresses;
  @override
  @JsonKey()
  List<Progress> get progresses {
    if (_progresses is EqualUnmodifiableListView) return _progresses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_progresses);
  }

  @override
  @JsonKey()
  final int pendingSyncCount;
  @override
  @JsonKey()
  final ConnectivityState connectivity;
  @override
  @JsonKey()
  final SyncEngineStatus syncStatus;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'DashboardState(users: $users, lessons: $lessons, progresses: $progresses, pendingSyncCount: $pendingSyncCount, connectivity: $connectivity, syncStatus: $syncStatus, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardStateImpl &&
            const DeepCollectionEquality().equals(other._users, _users) &&
            const DeepCollectionEquality().equals(other._lessons, _lessons) &&
            const DeepCollectionEquality().equals(
              other._progresses,
              _progresses,
            ) &&
            (identical(other.pendingSyncCount, pendingSyncCount) ||
                other.pendingSyncCount == pendingSyncCount) &&
            (identical(other.connectivity, connectivity) ||
                other.connectivity == connectivity) &&
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_users),
    const DeepCollectionEquality().hash(_lessons),
    const DeepCollectionEquality().hash(_progresses),
    pendingSyncCount,
    connectivity,
    syncStatus,
    errorMessage,
  );

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardStateImplCopyWith<_$DashboardStateImpl> get copyWith =>
      __$$DashboardStateImplCopyWithImpl<_$DashboardStateImpl>(
        this,
        _$identity,
      );
}

abstract class _DashboardState implements DashboardState {
  const factory _DashboardState({
    final List<User> users,
    final List<Lesson> lessons,
    final List<Progress> progresses,
    final int pendingSyncCount,
    final ConnectivityState connectivity,
    final SyncEngineStatus syncStatus,
    final String? errorMessage,
  }) = _$DashboardStateImpl;

  @override
  List<User> get users;
  @override
  List<Lesson> get lessons;
  @override
  List<Progress> get progresses;
  @override
  int get pendingSyncCount;
  @override
  ConnectivityState get connectivity;
  @override
  SyncEngineStatus get syncStatus;
  @override
  String? get errorMessage;

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardStateImplCopyWith<_$DashboardStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
