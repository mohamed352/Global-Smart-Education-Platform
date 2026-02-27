import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';

import 'package:drift/drift.dart';
import 'package:global_smart_education_platform/core/constants/sync_constants.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/sync_repository.dart';

void disposeSyncManager(SyncManager instance) => instance.dispose();

enum ConnectivityState { online, offline }

enum SyncEngineStatus { idle, syncing, error }

/// Dedicated service that monitors connectivity and processes the SyncQueue.
@LazySingleton(dispose: disposeSyncManager)
class SyncManager {
  SyncManager(this._repository, this._syncRepository);

  final EducationRepository _repository;
  final SyncRepository _syncRepository;

  final StreamController<SyncEngineStatus> _statusController =
      StreamController<SyncEngineStatus>.broadcast();

  final StreamController<ConnectivityState> _connectivityController =
      StreamController<ConnectivityState>.broadcast();

  Stream<SyncEngineStatus> get statusStream => _statusController.stream;
  Stream<ConnectivityState> get connectivityStream =>
      _connectivityController.stream;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  ConnectivityState _currentConnectivity = ConnectivityState.offline;
  bool _isSyncing = false;

  /// Queued conflict simulation progressIds to execute during next sync.
  final List<String> _pendingConflictSimulations = <String>[];

  ConnectivityState get currentConnectivity => _currentConnectivity;

  @visibleForTesting
  set currentConnectivityForTest(ConnectivityState state) {
    _currentConnectivity = state;
  }

  /// Initialize connectivity listener.
  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    log.i('SyncManager initialized', tag: LogTags.sync);

    // Check initial connectivity
    Connectivity().checkConnectivity().then(_onConnectivityChanged);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final bool isConnected = results.any(
      (ConnectivityResult r) => r != ConnectivityResult.none,
    );

    final ConnectivityState newState = isConnected
        ? ConnectivityState.online
        : ConnectivityState.offline;

    if (newState != _currentConnectivity) {
      _currentConnectivity = newState;
      _connectivityController.add(newState);
      log.i('Connectivity changed: ${newState.name}', tag: LogTags.sync);

      if (newState == ConnectivityState.online) {
        performFullSync();
      }
    }
  }

  /// Runs a full sync cycle: upload queue → download updates.
  Future<void> performFullSync() async {
    if (_isSyncing) {
      log.d('Sync already in progress, skipping', tag: LogTags.sync);
      return;
    }
    if (_currentConnectivity == ConnectivityState.offline) {
      log.d('Offline, skipping sync', tag: LogTags.sync);
      return;
    }

    _isSyncing = true;
    _statusController.add(SyncEngineStatus.syncing);
    log.i('=== Full Sync Started ===', tag: LogTags.sync);

    try {
      await _processUploadQueue();
      await _processConflictSimulations();
      await _processDownloadUpdates();
      _statusController.add(SyncEngineStatus.idle);
      log.i('=== Full Sync Completed ===', tag: LogTags.sync);
    } catch (e, s) {
      log.e('Full sync failed', tag: LogTags.sync, error: e, stackTrace: s);
      _statusController.add(SyncEngineStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  /// Reads from SyncQueue, attempts to upload each item.
  /// On success: mark local record synced + remove queue item.
  /// On failure: increment retryCount (skip if exceeded max).
  Future<void> _processUploadQueue() async {
    final List<SyncQueueItem> pendingItems = await _repository
        .getPendingSyncItems();

    if (pendingItems.isEmpty) {
      log.d('Upload queue empty', tag: LogTags.sync);
      return;
    }

    log.i(
      'Processing upload queue: ${pendingItems.length} items',
      tag: LogTags.sync,
    );

    for (final SyncQueueItem item in pendingItems) {
      if (!_isReadyForRetry(item)) {
        log.d(
          'Queue item ${item.id} is in backoff period (retry=${item.retryCount}). Skipping.',
          tag: LogTags.sync,
        );
        continue;
      }

      if (item.retryCount >= SyncConstants.maxRetryCount) {
        log.w(
          'Sync item ${item.id} exceeded max retries '
          '(${item.retryCount}/${SyncConstants.maxRetryCount}). Final failure recorded.',
          tag: LogTags.sync,
        );
        continue;
      }

      try {
        final Map<String, dynamic> payload =
            jsonDecode(item.payload) as Map<String, dynamic>;

        await _syncRepository.uploadProgress(payload);

        // Upload succeeded → mark synced + remove from queue
        await _repository.markProgressSynced(item.entityId);
        await _repository.deleteSyncQueueItem(item.id);
        log.i(
          'Uploaded & synced queue item ${item.id} '
          '(entity=${item.entityId})',
          tag: LogTags.sync,
        );
      } catch (e) {
        await _repository.incrementRetryCount(item.id, item.retryCount);
        final backoff = math.pow(2, item.retryCount + 1) * 30;
        log.w(
          'Upload failed for queue item ${item.id}. '
          'Retry ${item.retryCount + 1}/${SyncConstants.maxRetryCount} scheduled in $backoff seconds.',
          tag: LogTags.sync,
        );
      }
    }
  }

  bool _isReadyForRetry(SyncQueueItem item) {
    if (item.lastAttemptAt == null) return true;
    // Exponential backoff: 2^retryCount * 30 seconds
    final int backoffSeconds = math.pow(2, item.retryCount).toInt() * 30;
    final DateTime nextAttempt = item.lastAttemptAt!.add(
      Duration(seconds: backoffSeconds),
    );
    return DateTime.now().isAfter(nextAttempt);
  }

  /// Fetches remote updates and applies LWW conflict resolution.
  Future<void> _processDownloadUpdates() async {
    log.d('Downloading remote updates...', tag: LogTags.sync);

    try {
      // Fetch and upsert users
      final List<Map<String, dynamic>> remoteUsers = await _syncRepository
          .fetchUsers();
      for (final Map<String, dynamic> userData in remoteUsers) {
        await _repository.upsertUserFromRemote(userData);
      }

      // Fetch and upsert lessons
      final List<Map<String, dynamic>> remoteLessons = await _syncRepository
          .fetchLessons();
      for (final Map<String, dynamic> lessonData in remoteLessons) {
        await _repository.upsertLessonFromRemote(lessonData);
      }

      // Fetch progress with LWW conflict resolution
      final List<Map<String, dynamic>> remoteProgresses = await _syncRepository
          .fetchAllProgress();
      int conflictsResolved = 0;
      for (final Map<String, dynamic> progressData in remoteProgresses) {
        final bool wasUpdated = await _repository.upsertProgressIfNewer(
          progressData,
        );
        if (wasUpdated) {
          conflictsResolved++;
        }
      }

      log.i(
        'Download complete: ${remoteUsers.length} users, '
        '${remoteLessons.length} lessons, '
        '${remoteProgresses.length} progress records '
        '($conflictsResolved applied via LWW)',
        tag: LogTags.sync,
      );
    } catch (e, s) {
      log.e('Download failed', tag: LogTags.sync, error: e, stackTrace: s);
    }
  }

  /// Seeds initial data into local DB on first launch.
  Future<void> seedInitialData() async {
    // Always seed offline lessons (idempotent)
    await seedOfflineLessons();
    await _repository.seedSampleLesson();

    // Seed sample progress for the dashboard demo
    const String solarSystemId = '550e8400-e29b-41d4-a716-446655440001';
    final Progress? existingProgress = await _repository
        .getProgressByUserAndLesson('current-user-id', solarSystemId);

    if (existingProgress == null) {
      await _repository.updateProgress(
        userId: 'current-user-id',
        lessonId: solarSystemId,
        incrementBy: 65,
        score: 450,
        masteryLevel: 'intermediate',
      );
    }

    final List<User> existingUsers = await _repository.getUsers();
    if (existingUsers.isNotEmpty) {
      log.d('Data already seeded, skipping remote seed', tag: LogTags.db);
      return;
    }

    log.i('Seeding initial data...', tag: LogTags.db);

    try {
      final List<Map<String, dynamic>> users = await _syncRepository
          .fetchUsers();
      for (final Map<String, dynamic> u in users) {
        await _repository.upsertUserFromRemote(u);
      }

      final List<Map<String, dynamic>> lessons = await _syncRepository
          .fetchLessons();
      for (final Map<String, dynamic> l in lessons) {
        await _repository.upsertLessonFromRemote(l);
      }

      log.i('Initial data seeded successfully', tag: LogTags.db);
    } catch (e, s) {
      log.e(
        'Failed to seed initial data',
        tag: LogTags.db,
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Seeds offline lessons into local DB. Idempotent — updates if already present.
  Future<void> seedOfflineLessons() async {
    const String solarSystemId = '550e8400-e29b-41d4-a716-446655440001';

    log.i('Seeding/Updating offline lesson: النظام الشمسي', tag: LogTags.db);

    const String lessonContent = '''
النظام الشمسي

تعريف النظام الشمسي

النظام الشمسي هو مجموعة من الاجرام السماوية التي تدور حول الشمس بفعل الجاذبية.
يشمل: الشمس، الكواكب، الاقمار، الكويكبات، المذنبات، والغبار الكوني.

الشمس

الشمس نجم متوسط الحجم ومصدر الطاقة الرئيسي للكواكب.
تشع الضوء والحرارة مما يجعل الحياة على الارض ممكنة.
تتكون الشمس بشكل رئيسي من غازي الهيدروجين والهيليوم.
تبلغ درجة حرارة سطح الشمس نحو 5500 درجة مئوية بينما تصل درجة حرارة مركزها الى 15 مليون درجة مئوية.

الكواكب

عدد الكواكب في المجموعة الشمسية 8 كواكب مقسمة الى نوعين:

الكواكب الصخرية الداخلية: عطارد، الزهرة، الارض، المريخ.
الكواكب الغازية العملاقة الخارجية: المشتري، زحل، اورانوس، نبتون.

عطارد: اصغر كواكب النظام الشمسي واقربها الى الشمس. ليس له غلاف جوي يذكر.

الزهرة: ثاني الكواكب بعدا عن الشمس ويشبه الارض في الحجم. يتميز بغلاف جوي كثيف يتكون من ثاني اكسيد الكربون مما يجعله اسخن كوكب في النظام الشمسي.

الارض: ثالث الكواكب بعدا عن الشمس، الكوكب الوحيد المعروف الذي توجد عليه حياة. تبعد عن الشمس حوالي 150 مليون كيلومتر. تدور حول الشمس في 365 يوما.

المريخ: رابع الكواكب بعدا عن الشمس. يسمى الكوكب الاحمر بسبب لون تربته الغنية بالحديد. له قمران صغيران هما فوبوس وديموس.

المشتري: اكبر كواكب النظام الشمسي. يتكون بشكل رئيسي من الهيدروجين والهيليوم. يمتلك اكثر من 90 قمرا معروفا.

زحل: يشتهر بحلقاته الجميلة المكونة من جسيمات جليدية وصخرية. هو ثاني اكبر كوكب في النظام الشمسي.

اورانوس: يتميز بميله الشديد على محوره حيث يبدو وكانه يدور على جانبه. يصنف كعملاق جليدي.

نبتون: ابعد الكواكب عن الشمس. يتميز بلونه الازرق الناتج عن وجود غاز الميثان في غلافه الجوي.

الاقمار

الاجرام التي تدور حول الكواكب مثل القمر الذي يدور حول الارض.

الكويكبات والمذنبات

الكويكبات: صخور فضائية صغيرة تتواجد غالبا بين المريخ والمشتري في ما يسمى حزام الكويكبات.
المذنبات: اجسام جليدية تظهر لها ذيل عند الاقتراب من الشمس لان الجليد يتبخر مكونا ذيلا مضيئا.

معلومات مثيرة للاهتمام

المشتري اكبر كواكب النظام الشمسي.
زحل مشهور بحلقاته الجميلة.
عطارد اقرب كوكب للشمس.
المريخ يسمى الكوكب الاحمر بسبب لون تربته الغنية بالحديد.
المسافة بين الارض والشمس حوالي 150 مليون كيلومتر.
كل الكواكب تدور حول الشمس في مدارات ثابتة.
جاذبية الشمس تحافظ على ثبات الكواكب في مداراتها.
النظام الشمسي عمره حوالي 4.6 مليار سنة.
الارض تستغرق 365 يوما للدوران حول الشمس دورة كاملة.

اسئلة المراجعة

1. كم عدد الكواكب في المجموعة الشمسية؟
2. اي الكواكب هو الاقرب الى الشمس؟
3. ما هو اكبر كوكب في المجموعة الشمسية؟
4. اي الكواكب يعرف بحلقاته الشهيرة؟
5. كم تستغرق الارض للدوران حول الشمس دورة كاملة؟
6. لماذا يسمى المريخ الكوكب الاحمر؟
7. ما المذنبات وماذا يحدث لها عند اقترابها من الشمس؟
8. اذكر الكواكب الصخرية الداخلية الاربعة.
''';

    await _repository.upsertLessonFromLocal(
      LessonsCompanion(
        id: const Value<String>(solarSystemId),
        title: const Value<String>('النظام الشمسي'),
        description: const Value<String>(
          'درس علوم للصف السابع عن النظام الشمسي والكواكب',
        ),
        content: const Value<String>(lessonContent),
        audioPath: const Value<String>('assets/audio/sound1.mp3'),
        videoPath: const Value<String>(''),
        durationMinutes: const Value<int>(30),
        updatedAt: Value<DateTime>(DateTime.now()),
        syncStatus: Value<String>(SyncStatus.synced.name),
        hasQuiz: const Value<bool>(true),
      ),
    );

    log.i('Offline lesson seeded successfully', tag: LogTags.db);
  }

  /// Queues a conflict simulation to be executed during the next sync cycle.
  /// This is safe to call while offline — no network call is made.
  void queueConflictSimulation(String progressId) {
    _pendingConflictSimulations.add(progressId);
    log.i(
      'Queued conflict simulation for progressId=$progressId',
      tag: LogTags.sync,
    );
  }

  /// Executes queued conflict simulations against Firestore.
  /// Runs AFTER uploads (so the doc exists) and BEFORE downloads (so LWW
  /// sees the newer timestamp).
  Future<void> _processConflictSimulations() async {
    if (_pendingConflictSimulations.isEmpty) return;

    log.i(
      'Processing ${_pendingConflictSimulations.length} conflict simulations',
      tag: LogTags.sync,
    );

    for (final String progressId in _pendingConflictSimulations) {
      try {
        await _syncRepository.simulateRemoteConflict(progressId);
        log.i(
          'Conflict simulation applied for progressId=$progressId',
          tag: LogTags.sync,
        );
      } catch (e) {
        log.w(
          'Conflict simulation failed for progressId=$progressId',
          tag: LogTags.sync,
        );
      }
    }
    _pendingConflictSimulations.clear();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
    _connectivityController.close();
    log.d('SyncManager disposed', tag: LogTags.sync);
  }
}
