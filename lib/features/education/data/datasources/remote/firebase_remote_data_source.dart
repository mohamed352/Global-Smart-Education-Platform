import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import 'package:global_smart_education_platform/core/logger/app_logger.dart';

/// Production remote data source backed by Cloud Firestore.
/// Focused on the `Progress` entity as required by the client.
/// Collection: `progresses` — each document keyed by progressId.
@LazySingleton()
class FirebaseRemoteDataSource {
  FirebaseRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _progressesCollection = 'progresses';

  CollectionReference<Map<String, dynamic>> get _progressRef =>
      _firestore.collection(_progressesCollection);

  // ── Upload Progress ──

  /// Uploads or merges a progress document into Firestore.
  /// Uses `set` with `merge: true` so partial updates don't overwrite
  /// fields not present in the payload.
  Future<void> uploadProgress(Map<String, dynamic> payload) async {
    final String docId = payload['id'] as String;
    try {
      await _progressRef.doc(docId).set(payload, SetOptions(merge: true));
      log.i(
        'Firestore: Uploaded progress doc=$docId',
        tag: LogTags.network,
      );
    } on FirebaseException catch (e) {
      log.e(
        'Firestore: Upload failed for doc=$docId',
        tag: LogTags.network,
        error: e,
      );
      rethrow;
    }
  }

  // ── Fetch All Progress ──

  /// Fetches every document in the `progresses` collection for sync-down.
  Future<List<Map<String, dynamic>>> fetchAllProgress() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _progressRef.get();

      final List<Map<String, dynamic>> results = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.data())
          .toList();

      log.i(
        'Firestore: Fetched ${results.length} progress documents',
        tag: LogTags.network,
      );
      return results;
    } on FirebaseException catch (e) {
      log.e(
        'Firestore: fetchAllProgress failed',
        tag: LogTags.network,
        error: e,
      );
      rethrow;
    }
  }

  // ── Simulate Remote Conflict (Demo Helper) ──

  /// Directly writes to Firestore with a future timestamp and 100%,
  /// simulating another device pushing a newer change.
  Future<void> simulateRemoteConflict(String progressId) async {
    final DateTime futureTimestamp = DateTime.now().add(
      const Duration(hours: 1),
    );
    final Map<String, dynamic> conflictPayload = <String, dynamic>{
      'progressPercent': 100,
      'updatedAt': futureTimestamp.toIso8601String(),
    };

    try {
      await _progressRef.doc(progressId).set(
            conflictPayload,
            SetOptions(merge: true),
          );
      log.i(
        'Firestore: Seeded conflict on doc=$progressId '
        '(progress=100%, updatedAt=${futureTimestamp.toIso8601String()})',
        tag: LogTags.network,
      );
    } on FirebaseException catch (e) {
      log.e(
        'Firestore: simulateRemoteConflict failed for doc=$progressId',
        tag: LogTags.network,
        error: e,
      );
      rethrow;
    }
  }
}
