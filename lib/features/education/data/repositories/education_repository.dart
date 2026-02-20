import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import 'package:global_smart_education_platform/core/constants/sync_constants.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';

/// Repository: Single Source of Truth interface over the local DB.
/// All reads and writes go through the local database only.
@LazySingleton()
class EducationRepository {
  EducationRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  // ── Reactive Streams (SSOT) ──

  Stream<List<User>> watchUsers() => _db.watchAllUsers();

  Stream<List<Lesson>> watchLessons() => _db.watchAllLessons();

  Stream<List<Progress>> watchProgresses() => _db.watchAllProgresses();

  Stream<List<SyncQueueItem>> watchSyncQueue() => _db.watchPendingSyncItems();

  // ── Read Operations ──

  Future<List<User>> getUsers() => _db.getAllUsers();

  Future<List<Lesson>> getLessons() => _db.getAllLessons();

  Future<List<Progress>> getProgresses() => _db.getAllProgresses();

  Future<Progress?> getProgressByUserAndLesson(
    String userId,
    String lessonId,
  ) => _db.getProgressByUserAndLesson(userId, lessonId);

  Future<List<SyncQueueItem>> getPendingSyncItems() =>
      _db.getPendingSyncItems();

  // ── Helpers ──

  ProgressesCompanion _buildProgressCompanion({
    required String id,
    required String userId,
    required String lessonId,
    required int progressPercent,
    required DateTime updatedAt,
    required String syncStatus,
  }) {
    return ProgressesCompanion(
      id: Value<String>(id),
      userId: Value<String>(userId),
      lessonId: Value<String>(lessonId),
      progressPercent: Value<int>(progressPercent),
      updatedAt: Value<DateTime>(updatedAt),
      syncStatus: Value<String>(syncStatus),
    );
  }

  // ── Write: Update Progress (offline-first) ──

  Future<void> updateProgress({
    required String userId,
    required String lessonId,
    required int incrementBy,
  }) async {
    final DateTime now = DateTime.now();

    await _db.transaction(() async {
      final Progress? existing = await _db.getProgressByUserAndLesson(
        userId,
        lessonId,
      );

      final String progressId = existing?.id ?? _uuid.v4();
      final int newPercent = ((existing?.progressPercent ?? 0) + incrementBy)
          .clamp(0, 100);
      final OperationType opType = existing != null
          ? OperationType.updateProgress
          : OperationType.createProgress;

      // 1. Write to local DB
      await _db.upsertProgress(
        _buildProgressCompanion(
          id: progressId,
          userId: userId,
          lessonId: lessonId,
          progressPercent: newPercent,
          updatedAt: now,
          syncStatus: SyncStatus.pending.name,
        ),
      );

      // 2. Add to SyncQueue (atomic with step 1)
      final Map<String, dynamic> payload = <String, dynamic>{
        'id': progressId,
        'userId': userId,
        'lessonId': lessonId,
        'progressPercent': newPercent,
        'updatedAt': now.toIso8601String(),
      };
      await _db.addToSyncQueue(
        SyncQueueItemsCompanion(
          operationType: Value<String>(opType.name),
          entityId: Value<String>(progressId),
          payload: Value<String>(jsonEncode(payload)),
          retryCount: const Value<int>(0),
          createdAt: Value<DateTime>(now),
        ),
      );

      log.i(
        'Local DB: Progress updated atomically (lesson=$lessonId, '
        'progress=$newPercent%, status=pending, queue=${opType.name})',
        tag: LogTags.db,
      );
    });
  }

  // ── Sync Helpers ──

  Future<void> upsertUserFromRemote(Map<String, dynamic> data) async {
    await _db.upsertUser(
      UsersCompanion(
        id: Value<String>(data['id'] as String),
        name: Value<String>(data['name'] as String),
        email: Value<String>(data['email'] as String),
        updatedAt: Value<DateTime>(DateTime.parse(data['updatedAt'] as String)),
        syncStatus: Value<String>(SyncStatus.synced.name),
      ),
    );
  }

  Future<void> upsertLessonFromRemote(Map<String, dynamic> data) async {
    await _db.upsertLesson(
      LessonsCompanion(
        id: Value<String>(data['id'] as String),
        title: Value<String>(data['title'] as String),
        description: Value<String>(data['description'] as String),
        durationMinutes: Value<int>(data['durationMinutes'] as int),
        updatedAt: Value<DateTime>(DateTime.parse(data['updatedAt'] as String)),
        syncStatus: Value<String>(SyncStatus.synced.name),
      ),
    );
  }

  /// Upserts progress ONLY if remote is newer (Last-Write-Wins).
  /// Skips incomplete documents that are missing required fields.
  Future<bool> upsertProgressIfNewer(Map<String, dynamic> remoteData) async {
    final String? remoteId = remoteData['id'] as String?;
    final String? userId = remoteData['userId'] as String?;
    final String? lessonId = remoteData['lessonId'] as String?;
    final int? remotePercent = remoteData['progressPercent'] as int?;
    final String? updatedAtRaw = remoteData['updatedAt'] as String?;

    if (remoteId == null ||
        userId == null ||
        lessonId == null ||
        remotePercent == null ||
        updatedAtRaw == null) {
      log.w(
        'LWW: Skipping incomplete remote document (id=$remoteId)',
        tag: LogTags.sync,
      );
      return false;
    }

    final DateTime remoteUpdatedAt = DateTime.parse(updatedAtRaw);

    final Progress? local = await _db.getProgressByUserAndLesson(
      userId,
      lessonId,
    );

    if (local == null) {
      // No local record → insert remote
      await _db.upsertProgress(
        _buildProgressCompanion(
          id: remoteId,
          userId: userId,
          lessonId: lessonId,
          progressPercent: remotePercent,
          updatedAt: remoteUpdatedAt,
          syncStatus: SyncStatus.synced.name,
        ),
      );
      log.i(
        'LWW: No local record. Inserted remote progress '
        '(lesson=$lessonId, progress=$remotePercent%)',
        tag: LogTags.sync,
      );
      return true;
    }

    // ── Last-Write-Wins Conflict Resolution ──
    if (remoteUpdatedAt.isAfter(local.updatedAt)) {
      await _db.upsertProgress(
        _buildProgressCompanion(
          id: local.id,
          userId: userId,
          lessonId: lessonId,
          progressPercent: remotePercent,
          updatedAt: remoteUpdatedAt,
          syncStatus: SyncStatus.synced.name,
        ),
      );
      log.i(
        'LWW: Remote WINS (lesson=$lessonId). '
        'Remote=${remoteUpdatedAt.toIso8601String()} > '
        'Local=${local.updatedAt.toIso8601String()}. '
        'Progress overwritten to $remotePercent%',
        tag: LogTags.sync,
      );
      return true;
    } else {
      log.i(
        'LWW: Local WINS (lesson=$lessonId). '
        'Local=${local.updatedAt.toIso8601String()} >= '
        'Remote=${remoteUpdatedAt.toIso8601String()}. '
        'Keeping local progress at ${local.progressPercent}%',
        tag: LogTags.sync,
      );
      return false;
    }
  }

  Future<void> markProgressSynced(String progressId) async {
    final int rowsAffected = await _db.updateProgressSyncStatus(
      progressId,
      SyncStatus.synced.name,
    );
    if (rowsAffected == 0) {
      log.w(
        'markProgressSynced: No progress found with id=$progressId',
        tag: LogTags.db,
      );
    }
  }

  Future<void> deleteSyncQueueItem(int id) => _db.deleteSyncQueueItem(id);

  Future<void> incrementRetryCount(int id, int currentCount) =>
      _db.updateSyncQueueRetryCount(id, currentCount + 1);
}
