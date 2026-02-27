import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';

/// Repository for quiz operations: CRUD, scoring, and state restoration.
@LazySingleton()
class QuizRepository {
  QuizRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  // ── Read ──

  Future<List<QuizQuestion>> getQuestionsForLesson(String lessonId) =>
      _db.getQuestionsForLesson(lessonId);

  Future<QuizAttempt?> getActiveAttempt(String userId, String lessonId) =>
      _db.getActiveAttempt(userId, lessonId);

  Future<QuizAttempt?> getLatestCompletedAttempt(
    String userId,
    String lessonId,
  ) => _db.getLatestCompletedAttempt(userId, lessonId);

  Future<List<QuizAttempt>> getAllCompletedAttempts(String userId) =>
      _db.getAllCompletedAttempts(userId);

  Stream<List<QuizAttempt>> watchAllAttempts(String userId) =>
      _db.watchAllAttempts(userId);

  // ── Get or Create Attempt ──

  Future<QuizAttempt> getOrCreateAttempt(String userId, String lessonId) async {
    // Try to resume an in-progress attempt
    final existing = await _db.getActiveAttempt(userId, lessonId);
    if (existing != null) return existing;

    // Create a new attempt
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.upsertQuizAttempt(
      QuizAttemptsCompanion(
        id: Value(id),
        lessonId: Value(lessonId),
        userId: Value(userId),
        answers: const Value('{}'),
        currentIndex: const Value(0),
        score: const Value(0),
        masteryLevel: const Value('beginner'),
        isCompleted: const Value(false),
        startedAt: Value(now),
      ),
    );

    return (await _db.getActiveAttempt(userId, lessonId))!;
  }

  // ── Save Answer (Auto-Save) ──

  Future<void> saveAnswer(
    String attemptId,
    int questionIndex,
    String answer,
    int currentIndex,
    String currentAnswersJson,
  ) async {
    final Map<String, dynamic> answers =
        jsonDecode(currentAnswersJson) as Map<String, dynamic>;
    answers[questionIndex.toString()] = answer;

    await _db.upsertQuizAttempt(
      QuizAttemptsCompanion(
        id: Value(attemptId),
        answers: Value(jsonEncode(answers)),
        currentIndex: Value(currentIndex),
      ),
    );
  }

  // ── Submit Quiz ──

  Future<({int score, String masteryLevel})> submitQuiz(
    String attemptId,
    String answersJson,
    List<QuizQuestion> questions,
  ) async {
    final Map<String, dynamic> answers =
        jsonDecode(answersJson) as Map<String, dynamic>;

    int correct = 0;
    for (int i = 0; i < questions.length; i++) {
      final userAnswer = answers[i.toString()]?.toString().trim().toLowerCase();
      final correctAnswer = questions[i].correctAnswer.trim().toLowerCase();
      if (userAnswer == correctAnswer) correct++;
    }

    final int score = questions.isEmpty
        ? 0
        : ((correct / questions.length) * 100).round();

    final String masteryLevel;
    if (score >= 90) {
      masteryLevel = 'expert';
    } else if (score >= 70) {
      masteryLevel = 'advanced';
    } else if (score >= 50) {
      masteryLevel = 'intermediate';
    } else {
      masteryLevel = 'beginner';
    }

    await _db.upsertQuizAttempt(
      QuizAttemptsCompanion(
        id: Value(attemptId),
        answers: Value(answersJson),
        score: Value(score),
        masteryLevel: Value(masteryLevel),
        isCompleted: const Value(true),
        completedAt: Value(DateTime.now()),
      ),
    );

    return (score: score, masteryLevel: masteryLevel);
  }

  // ── Seed Sample Questions ──

  Future<void> seedSampleQuestions() async {
    final existing = await _db.getQuestionsForLesson('sample-lesson-1');
    if (existing.isNotEmpty) return;

    final questions = [
      QuizQuestionsCompanion(
        id: const Value('q1-sample-lesson-1'),
        lessonId: const Value('sample-lesson-1'),
        questionText: const Value('ما هو مبدأ "أوفلاين أولاً" في التطبيقات؟'),
        questionType: const Value('multiple_choice'),
        options: Value(
          jsonEncode([
            'العمل بدون إنترنت',
            'تخزين البيانات محلياً أولاً ثم المزامنة',
            'عدم استخدام الخوادم',
            'استخدام البيانات المؤقتة فقط',
          ]),
        ),
        correctAnswer: const Value('تخزين البيانات محلياً أولاً ثم المزامنة'),
        orderIndex: const Value(0),
      ),
      QuizQuestionsCompanion(
        id: const Value('q2-sample-lesson-1'),
        lessonId: const Value('sample-lesson-1'),
        questionText: const Value(
          'أي من التالي يُعد ميزة للتعلم عبر الوسائط المتعددة؟',
        ),
        questionType: const Value('multiple_choice'),
        options: Value(
          jsonEncode([
            'زيادة حجم التطبيق',
            'تحسين الفهم والاستيعاب',
            'تقليل سرعة التطبيق',
            'حذف البيانات القديمة',
          ]),
        ),
        correctAnswer: const Value('تحسين الفهم والاستيعاب'),
        orderIndex: const Value(1),
      ),
      QuizQuestionsCompanion(
        id: const Value('q3-sample-lesson-1'),
        lessonId: const Value('sample-lesson-1'),
        questionText: const Value('ما هو دور "المعلم البديل" في المنصة؟'),
        questionType: const Value('multiple_choice'),
        options: Value(
          jsonEncode([
            'حذف الدروس',
            'تقديم شرح تفاعلي بوسائط متعددة',
            'إدارة المستخدمين',
            'تحديث النظام',
          ]),
        ),
        correctAnswer: const Value('تقديم شرح تفاعلي بوسائط متعددة'),
        orderIndex: const Value(2),
      ),
      QuizQuestionsCompanion(
        id: const Value('q4-sample-lesson-1'),
        lessonId: const Value('sample-lesson-1'),
        questionText: const Value('ما الفائدة الرئيسية من مزامنة البيانات؟'),
        questionType: const Value('multiple_choice'),
        options: Value(
          jsonEncode([
            'تقليل استخدام الذاكرة',
            'ضمان تحديث البيانات عبر الأجهزة',
            'تسريع الإنترنت',
            'حذف البيانات تلقائياً',
          ]),
        ),
        correctAnswer: const Value('ضمان تحديث البيانات عبر الأجهزة'),
        orderIndex: const Value(3),
      ),
      QuizQuestionsCompanion(
        id: const Value('q5-sample-lesson-1'),
        lessonId: const Value('sample-lesson-1'),
        questionText: const Value('اذكر ميزة واحدة لنهج "أوفلاين أولاً"'),
        questionType: const Value('short_answer'),
        options: const Value('[]'),
        correctAnswer: const Value('الوصول للمحتوى بدون إنترنت'),
        orderIndex: const Value(4),
      ),
    ];

    for (final q in questions) {
      await _db.upsertQuizQuestion(q);
    }
  }
}
