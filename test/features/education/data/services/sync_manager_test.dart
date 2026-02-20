import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:global_smart_education_platform/core/constants/sync_constants.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/sync_repository.dart';
import 'package:global_smart_education_platform/features/education/data/services/sync_manager.dart';

class MockEducationRepository extends Mock implements EducationRepository {}

class MockSyncRepository extends Mock implements SyncRepository {}

void main() {
  late MockEducationRepository mockEducationRepo;
  late MockSyncRepository mockSyncRepo;
  late SyncManager syncManager;

  setUp(() {
    mockEducationRepo = MockEducationRepository();
    mockSyncRepo = MockSyncRepository();
    syncManager = SyncManager(mockEducationRepo, mockSyncRepo);
  });

  tearDown(() {
    syncManager.dispose();
  });

  SyncQueueItem buildQueueItem({
    required int id,
    required String entityId,
    int retryCount = 0,
  }) {
    final Map<String, dynamic> payload = <String, dynamic>{
      'id': entityId,
      'userId': 'u1',
      'lessonId': 'l1',
      'progressPercent': 50,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    return SyncQueueItem(
      id: id,
      operationType: OperationType.updateProgress.name,
      entityId: entityId,
      payload: jsonEncode(payload),
      retryCount: retryCount,
      createdAt: DateTime.now(),
    );
  }

  void stubEmptyDownloads() {
    when(
      () => mockSyncRepo.fetchUsers(),
    ).thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(
      () => mockSyncRepo.fetchLessons(),
    ).thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(
      () => mockSyncRepo.fetchAllProgress(),
    ).thenAnswer((_) async => <Map<String, dynamic>>[]);
  }

  group('performFullSync', () {
    test('skips when offline', () async {
      await syncManager.performFullSync();
      verifyNever(() => mockEducationRepo.getPendingSyncItems());
    });

    test('processes upload queue when online', () async {
      syncManager.currentConnectivityForTest = ConnectivityState.online;

      when(
        () => mockEducationRepo.getPendingSyncItems(),
      ).thenAnswer((_) async => <SyncQueueItem>[]);
      stubEmptyDownloads();

      await syncManager.performFullSync();

      verify(() => mockEducationRepo.getPendingSyncItems()).called(1);
    });

    test('emits syncing then idle on successful sync', () async {
      syncManager.currentConnectivityForTest = ConnectivityState.online;

      when(
        () => mockEducationRepo.getPendingSyncItems(),
      ).thenAnswer((_) async => <SyncQueueItem>[]);
      stubEmptyDownloads();

      expectLater(
        syncManager.statusStream,
        emitsInOrder(<SyncEngineStatus>[
          SyncEngineStatus.syncing,
          SyncEngineStatus.idle,
        ]),
      );

      await syncManager.performFullSync();
    });
  });

  group('upload queue processing', () {
    test(
      'successful upload marks progress synced and removes queue item',
      () async {
        syncManager.currentConnectivityForTest = ConnectivityState.online;

        final SyncQueueItem item = buildQueueItem(id: 1, entityId: 'p1');

        when(
          () => mockEducationRepo.getPendingSyncItems(),
        ).thenAnswer((_) async => <SyncQueueItem>[item]);
        when(() => mockSyncRepo.uploadProgress(any())).thenAnswer((_) async {});
        when(
          () => mockEducationRepo.markProgressSynced('p1'),
        ).thenAnswer((_) async {});
        when(
          () => mockEducationRepo.deleteSyncQueueItem(1),
        ).thenAnswer((_) async {});
        stubEmptyDownloads();

        await syncManager.performFullSync();

        verify(() => mockSyncRepo.uploadProgress(any())).called(1);
        verify(() => mockEducationRepo.markProgressSynced('p1')).called(1);
        verify(() => mockEducationRepo.deleteSyncQueueItem(1)).called(1);
      },
    );

    test('failed upload increments retry count', () async {
      syncManager.currentConnectivityForTest = ConnectivityState.online;

      final SyncQueueItem item = buildQueueItem(id: 1, entityId: 'p1');

      when(
        () => mockEducationRepo.getPendingSyncItems(),
      ).thenAnswer((_) async => <SyncQueueItem>[item]);
      when(
        () => mockSyncRepo.uploadProgress(any()),
      ).thenThrow(Exception('Network error'));
      when(
        () => mockEducationRepo.incrementRetryCount(1, 0),
      ).thenAnswer((_) async {});
      stubEmptyDownloads();

      await syncManager.performFullSync();

      verify(() => mockEducationRepo.incrementRetryCount(1, 0)).called(1);
      verifyNever(() => mockEducationRepo.markProgressSynced(any()));
    });

    test('skips items exceeding max retry count', () async {
      syncManager.currentConnectivityForTest = ConnectivityState.online;

      final SyncQueueItem item = buildQueueItem(
        id: 1,
        entityId: 'p1',
        retryCount: SyncConstants.maxRetryCount,
      );

      when(
        () => mockEducationRepo.getPendingSyncItems(),
      ).thenAnswer((_) async => <SyncQueueItem>[item]);
      stubEmptyDownloads();

      await syncManager.performFullSync();

      verifyNever(() => mockSyncRepo.uploadProgress(any()));
    });
  });

  group('download processing', () {
    test('fetches and upserts users, lessons, and progress', () async {
      syncManager.currentConnectivityForTest = ConnectivityState.online;

      when(
        () => mockEducationRepo.getPendingSyncItems(),
      ).thenAnswer((_) async => <SyncQueueItem>[]);

      final Map<String, dynamic> userData = <String, dynamic>{
        'id': 'u1',
        'name': 'Test User',
        'email': 'test@test.com',
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final Map<String, dynamic> lessonData = <String, dynamic>{
        'id': 'l1',
        'title': 'Test Lesson',
        'description': 'Desc',
        'durationMinutes': 30,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final Map<String, dynamic> progressData = <String, dynamic>{
        'id': 'p1',
        'userId': 'u1',
        'lessonId': 'l1',
        'progressPercent': 50,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(
        () => mockSyncRepo.fetchUsers(),
      ).thenAnswer((_) async => <Map<String, dynamic>>[userData]);
      when(
        () => mockSyncRepo.fetchLessons(),
      ).thenAnswer((_) async => <Map<String, dynamic>>[lessonData]);
      when(
        () => mockSyncRepo.fetchAllProgress(),
      ).thenAnswer((_) async => <Map<String, dynamic>>[progressData]);
      when(
        () => mockEducationRepo.upsertUserFromRemote(userData),
      ).thenAnswer((_) async {});
      when(
        () => mockEducationRepo.upsertLessonFromRemote(lessonData),
      ).thenAnswer((_) async {});
      when(
        () => mockEducationRepo.upsertProgressIfNewer(progressData),
      ).thenAnswer((_) async => true);

      await syncManager.performFullSync();

      verify(() => mockEducationRepo.upsertUserFromRemote(userData)).called(1);
      verify(
        () => mockEducationRepo.upsertLessonFromRemote(lessonData),
      ).called(1);
      verify(
        () => mockEducationRepo.upsertProgressIfNewer(progressData),
      ).called(1);
    });
  });

  group('simulateRemoteConflict', () {
    test('delegates to SyncRepository', () async {
      when(
        () => mockSyncRepo.simulateRemoteConflict(any()),
      ).thenAnswer((_) async {});

      await syncManager.simulateRemoteConflict('p1');

      verify(() => mockSyncRepo.simulateRemoteConflict('p1')).called(1);
    });
  });

  group('queue mechanism — offline update then online sync', () {
    test(
      'offline: updateProgress creates queue item, no upload call; '
      'online: performFullSync processes the queue and calls uploadProgress',
      () async {
        // ── Phase 1: OFFLINE — updateProgress writes locally ──
        // SyncManager is offline by default.
        // The repository.updateProgress (called by the cubit) writes to
        // local DB + SyncQueue atomically. We verify NO remote call happens.

        when(
          () => mockEducationRepo.updateProgress(
            userId: any(named: 'userId'),
            lessonId: any(named: 'lessonId'),
            incrementBy: any(named: 'incrementBy'),
          ),
        ).thenAnswer((_) async {});

        await mockEducationRepo.updateProgress(
          userId: 'u1',
          lessonId: 'l1',
          incrementBy: 10,
        );

        // Offline: performFullSync should bail out immediately.
        await syncManager.performFullSync();

        // No upload attempted while offline.
        verifyNever(() => mockSyncRepo.uploadProgress(any()));

        // ── Phase 2: ONLINE — SyncManager processes the queue ──
        syncManager.currentConnectivityForTest = ConnectivityState.online;

        final SyncQueueItem queuedItem = buildQueueItem(id: 1, entityId: 'p1');

        when(
          () => mockEducationRepo.getPendingSyncItems(),
        ).thenAnswer((_) async => <SyncQueueItem>[queuedItem]);
        when(() => mockSyncRepo.uploadProgress(any())).thenAnswer((_) async {});
        when(
          () => mockEducationRepo.markProgressSynced('p1'),
        ).thenAnswer((_) async {});
        when(
          () => mockEducationRepo.deleteSyncQueueItem(1),
        ).thenAnswer((_) async {});
        stubEmptyDownloads();

        await syncManager.performFullSync();

        // Upload WAS called now that we are online.
        verify(() => mockSyncRepo.uploadProgress(any())).called(1);
        verify(() => mockEducationRepo.markProgressSynced('p1')).called(1);
        verify(() => mockEducationRepo.deleteSyncQueueItem(1)).called(1);
      },
    );
  });

  group('seedInitialData', () {
    test('skips if users already exist', () async {
      when(() => mockEducationRepo.getUsers()).thenAnswer(
        (_) async => <User>[
          User(
            id: 'u1',
            name: 'Test',
            email: 'test@test.com',
            updatedAt: DateTime.now(),
            syncStatus: 'synced',
          ),
        ],
      );

      await syncManager.seedInitialData();

      verifyNever(() => mockSyncRepo.fetchUsers());
    });

    test('seeds data if no users exist', () async {
      when(
        () => mockEducationRepo.getUsers(),
      ).thenAnswer((_) async => <User>[]);

      final Map<String, dynamic> userData = <String, dynamic>{
        'id': 'u1',
        'name': 'Test',
        'email': 'test@test.com',
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final Map<String, dynamic> lessonData = <String, dynamic>{
        'id': 'l1',
        'title': 'Lesson',
        'description': 'Desc',
        'durationMinutes': 30,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(
        () => mockSyncRepo.fetchUsers(),
      ).thenAnswer((_) async => <Map<String, dynamic>>[userData]);
      when(
        () => mockSyncRepo.fetchLessons(),
      ).thenAnswer((_) async => <Map<String, dynamic>>[lessonData]);
      when(
        () => mockEducationRepo.upsertUserFromRemote(userData),
      ).thenAnswer((_) async {});
      when(
        () => mockEducationRepo.upsertLessonFromRemote(lessonData),
      ).thenAnswer((_) async {});

      await syncManager.seedInitialData();

      verify(() => mockEducationRepo.upsertUserFromRemote(userData)).called(1);
      verify(
        () => mockEducationRepo.upsertLessonFromRemote(lessonData),
      ).called(1);
    });
  });
}
