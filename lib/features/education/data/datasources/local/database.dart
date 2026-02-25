import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:global_smart_education_platform/core/constants/sync_constants.dart';

part 'database.g.dart';

// ─── Table Definitions ───

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Lessons extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get audioPath => text().withDefault(const Constant(''))();
  TextColumn get videoPath => text().withDefault(const Constant(''))();
  IntColumn get durationMinutes => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Progress')
class Progresses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get lessonId => text().references(Lessons, #id)();
  IntColumn get progressPercent => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text()();
  TextColumn get entityId => text()();
  TextColumn get payload => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Q&A history for AI teacher — stores all student questions and AI answers per lesson
class QaHistoryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get lessonId => text()();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  BoolColumn get isGreeting => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

// ─── Database ───

@DriftDatabase(
  tables: [Users, Lessons, Progresses, SyncQueueItems, QaHistoryItems],
)
@LazySingleton()
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(lessons, lessons.content);
        await m.addColumn(lessons, lessons.audioPath);
      }
      if (from < 3) {
        await m.addColumn(lessons, lessons.videoPath);
      }
      if (from < 4) {
        await m.createTable(qaHistoryItems);
      }
    },
  );

  // ── User Queries ──

  Future<List<User>> getAllUsers() => select(users).get();

  Stream<List<User>> watchAllUsers() => select(users).watch();

  Future<void> upsertUser(UsersCompanion user) =>
      into(users).insertOnConflictUpdate(user);

  // ── Lesson Queries ──

  Future<List<Lesson>> getAllLessons() => select(lessons).get();

  Stream<List<Lesson>> watchAllLessons() => select(lessons).watch();

  Future<Lesson?> getLessonById(String id) =>
      (select(lessons)..where((l) => l.id.equals(id))).getSingleOrNull();

  Future<void> upsertLesson(LessonsCompanion lesson) =>
      into(lessons).insertOnConflictUpdate(lesson);

  // ── Progress Queries ──

  Future<List<Progress>> getAllProgresses() => select(progresses).get();

  Stream<List<Progress>> watchAllProgresses() => select(progresses).watch();

  Future<Progress?> getProgressByUserAndLesson(
    String userId,
    String lessonId,
  ) =>
      (select(progresses)..where(
            (p) => p.userId.equals(userId) & p.lessonId.equals(lessonId),
          ))
          .getSingleOrNull();

  Future<void> upsertProgress(ProgressesCompanion progress) =>
      into(progresses).insertOnConflictUpdate(progress);

  // ── Sync Queue Queries ──

  Future<List<SyncQueueItem>> getPendingSyncItems() =>
      (select(syncQueueItems)..where(
            (s) => s.retryCount.isSmallerThanValue(SyncConstants.maxRetryCount),
          ))
          .get();

  Stream<List<SyncQueueItem>> watchPendingSyncItems() =>
      select(syncQueueItems).watch();

  Future<int> addToSyncQueue(SyncQueueItemsCompanion item) =>
      into(syncQueueItems).insert(item);

  Future<void> deleteSyncQueueItem(int id) =>
      (delete(syncQueueItems)..where((s) => s.id.equals(id))).go();

  Future<void> updateSyncQueueRetryCount(int id, int newRetryCount) =>
      (update(syncQueueItems)..where((s) => s.id.equals(id))).write(
        SyncQueueItemsCompanion(retryCount: Value(newRetryCount)),
      );

  Future<int> updateProgressSyncStatus(String progressId, String status) =>
      (update(progresses)..where((p) => p.id.equals(progressId))).write(
        ProgressesCompanion(syncStatus: Value(status)),
      );

  // ── Q&A History Queries ──

  Future<List<QaHistoryItem>> getQaHistoryForLesson(String lessonId) =>
      (select(qaHistoryItems)
            ..where((q) => q.lessonId.equals(lessonId))
            ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
          .get();

  Future<int> insertQaItem(QaHistoryItemsCompanion item) =>
      into(qaHistoryItems).insert(item);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dbFolder = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dbFolder.path, 'education_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
