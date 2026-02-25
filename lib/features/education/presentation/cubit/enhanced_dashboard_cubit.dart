import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';
import 'package:global_smart_education_platform/features/education/data/services/sync_manager.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/enhanced_dashboard_state.dart';

/// Enhanced Dashboard Cubit مع ميزات إحصائية متقدمة
@injectable
class EnhancedDashboardCubit
    extends Cubit<EnhancedDashboardState> {
  EnhancedDashboardCubit(
    this._repository,
    this._syncManager,
  ) : super(const EnhancedDashboardState()) {
    _subscribeToStreams();
  }

  final EducationRepository _repository;
  final SyncManager _syncManager;

  StreamSubscription<List<User>>? _usersSub;
  StreamSubscription<List<Lesson>>? _lessonsSub;
  StreamSubscription<List<Progress>>? _progressesSub;
  StreamSubscription<List<SyncQueueItem>>? _syncQueueSub;
  StreamSubscription<ConnectivityState>? _connectivitySub;
  StreamSubscription<SyncEngineStatus>? _syncStatusSub;

  Map<String, Progress> _progressMap = <String, Progress>{};

  void _subscribeToStreams() {
    _usersSub = _repository.watchUsers().listen((
      List<User> users,
    ) {
      log.d('Users stream updated', tag: LogTags.bloc);
      emit(state.copyWith(users: users));
      _calculateStatistics();
    });

    _lessonsSub = _repository.watchLessons().listen((
      List<Lesson> lessons,
    ) {
      log.d(
        'Lessons stream updated: ${lessons.length} lessons',
        tag: LogTags.bloc,
      );
      emit(state.copyWith(lessons: lessons));
      _calculateStatistics();
    });

    _progressesSub = _repository.watchProgresses().listen((
      List<Progress> progresses,
    ) {
      log.d(
        'Progresses updated: ${progresses.length} records',
        tag: LogTags.bloc,
      );
      _progressMap = <String, Progress>{
        for (final Progress p in progresses)
          '${p.userId}_${p.lessonId}': p,
      };
      emit(state.copyWith(progresses: progresses));
      _calculateStatistics();
    });

    _syncQueueSub = _repository.watchSyncQueue().listen((
      List<SyncQueueItem> items,
    ) {
      emit(state.copyWith(pendingSyncCount: items.length));
    });

    _connectivitySub = _syncManager.connectivityStream
        .listen((ConnectivityState connectivity) {
          emit(state.copyWith(connectivity: connectivity));
        });

    _syncStatusSub = _syncManager.statusStream.listen((
      SyncEngineStatus status,
    ) {
      emit(state.copyWith(syncStatus: status));
    });
  }

  void _calculateStatistics() {
    if (state.users.isEmpty ||
        state.lessons.isEmpty ||
        state.progresses.isEmpty) {
      return;
    }

    final currentUser = state.users.first;
    final completedLessons = state.progresses
        .where(
          (p) =>
              p.userId == currentUser.id &&
              p.progressPercent == 100,
        )
        .length;

    final averageProgress =
        state.progresses
            .where((p) => p.userId == currentUser.id)
            .fold<int>(
              0,
              (sum, p) => sum + p.progressPercent,
            ) ~/
        (state.lessons.isNotEmpty
            ? state.lessons.length
            : 1);

    final totalLearningHours =
        state.progresses
            .where((p) => p.userId == currentUser.id)
            .fold<int>(
              0,
              (sum, p) =>
                  sum + ((p.progressPercent ~/ 10) * 3),
            ) ~/
        60;

    emit(
      state.copyWith(
        completedLessonsCount: completedLessons,
        averageProgressPercent: averageProgress,
        totalLearningHours: totalLearningHours,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  Future<void> updateProgress({
    required String userId,
    required String lessonId,
    int incrementBy = 10,
  }) async {
    try {
      await _repository.updateProgress(
        userId: userId,
        lessonId: lessonId,
        incrementBy: incrementBy,
      );
    } catch (e, s) {
      log.e(
        'Failed to update progress',
        error: e,
        stackTrace: s,
      );
      emit(
        state.copyWith(errorMessage: 'فشل تحديث التقدم'),
      );
    }
  }

  Future<void> triggerSync() async {
    log.i('Manual sync triggered');
    await _syncManager.performFullSync();
  }

  void simulateRemoteConflict(String progressId) {
    _syncManager.queueConflictSimulation(progressId);
  }

  int getProgressPercent(String userId, String lessonId) {
    return _progressMap['${userId}_$lessonId']
            ?.progressPercent ??
        0;
  }

  String getProgressSyncStatus(
    String userId,
    String lessonId,
  ) {
    return _progressMap['${userId}_$lessonId']
            ?.syncStatus ??
        'none';
  }

  String? getProgressId(String userId, String lessonId) {
    return _progressMap['${userId}_$lessonId']?.id;
  }

  List<dynamic> getLessonsByCategory(String category) {
    // معظم الدروس لا تملك حقل category، لذا نرجع الدروس كما هي
    return state.lessons.toList();
  }

  List<dynamic> getFeaturedLessons() {
    return state.lessons.take(3).toList();
  }

  @override
  Future<void> close() {
    _usersSub?.cancel();
    _lessonsSub?.cancel();
    _progressesSub?.cancel();
    _syncQueueSub?.cancel();
    _connectivitySub?.cancel();
    _syncStatusSub?.cancel();
    return super.close();
  }
}
