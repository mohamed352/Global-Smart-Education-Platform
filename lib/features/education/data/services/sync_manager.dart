import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';

import 'package:global_smart_education_platform/core/constants/sync_constants.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/sync_repository.dart';

void disposeSyncManager(SyncManager instance) => instance.dispose();

enum ConnectivityState { online, offline }

enum SyncEngineStatus { idle, syncing, error }

/// Dedicated service that monitors connectivity and processes the SyncQueue.
@LazySingleton(dispose: disposeSyncManager)
class SyncManager {
  SyncManager(this._repository, this._syncRepository);

  final EducationRepository _repository;
  final SyncRepository _syncRepository;

  final StreamController<SyncEngineStatus> _statusController =
      StreamController<SyncEngineStatus>.broadcast();

  final StreamController<ConnectivityState> _connectivityController =
      StreamController<ConnectivityState>.broadcast();

  Stream<SyncEngineStatus> get statusStream => _statusController.stream;
  Stream<ConnectivityState> get connectivityStream =>
      _connectivityController.stream;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  ConnectivityState _currentConnectivity = ConnectivityState.offline;
  bool _isSyncing = false;

  ConnectivityState get currentConnectivity => _currentConnectivity;

  @visibleForTesting
  set currentConnectivityForTest(ConnectivityState state) {
    _currentConnectivity = state;
  }

  /// Initialize connectivity listener.
  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    log.i('SyncManager initialized', tag: LogTags.sync);

    // Check initial connectivity
    Connectivity().checkConnectivity().then(_onConnectivityChanged);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final bool isConnected = results.any(
      (ConnectivityResult r) => r != ConnectivityResult.none,
    );

    final ConnectivityState newState = isConnected
        ? ConnectivityState.online
        : ConnectivityState.offline;

    if (newState != _currentConnectivity) {
      _currentConnectivity = newState;
      _connectivityController.add(newState);
      log.i('Connectivity changed: ${newState.name}', tag: LogTags.sync);

      if (newState == ConnectivityState.online) {
        performFullSync();
      }
    }
  }

  /// Runs a full sync cycle: upload queue → download updates.
  Future<void> performFullSync() async {
    if (_isSyncing) {
      log.d('Sync already in progress, skipping', tag: LogTags.sync);
      return;
    }
    if (_currentConnectivity == ConnectivityState.offline) {
      log.d('Offline, skipping sync', tag: LogTags.sync);
      return;
    }

    _isSyncing = true;
    _statusController.add(SyncEngineStatus.syncing);
    log.i('=== Full Sync Started ===', tag: LogTags.sync);

    try {
      await _processUploadQueue();
      await _processDownloadUpdates();
      _statusController.add(SyncEngineStatus.idle);
      log.i('=== Full Sync Completed ===', tag: LogTags.sync);
    } catch (e, s) {
      log.e('Full sync failed', tag: LogTags.sync, error: e, stackTrace: s);
      _statusController.add(SyncEngineStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  /// Reads from SyncQueue, attempts to upload each item.
  /// On success: mark local record synced + remove queue item.
  /// On failure: increment retryCount (skip if exceeded max).
  Future<void> _processUploadQueue() async {
    final List<SyncQueueItem> pendingItems = await _repository
        .getPendingSyncItems();

    if (pendingItems.isEmpty) {
      log.d('Upload queue empty', tag: LogTags.sync);
      return;
    }

    log.i(
      'Processing upload queue: ${pendingItems.length} items',
      tag: LogTags.sync,
    );

    for (final SyncQueueItem item in pendingItems) {
      if (item.retryCount >= SyncConstants.maxRetryCount) {
        log.w(
          'Sync item ${item.id} exceeded max retries '
          '(${item.retryCount}/${SyncConstants.maxRetryCount}). Skipping.',
          tag: LogTags.sync,
        );
        continue;
      }

      try {
        final Map<String, dynamic> payload =
            jsonDecode(item.payload) as Map<String, dynamic>;

        await _syncRepository.uploadProgress(payload);

        // Upload succeeded → mark synced + remove from queue
        await _repository.markProgressSynced(item.entityId);
        await _repository.deleteSyncQueueItem(item.id);
        log.i(
          'Uploaded & synced queue item ${item.id} '
          '(entity=${item.entityId})',
          tag: LogTags.sync,
        );
      } catch (e) {
        await _repository.incrementRetryCount(item.id, item.retryCount);
        log.w(
          'Upload failed for queue item ${item.id}. '
          'Retry ${item.retryCount + 1}/${SyncConstants.maxRetryCount}',
          tag: LogTags.sync,
        );
      }
    }
  }

  /// Fetches remote updates and applies LWW conflict resolution.
  Future<void> _processDownloadUpdates() async {
    log.d('Downloading remote updates...', tag: LogTags.sync);

    try {
      // Fetch and upsert users
      final List<Map<String, dynamic>> remoteUsers = await _syncRepository
          .fetchUsers();
      for (final Map<String, dynamic> userData in remoteUsers) {
        await _repository.upsertUserFromRemote(userData);
      }

      // Fetch and upsert lessons
      final List<Map<String, dynamic>> remoteLessons = await _syncRepository
          .fetchLessons();
      for (final Map<String, dynamic> lessonData in remoteLessons) {
        await _repository.upsertLessonFromRemote(lessonData);
      }

      // Fetch progress with LWW conflict resolution
      final List<Map<String, dynamic>> remoteProgresses = await _syncRepository
          .fetchAllProgress();
      int conflictsResolved = 0;
      for (final Map<String, dynamic> progressData in remoteProgresses) {
        final bool wasUpdated = await _repository.upsertProgressIfNewer(
          progressData,
        );
        if (wasUpdated) {
          conflictsResolved++;
        }
      }

      log.i(
        'Download complete: ${remoteUsers.length} users, '
        '${remoteLessons.length} lessons, '
        '${remoteProgresses.length} progress records '
        '($conflictsResolved applied via LWW)',
        tag: LogTags.sync,
      );
    } catch (e, s) {
      log.e('Download failed', tag: LogTags.sync, error: e, stackTrace: s);
    }
  }

  /// Seeds initial data into local DB on first launch.
  Future<void> seedInitialData() async {
    final List<User> existingUsers = await _repository.getUsers();
    if (existingUsers.isNotEmpty) {
      log.d('Data already seeded, skipping', tag: LogTags.db);
      return;
    }

    log.i('Seeding initial data...', tag: LogTags.db);

    try {
      final List<Map<String, dynamic>> users = await _syncRepository
          .fetchUsers();
      for (final Map<String, dynamic> u in users) {
        await _repository.upsertUserFromRemote(u);
      }

      final List<Map<String, dynamic>> lessons = await _syncRepository
          .fetchLessons();
      for (final Map<String, dynamic> l in lessons) {
        await _repository.upsertLessonFromRemote(l);
      }

      log.i('Initial data seeded successfully', tag: LogTags.db);
    } catch (e, s) {
      log.e(
        'Failed to seed initial data',
        tag: LogTags.db,
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Directly writes a conflict document into Firestore for LWW demo.
  Future<void> simulateRemoteConflict(String progressId) async {
    await _syncRepository.simulateRemoteConflict(progressId);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
    _connectivityController.close();
    log.d('SyncManager disposed', tag: LogTags.sync);
  }
}
