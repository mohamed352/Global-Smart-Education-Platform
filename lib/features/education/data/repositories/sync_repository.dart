import 'package:injectable/injectable.dart';

import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/remote/remote_data_source.dart';

/// Repository that encapsulates all remote data source interactions.
/// SyncManager and Cubit should never access RemoteDataSource directly.
@LazySingleton()
class SyncRepository {
  SyncRepository(this._remoteDataSource);

  final RemoteDataSource _remoteDataSource;

  // ── Upload ──

  Future<bool> uploadProgress(Map<String, dynamic> payload) async {
    return _remoteDataSource.uploadProgress(payload);
  }

  // ── Download ──

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    return _remoteDataSource.fetchUsers();
  }

  Future<List<Map<String, dynamic>>> fetchLessons() async {
    return _remoteDataSource.fetchLessons();
  }

  Future<List<Map<String, dynamic>>> fetchAllProgress() async {
    return _remoteDataSource.fetchAllProgress();
  }

  // ── Conflict Demo ──

  /// Seeds a newer progress entry on the mock server for LWW demo.
  void seedConflictData({
    required String progressId,
    required String userId,
    required String lessonId,
    required int progressPercent,
    required DateTime updatedAt,
  }) {
    _remoteDataSource.seedConflictData(
      progressId: progressId,
      userId: userId,
      lessonId: lessonId,
      progressPercent: progressPercent,
      updatedAt: updatedAt,
    );
    log.i(
      'SyncRepository: Seeded conflict data '
      '(user=$userId, lesson=$lessonId, progress=$progressPercent%)',
      tag: LogTags.sync,
    );
  }
}
