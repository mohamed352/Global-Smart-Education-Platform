import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';
import 'package:global_smart_education_platform/features/education/data/services/sync_manager.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/dashboard_cubit.dart';

class MockEducationRepository extends Mock implements EducationRepository {}

class MockSyncManager extends Mock implements SyncManager {}

void main() {
  late MockEducationRepository mockRepo;
  late MockSyncManager mockSyncManager;
  late StreamController<List<User>> usersController;
  late StreamController<List<Lesson>> lessonsController;
  late StreamController<List<Progress>> progressesController;
  late StreamController<List<SyncQueueItem>> syncQueueController;
  late StreamController<ConnectivityState> connectivityController;
  late StreamController<SyncEngineStatus> syncStatusController;

  setUp(() {
    mockRepo = MockEducationRepository();
    mockSyncManager = MockSyncManager();

    usersController = StreamController<List<User>>.broadcast();
    lessonsController = StreamController<List<Lesson>>.broadcast();
    progressesController = StreamController<List<Progress>>.broadcast();
    syncQueueController = StreamController<List<SyncQueueItem>>.broadcast();
    connectivityController = StreamController<ConnectivityState>.broadcast();
    syncStatusController = StreamController<SyncEngineStatus>.broadcast();

    when(() => mockRepo.watchUsers()).thenAnswer((_) => usersController.stream);
    when(
      () => mockRepo.watchLessons(),
    ).thenAnswer((_) => lessonsController.stream);
    when(
      () => mockRepo.watchProgresses(),
    ).thenAnswer((_) => progressesController.stream);
    when(
      () => mockRepo.watchSyncQueue(),
    ).thenAnswer((_) => syncQueueController.stream);
    when(
      () => mockSyncManager.connectivityStream,
    ).thenAnswer((_) => connectivityController.stream);
    when(
      () => mockSyncManager.statusStream,
    ).thenAnswer((_) => syncStatusController.stream);
  });

  tearDown(() {
    usersController.close();
    lessonsController.close();
    progressesController.close();
    syncQueueController.close();
    connectivityController.close();
    syncStatusController.close();
  });

  DashboardCubit createCubit() {
    return DashboardCubit(mockRepo, mockSyncManager);
  }

  group('initial state', () {
    test('has empty lists and default values', () {
      final DashboardCubit cubit = createCubit();

      expect(cubit.state.users, isEmpty);
      expect(cubit.state.lessons, isEmpty);
      expect(cubit.state.progresses, isEmpty);
      expect(cubit.state.pendingSyncCount, 0);
      expect(cubit.state.connectivity, ConnectivityState.offline);
      expect(cubit.state.syncStatus, SyncEngineStatus.idle);
      expect(cubit.state.errorMessage, isNull);

      cubit.close();
    });
  });

  group('stream subscriptions', () {
    test('emits updated users when users stream fires', () async {
      final DashboardCubit cubit = createCubit();

      final List<User> testUsers = <User>[
        User(
          id: 'u1',
          name: 'Test User',
          email: 'test@test.com',
          updatedAt: DateTime.now(),
          syncStatus: 'synced',
        ),
      ];

      usersController.add(testUsers);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.users, testUsers);

      await cubit.close();
    });

    test('emits updated lessons when lessons stream fires', () async {
      final DashboardCubit cubit = createCubit();

      final List<Lesson> testLessons = <Lesson>[
        Lesson(
          id: 'l1',
          title: 'Algebra',
          description: 'Desc',
          durationMinutes: 45,
          updatedAt: DateTime.now(),
          syncStatus: 'synced',
        ),
      ];

      lessonsController.add(testLessons);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.lessons, testLessons);

      await cubit.close();
    });

    test(
      'emits updated pendingSyncCount when syncQueue stream fires',
      () async {
        final DashboardCubit cubit = createCubit();

        syncQueueController.add(<SyncQueueItem>[
          SyncQueueItem(
            id: 1,
            operationType: 'updateProgress',
            entityId: 'p1',
            payload: '{}',
            retryCount: 0,
            createdAt: DateTime.now(),
          ),
          SyncQueueItem(
            id: 2,
            operationType: 'updateProgress',
            entityId: 'p2',
            payload: '{}',
            retryCount: 0,
            createdAt: DateTime.now(),
          ),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.pendingSyncCount, 2);

        await cubit.close();
      },
    );

    test('emits connectivity state changes', () async {
      final DashboardCubit cubit = createCubit();

      connectivityController.add(ConnectivityState.online);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.connectivity, ConnectivityState.online);

      await cubit.close();
    });

    test('emits sync engine status changes', () async {
      final DashboardCubit cubit = createCubit();

      syncStatusController.add(SyncEngineStatus.syncing);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.syncStatus, SyncEngineStatus.syncing);

      await cubit.close();
    });
  });

  group('updateProgress', () {
    test('delegates to repository', () async {
      final DashboardCubit cubit = createCubit();

      when(
        () => mockRepo.updateProgress(
          userId: 'u1',
          lessonId: 'l1',
          incrementBy: 10,
        ),
      ).thenAnswer((_) async {});

      await cubit.updateProgress(userId: 'u1', lessonId: 'l1');

      verify(
        () => mockRepo.updateProgress(
          userId: 'u1',
          lessonId: 'l1',
          incrementBy: 10,
        ),
      ).called(1);

      await cubit.close();
    });

    test('emits errorMessage on failure', () async {
      final DashboardCubit cubit = createCubit();

      when(
        () => mockRepo.updateProgress(
          userId: 'u1',
          lessonId: 'l1',
          incrementBy: 10,
        ),
      ).thenThrow(Exception('DB error'));

      await cubit.updateProgress(userId: 'u1', lessonId: 'l1');

      expect(cubit.state.errorMessage, 'Failed to update progress');

      await cubit.close();
    });

    test('clears errorMessage before attempting update', () async {
      final DashboardCubit cubit = createCubit();

      // First call fails — sets errorMessage
      when(
        () => mockRepo.updateProgress(
          userId: 'u1',
          lessonId: 'l1',
          incrementBy: 10,
        ),
      ).thenThrow(Exception('DB error'));

      await cubit.updateProgress(userId: 'u1', lessonId: 'l1');
      expect(cubit.state.errorMessage, isNotNull);

      // Second call succeeds — errorMessage should be cleared
      when(
        () => mockRepo.updateProgress(
          userId: 'u1',
          lessonId: 'l1',
          incrementBy: 10,
        ),
      ).thenAnswer((_) async {});

      await cubit.updateProgress(userId: 'u1', lessonId: 'l1');
      expect(cubit.state.errorMessage, isNull);

      await cubit.close();
    });
  });

  group('triggerSync', () {
    test('delegates to SyncManager.performFullSync', () async {
      final DashboardCubit cubit = createCubit();

      when(() => mockSyncManager.performFullSync()).thenAnswer((_) async {});

      await cubit.triggerSync();

      verify(() => mockSyncManager.performFullSync()).called(1);

      await cubit.close();
    });
  });

  group('helper methods', () {
    test('getProgressPercent returns 0 when no match', () {
      final DashboardCubit cubit = createCubit();

      expect(cubit.getProgressPercent('u1', 'l1'), 0);

      cubit.close();
    });

    test('getProgressSyncStatus returns none when no match', () {
      final DashboardCubit cubit = createCubit();

      expect(cubit.getProgressSyncStatus('u1', 'l1'), 'none');

      cubit.close();
    });
  });
}
