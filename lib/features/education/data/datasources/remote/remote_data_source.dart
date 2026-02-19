import 'dart:math';

import 'package:injectable/injectable.dart';

import 'package:global_smart_education_platform/core/constants/sync_constants.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';

/// Mocked remote data source simulating network calls with Future.delayed.
/// Simulates random failures to test retry logic.
@LazySingleton()
class RemoteDataSource {
  final Random _random = Random();

  // ── Simulated Remote State ──
  // This map simulates the server-side progress records.
  // Key: "{userId}_{lessonId}", Value: progress JSON.
  final Map<String, Map<String, dynamic>> _remoteProgressStore = {};

  bool get _shouldFail =>
      _random.nextInt(100) < SyncConstants.failureProbabilityPercent;

  Future<void> _simulateDelay() => Future<void>.delayed(
    const Duration(milliseconds: SyncConstants.networkDelayMs),
  );

  // ── Upload Progress ──

  Future<bool> uploadProgress(Map<String, dynamic> payload) async {
    await _simulateDelay();
    if (_shouldFail) {
      log.w('Mock API: Upload failed (simulated)', tag: LogTags.network);
      throw Exception('Simulated network failure on upload');
    }
    final String key = '${payload['userId']}_${payload['lessonId']}';
    _remoteProgressStore[key] = Map<String, dynamic>.from(payload);
    log.i('Mock API: Uploaded progress for $key', tag: LogTags.network);
    return true;
  }

  // ── Download All Progress ──

  Future<List<Map<String, dynamic>>> fetchAllProgress() async {
    await _simulateDelay();
    if (_shouldFail) {
      log.w('Mock API: Download failed (simulated)', tag: LogTags.network);
      throw Exception('Simulated network failure on download');
    }
    log.i(
      'Mock API: Fetched ${_remoteProgressStore.length} progress records',
      tag: LogTags.network,
    );
    return _remoteProgressStore.values.toList();
  }

  // ── Seed Remote Data (for conflict demo) ──

  /// Seeds a newer progress entry on the "server" to demonstrate LWW conflict.
  void seedConflictData({
    required String progressId,
    required String userId,
    required String lessonId,
    required int progressPercent,
    required DateTime updatedAt,
  }) {
    final String key = '${userId}_$lessonId';
    _remoteProgressStore[key] = <String, dynamic>{
      'id': progressId,
      'userId': userId,
      'lessonId': lessonId,
      'progressPercent': progressPercent,
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': 'synced',
    };
    log.i(
      'Mock API: Seeded conflict data for $key '
      '(progress=$progressPercent%, updatedAt=$updatedAt)',
      tag: LogTags.network,
    );
  }

  // ── Fetch Users & Lessons (static mock) ──

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    await _simulateDelay();
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'user_001',
        'name': 'Ahmed Al-Farsi',
        'email': 'ahmed@edu.com',
        'updatedAt': DateTime.now().toIso8601String(),
        'syncStatus': 'synced',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> fetchLessons() async {
    await _simulateDelay();
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'lesson_001',
        'title': 'Introduction to Algebra',
        'description': 'Basic algebraic expressions and equations.',
        'durationMinutes': 45,
        'updatedAt': DateTime.now().toIso8601String(),
        'syncStatus': 'synced',
      },
      <String, dynamic>{
        'id': 'lesson_002',
        'title': 'World History: Ancient Egypt',
        'description': 'Exploring the civilization of Ancient Egypt.',
        'durationMinutes': 60,
        'updatedAt': DateTime.now().toIso8601String(),
        'syncStatus': 'synced',
      },
      <String, dynamic>{
        'id': 'lesson_003',
        'title': 'Physics: Newton\'s Laws',
        'description': 'Understanding motion and forces.',
        'durationMinutes': 50,
        'updatedAt': DateTime.now().toIso8601String(),
        'syncStatus': 'synced',
      },
    ];
  }
}
