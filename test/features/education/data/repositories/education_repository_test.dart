import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:global_smart_education_platform/core/constants/sync_constants.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';

AppDatabase _createInMemoryDb() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late EducationRepository repository;

  setUp(() {
    db = _createInMemoryDb();
    repository = EducationRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('updateProgress', () {
    test(
      'creates new progress with correct values and pending status',
      () async {
        await repository.updateProgress(
          userId: 'u1',
          lessonId: 'l1',
          incrementBy: 10,
        );

        final List<Progress> progresses = await db.getAllProgresses();
        expect(progresses.length, 1);
        expect(progresses.first.userId, 'u1');
        expect(progresses.first.lessonId, 'l1');
        expect(progresses.first.progressPercent, 10);
        expect(progresses.first.syncStatus, SyncStatus.pending.name);
      },
    );

    test('increments existing progress correctly', () async {
      await repository.updateProgress(
        userId: 'u1',
        lessonId: 'l1',
        incrementBy: 30,
      );
      await repository.updateProgress(
        userId: 'u1',
        lessonId: 'l1',
        incrementBy: 25,
      );

      final List<Progress> progresses = await db.getAllProgresses();
      expect(progresses.length, 1);
      expect(progresses.first.progressPercent, 55);
    });

    test('clamps progress at 100', () async {
      await repository.updateProgress(
        userId: 'u1',
        lessonId: 'l1',
        incrementBy: 80,
      );
      await repository.updateProgress(
        userId: 'u1',
        lessonId: 'l1',
        incrementBy: 50,
      );

      final List<Progress> progresses = await db.getAllProgresses();
      expect(progresses.first.progressPercent, 100);
    });

    test('adds entry to SyncQueue atomically with progress', () async {
      await repository.updateProgress(
        userId: 'u1',
        lessonId: 'l1',
        incrementBy: 10,
      );

      final List<SyncQueueItem> queue = await db.getPendingSyncItems();
      expect(queue.length, 1);
      expect(queue.first.operationType, OperationType.createProgress.name);
    });

    test('second update produces updateProgress operation type', () async {
      await repository.updateProgress(
        userId: 'u1',
        lessonId: 'l1',
        incrementBy: 10,
      );
      await repository.updateProgress(
        userId: 'u1',
        lessonId: 'l1',
        incrementBy: 10,
      );

      final List<SyncQueueItem> queue = await db.getPendingSyncItems();
      expect(queue.length, 2);
      expect(queue.last.operationType, OperationType.updateProgress.name);
    });
  });

  group('markProgressSynced', () {
    test('updates syncStatus to synced for existing progress', () async {
      await repository.updateProgress(
        userId: 'u1',
        lessonId: 'l1',
        incrementBy: 10,
      );

      final List<Progress> before = await db.getAllProgresses();
      expect(before.first.syncStatus, SyncStatus.pending.name);

      await repository.markProgressSynced(before.first.id);

      final List<Progress> after = await db.getAllProgresses();
      expect(after.first.syncStatus, SyncStatus.synced.name);
    });

    test('does not throw for non-existent progress id', () async {
      await expectLater(
        repository.markProgressSynced('non_existent'),
        completes,
      );
    });
  });

  group('upsertProgressIfNewer (LWW)', () {
    final DateTime baseTime = DateTime(2025, 6, 1, 12);

    test('inserts remote progress when no local record exists', () async {
      final bool result = await repository.upsertProgressIfNewer({
        'id': 'p1',
        'userId': 'u1',
        'lessonId': 'l1',
        'progressPercent': 50,
        'updatedAt': baseTime.toIso8601String(),
      });

      expect(result, isTrue);
      final Progress? progress = await db.getProgressByUserAndLesson(
        'u1',
        'l1',
      );
      expect(progress, isNotNull);
      expect(progress!.progressPercent, 50);
    });

    test('remote wins when remote updatedAt is newer', () async {
      // Seed local at baseTime with 30%
      await db.upsertProgress(
        ProgressesCompanion(
          id: const Value<String>('p1'),
          userId: const Value<String>('u1'),
          lessonId: const Value<String>('l1'),
          progressPercent: const Value<int>(30),
          updatedAt: Value<DateTime>(baseTime),
          syncStatus: Value<String>(SyncStatus.synced.name),
        ),
      );

      // Remote at baseTime + 1 hour with 80%
      final bool result = await repository.upsertProgressIfNewer({
        'id': 'p1',
        'userId': 'u1',
        'lessonId': 'l1',
        'progressPercent': 80,
        'updatedAt': baseTime.add(const Duration(hours: 1)).toIso8601String(),
      });

      expect(result, isTrue);
      final Progress? progress = await db.getProgressByUserAndLesson(
        'u1',
        'l1',
      );
      expect(progress!.progressPercent, 80);
    });

    test('local wins when local updatedAt is newer', () async {
      final DateTime laterTime = baseTime.add(const Duration(hours: 2));

      // Seed local at laterTime with 60%
      await db.upsertProgress(
        ProgressesCompanion(
          id: const Value<String>('p1'),
          userId: const Value<String>('u1'),
          lessonId: const Value<String>('l1'),
          progressPercent: const Value<int>(60),
          updatedAt: Value<DateTime>(laterTime),
          syncStatus: Value<String>(SyncStatus.pending.name),
        ),
      );

      // Remote at baseTime (older) with 40%
      final bool result = await repository.upsertProgressIfNewer({
        'id': 'p1',
        'userId': 'u1',
        'lessonId': 'l1',
        'progressPercent': 40,
        'updatedAt': baseTime.toIso8601String(),
      });

      expect(result, isFalse);
      final Progress? progress = await db.getProgressByUserAndLesson(
        'u1',
        'l1',
      );
      expect(progress!.progressPercent, 60);
    });

    test('local wins on equal timestamps (tie-break)', () async {
      // Seed local at baseTime with 45%
      await db.upsertProgress(
        ProgressesCompanion(
          id: const Value<String>('p1'),
          userId: const Value<String>('u1'),
          lessonId: const Value<String>('l1'),
          progressPercent: const Value<int>(45),
          updatedAt: Value<DateTime>(baseTime),
          syncStatus: Value<String>(SyncStatus.synced.name),
        ),
      );

      // Remote at same baseTime with 90%
      final bool result = await repository.upsertProgressIfNewer({
        'id': 'p1',
        'userId': 'u1',
        'lessonId': 'l1',
        'progressPercent': 90,
        'updatedAt': baseTime.toIso8601String(),
      });

      expect(result, isFalse);
      final Progress? progress = await db.getProgressByUserAndLesson(
        'u1',
        'l1',
      );
      expect(progress!.progressPercent, 45);
    });
  });

  group('incrementRetryCount', () {
    test('increments retry count by 1', () async {
      await repository.updateProgress(
        userId: 'u1',
        lessonId: 'l1',
        incrementBy: 10,
      );

      final List<SyncQueueItem> queue = await db.getPendingSyncItems();
      expect(queue.first.retryCount, 0);

      await repository.incrementRetryCount(queue.first.id, 0);

      final List<SyncQueueItem> updated = await db.getPendingSyncItems();
      expect(updated.first.retryCount, 1);
    });
  });

  group('deleteSyncQueueItem', () {
    test('removes item from queue', () async {
      await repository.updateProgress(
        userId: 'u1',
        lessonId: 'l1',
        incrementBy: 10,
      );

      final List<SyncQueueItem> queue = await db.getPendingSyncItems();
      expect(queue.length, 1);

      await repository.deleteSyncQueueItem(queue.first.id);

      final List<SyncQueueItem> after = await db.getPendingSyncItems();
      expect(after.length, 0);
    });
  });
}
