import 'package:injectable/injectable.dart';

import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/remote/firebase_remote_data_source.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/remote/remote_data_source.dart';

/// Repository that encapsulates all remote data source interactions.
/// Progress operations route to Firebase; Users/Lessons stay on mock.
@LazySingleton()
class SyncRepository {
  SyncRepository(this._mockDataSource, this._firebaseDataSource);

  final RemoteDataSource _mockDataSource;
  final FirebaseRemoteDataSource _firebaseDataSource;

  // ── Upload (Firebase) ──

  Future<void> uploadProgress(Map<String, dynamic> payload) async {
    await _firebaseDataSource.uploadProgress(payload);
  }

  // ── Download ──

  /// Users and Lessons remain from the mock data source (static seed data).
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    return _mockDataSource.fetchUsers();
  }

  Future<List<Map<String, dynamic>>> fetchLessons() async {
    return _mockDataSource.fetchLessons();
  }

  /// Progress is fetched from Firebase Firestore.
  Future<List<Map<String, dynamic>>> fetchAllProgress() async {
    return _firebaseDataSource.fetchAllProgress();
  }

  // ── Conflict Demo (Firebase) ──

  /// Directly writes a newer timestamp into Firestore to simulate a
  /// remote conflict from another device.
  Future<void> simulateRemoteConflict(String progressId) async {
    await _firebaseDataSource.simulateRemoteConflict(progressId);
    log.i(
      'SyncRepository: Remote conflict simulated for progressId=$progressId',
      tag: LogTags.sync,
    );
  }
}
