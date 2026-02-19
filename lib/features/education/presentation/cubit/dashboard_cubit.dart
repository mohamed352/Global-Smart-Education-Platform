import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';
import 'package:global_smart_education_platform/features/education/data/services/sync_manager.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/dashboard_state.dart';

/// Cubit that listens to reactive streams from the local DB (SSOT).
@injectable
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository, this._syncManager)
    : super(const DashboardState()) {
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

  /// O(1) lookup map keyed by 'userId_lessonId'.
  Map<String, Progress> _progressMap = <String, Progress>{};

  void _subscribeToStreams() {
    // Reactive streams from local DB
    _usersSub = _repository.watchUsers().listen((List<User> users) {
      log.d('Users stream: ${users.length} records', tag: LogTags.bloc);
      emit(state.copyWith(users: users));
    });

    _lessonsSub = _repository.watchLessons().listen((List<Lesson> lessons) {
      log.d('Lessons stream: ${lessons.length} records', tag: LogTags.bloc);
      emit(state.copyWith(lessons: lessons));
    });

    _progressesSub = _repository.watchProgresses().listen((
      List<Progress> progresses,
    ) {
      log.d(
        'Progresses stream: ${progresses.length} records',
        tag: LogTags.bloc,
      );
      _progressMap = <String, Progress>{
        for (final Progress p in progresses) '${p.userId}_${p.lessonId}': p,
      };
      emit(state.copyWith(progresses: progresses));
    });

    _syncQueueSub = _repository.watchSyncQueue().listen((
      List<SyncQueueItem> items,
    ) {
      log.d(
        'SyncQueue stream: ${items.length} pending items',
        tag: LogTags.bloc,
      );
      emit(state.copyWith(pendingSyncCount: items.length));
    });

    // Connectivity & sync status from SyncManager
    _connectivitySub = _syncManager.connectivityStream.listen((
      ConnectivityState connectivity,
    ) {
      log.i('Connectivity state: ${connectivity.name}', tag: LogTags.bloc);
      emit(state.copyWith(connectivity: connectivity));
    });

    _syncStatusSub = _syncManager.statusStream.listen((
      SyncEngineStatus status,
    ) {
      log.i('Sync engine status: ${status.name}', tag: LogTags.bloc);
      emit(state.copyWith(syncStatus: status));
    });
  }

  /// Updates progress offline-first: writes to local DB + adds to SyncQueue.
  Future<void> updateProgress({
    required String userId,
    required String lessonId,
    int incrementBy = 10,
  }) async {
    emit(state.copyWith(errorMessage: null));
    try {
      log.i(
        'Updating progress (user=$userId, lesson=$lessonId, +$incrementBy%)',
        tag: LogTags.bloc,
      );
      await _repository.updateProgress(
        userId: userId,
        lessonId: lessonId,
        incrementBy: incrementBy,
      );
    } catch (e, s) {
      log.e(
        'Failed to update progress',
        tag: LogTags.bloc,
        error: e,
        stackTrace: s,
      );
      emit(state.copyWith(errorMessage: 'Failed to update progress'));
    }
  }

  /// Triggers a manual sync.
  Future<void> triggerSync() async {
    emit(state.copyWith(errorMessage: null));
    log.i('Manual sync triggered', tag: LogTags.bloc);
    await _syncManager.performFullSync();
  }

  /// Seeds a conflict scenario on the mock server for demo purposes.
  void seedConflictDemo({
    required String progressId,
    required String userId,
    required String lessonId,
  }) {
    log.i('Seeding conflict demo data on mock server', tag: LogTags.bloc);
    _syncManager.seedConflictData(
      progressId: progressId,
      userId: userId,
      lessonId: lessonId,
      progressPercent: 95,
      updatedAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  /// Helper: get progress percent for a given user+lesson. O(1) lookup.
  int getProgressPercent(String userId, String lessonId) {
    return _progressMap['${userId}_$lessonId']?.progressPercent ?? 0;
  }

  /// Helper: get sync status string for a given user+lesson. O(1) lookup.
  String getProgressSyncStatus(String userId, String lessonId) {
    return _progressMap['${userId}_$lessonId']?.syncStatus ?? 'none';
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
