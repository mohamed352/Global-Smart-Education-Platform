import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/services/sync_manager.dart';

class EnhancedDashboardState {
  const EnhancedDashboardState({
    this.users = const <User>[],
    this.lessons = const <Lesson>[],
    this.progresses = const <Progress>[],
    this.connectivity = ConnectivityState.online,
    this.syncStatus = SyncEngineStatus.idle,
    this.pendingSyncCount = 0,
    this.errorMessage,
    this.completedLessonsCount = 0,
    this.averageProgressPercent = 0,
    this.totalLearningHours = 0,
    this.lastUpdated,
  });

  final List<User> users;
  final List<Lesson> lessons;
  final List<Progress> progresses;
  final ConnectivityState connectivity;
  final SyncEngineStatus syncStatus;
  final int pendingSyncCount;
  final String? errorMessage;
  final int completedLessonsCount;
  final int averageProgressPercent;
  final int totalLearningHours;
  final DateTime? lastUpdated;

  EnhancedDashboardState copyWith({
    List<User>? users,
    List<Lesson>? lessons,
    List<Progress>? progresses,
    ConnectivityState? connectivity,
    SyncEngineStatus? syncStatus,
    int? pendingSyncCount,
    String? errorMessage,
    int? completedLessonsCount,
    int? averageProgressPercent,
    int? totalLearningHours,
    DateTime? lastUpdated,
  }) {
    return EnhancedDashboardState(
      users: users ?? this.users,
      lessons: lessons ?? this.lessons,
      progresses: progresses ?? this.progresses,
      connectivity: connectivity ?? this.connectivity,
      syncStatus: syncStatus ?? this.syncStatus,
      pendingSyncCount:
          pendingSyncCount ?? this.pendingSyncCount,
      errorMessage: errorMessage ?? this.errorMessage,
      completedLessonsCount:
          completedLessonsCount ??
          this.completedLessonsCount,
      averageProgressPercent:
          averageProgressPercent ??
          this.averageProgressPercent,
      totalLearningHours:
          totalLearningHours ?? this.totalLearningHours,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
