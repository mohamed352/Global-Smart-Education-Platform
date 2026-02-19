import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/services/sync_manager.dart';

part 'dashboard_state.freezed.dart';

@freezed
class DashboardState with _$DashboardState {
  const factory DashboardState({
    @Default(<User>[]) List<User> users,
    @Default(<Lesson>[]) List<Lesson> lessons,
    @Default(<Progress>[]) List<Progress> progresses,
    @Default(0) int pendingSyncCount,
    @Default(ConnectivityState.offline) ConnectivityState connectivity,
    @Default(SyncEngineStatus.idle) SyncEngineStatus syncStatus,
    String? errorMessage,
  }) = _DashboardState;
}
