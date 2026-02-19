import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:global_smart_education_platform/core/constants/sync_constants.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';

/// Dedicated integration tests for Last-Write-Wins conflict resolution.
/// Uses a real in-memory Drift database — no mocks.
void main() {
  late AppDatabase db;
  late EducationRepository repository;

  final DateTime t1 = DateTime(2025, 6, 1, 12);
  final DateTime t2 = DateTime(2025, 6, 1, 13);
  final DateTime t3 = DateTime(2025, 6, 1, 14);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = EducationRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedLocalProgress({
    required String id,
    required String userId,
    required String lessonId,
    required int percent,
    required DateTime updatedAt,
    String syncStatus = 'synced',
  }) async {
    await db.upsertProgress(
      ProgressesCompanion(
        id: Value<String>(id),
        userId: Value<String>(userId),
        lessonId: Value<String>(lessonId),
        progressPercent: Value<int>(percent),
        updatedAt: Value<DateTime>(updatedAt),
        syncStatus: Value<String>(syncStatus),
      ),
    );
  }

  Map<String, dynamic> buildRemotePayload({
    required String id,
    required String userId,
    required String lessonId,
    required int percent,
    required DateTime updatedAt,
  }) {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'lessonId': lessonId,
      'progressPercent': percent,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  group('LWW Conflict Resolution — core scenarios', () {
    test('Scenario 1: Remote newer than local → remote wins', () async {
      await seedLocalProgress(
        id: 'p1',
        userId: 'u1',
        lessonId: 'l1',
        percent: 30,
        updatedAt: t1,
      );

      final bool result = await repository.upsertProgressIfNewer(
        buildRemotePayload(
          id: 'p1',
          userId: 'u1',
          lessonId: 'l1',
          percent: 80,
          updatedAt: t2,
        ),
      );

      expect(result, isTrue, reason: 'Remote is newer, should win');
      final Progress? progress =
          await db.getProgressByUserAndLesson('u1', 'l1');
      expect(progress!.progressPercent, 80);
      expect(progress.syncStatus, SyncStatus.synced.name);
    });

    test('Scenario 2: Local newer than remote → local wins', () async {
      await seedLocalProgress(
        id: 'p1',
        userId: 'u1',
        lessonId: 'l1',
        percent: 60,
        updatedAt: t2,
        syncStatus: SyncStatus.pending.name,
      );

      final bool result = await repository.upsertProgressIfNewer(
        buildRemotePayload(
          id: 'p1',
          userId: 'u1',
          lessonId: 'l1',
          percent: 40,
          updatedAt: t1,
        ),
      );

      expect(result, isFalse, reason: 'Local is newer, should win');
      final Progress? progress =
          await db.getProgressByUserAndLesson('u1', 'l1');
      expect(progress!.progressPercent, 60);
      expect(progress.syncStatus, SyncStatus.pending.name);
    });

    test('Scenario 3: Equal timestamps → local wins (tie-break)', () async {
      await seedLocalProgress(
        id: 'p1',
        userId: 'u1',
        lessonId: 'l1',
        percent: 45,
        updatedAt: t1,
      );

      final bool result = await repository.upsertProgressIfNewer(
        buildRemotePayload(
          id: 'p1',
          userId: 'u1',
          lessonId: 'l1',
          percent: 90,
          updatedAt: t1,
        ),
      );

      expect(result, isFalse, reason: 'Equal time = local wins');
      final Progress? progress =
          await db.getProgressByUserAndLesson('u1', 'l1');
      expect(progress!.progressPercent, 45);
    });

    test('Scenario 4: No local record → remote inserted directly', () async {
      final bool result = await repository.upsertProgressIfNewer(
        buildRemotePayload(
          id: 'p1',
          userId: 'u1',
          lessonId: 'l1',
          percent: 70,
          updatedAt: t1,
        ),
      );

      expect(result, isTrue, reason: 'No local record, remote should insert');
      final Progress? progress =
          await db.getProgressByUserAndLesson('u1', 'l1');
      expect(progress, isNotNull);
      expect(progress!.progressPercent, 70);
    });
  });

  group('LWW — offline mutation scenarios', () {
    test('rapid-fire offline increments produce correct queue entries',
        () async {
      await repository.updateProgress(
        userId: 'u1',
        lessonId: 'l1',
        incrementBy: 10,
      );
      await repository.updateProgress(
        userId: 'u1',
        lessonId: 'l1',
        incrementBy: 15,
      );
      await repository.updateProgress(
        userId: 'u1',
        lessonId: 'l1',
        incrementBy: 20,
      );

      // Progress should be 10 + 15 + 20 = 45%
      final Progress? progress =
          await db.getProgressByUserAndLesson('u1', 'l1');
      expect(progress!.progressPercent, 45);

      // Queue should have 3 entries (1 create + 2 updates)
      final List<SyncQueueItem> queue = await db.getPendingSyncItems();
      expect(queue.length, 3);
      expect(queue.first.operationType, OperationType.createProgress.name);
      expect(queue[1].operationType, OperationType.updateProgress.name);
      expect(queue[2].operationType, OperationType.updateProgress.name);
    });

    test('offline mutation followed by newer remote sync → remote wins',
        () async {
      // User makes local change at t1
      await seedLocalProgress(
        id: 'p1',
        userId: 'u1',
        lessonId: 'l1',
        percent: 20,
        updatedAt: t1,
        syncStatus: SyncStatus.pending.name,
      );

      // Meanwhile, server has newer data at t3
      final bool result = await repository.upsertProgressIfNewer(
        buildRemotePayload(
          id: 'p1',
          userId: 'u1',
          lessonId: 'l1',
          percent: 95,
          updatedAt: t3,
        ),
      );

      expect(result, isTrue);
      final Progress? progress =
          await db.getProgressByUserAndLesson('u1', 'l1');
      expect(progress!.progressPercent, 95);
      expect(progress.syncStatus, SyncStatus.synced.name);
    });

    test('offline mutation followed by older remote sync → local wins',
        () async {
      // User makes local change at t3 (latest)
      await seedLocalProgress(
        id: 'p1',
        userId: 'u1',
        lessonId: 'l1',
        percent: 50,
        updatedAt: t3,
        syncStatus: SyncStatus.pending.name,
      );

      // Server has stale data at t1
      final bool result = await repository.upsertProgressIfNewer(
        buildRemotePayload(
          id: 'p1',
          userId: 'u1',
          lessonId: 'l1',
          percent: 10,
          updatedAt: t1,
        ),
      );

      expect(result, isFalse);
      final Progress? progress =
          await db.getProgressByUserAndLesson('u1', 'l1');
      expect(progress!.progressPercent, 50);
      expect(progress.syncStatus, SyncStatus.pending.name);
    });
  });

  group('LWW — multi-lesson isolation', () {
    test('conflict resolution is scoped per user+lesson', () async {
      // Lesson 1: local at t1 with 30%
      await seedLocalProgress(
        id: 'p1',
        userId: 'u1',
        lessonId: 'l1',
        percent: 30,
        updatedAt: t1,
      );

      // Lesson 2: local at t3 with 80%
      await seedLocalProgress(
        id: 'p2',
        userId: 'u1',
        lessonId: 'l2',
        percent: 80,
        updatedAt: t3,
      );

      // Remote for lesson 1 at t2 (newer) → should win
      final bool r1 = await repository.upsertProgressIfNewer(
        buildRemotePayload(
          id: 'p1',
          userId: 'u1',
          lessonId: 'l1',
          percent: 60,
          updatedAt: t2,
        ),
      );

      // Remote for lesson 2 at t1 (older) → should lose
      final bool r2 = await repository.upsertProgressIfNewer(
        buildRemotePayload(
          id: 'p2',
          userId: 'u1',
          lessonId: 'l2',
          percent: 20,
          updatedAt: t1,
        ),
      );

      expect(r1, isTrue, reason: 'Lesson 1: remote t2 > local t1');
      expect(r2, isFalse, reason: 'Lesson 2: remote t1 < local t3');

      final Progress? p1 =
          await db.getProgressByUserAndLesson('u1', 'l1');
      final Progress? p2 =
          await db.getProgressByUserAndLesson('u1', 'l2');

      expect(p1!.progressPercent, 60);
      expect(p2!.progressPercent, 80);
    });
  });
}
