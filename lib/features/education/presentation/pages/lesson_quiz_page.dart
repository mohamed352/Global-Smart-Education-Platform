import 'package:flutter/material.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/quiz_repository.dart';
import 'package:global_smart_education_platform/features/education/presentation/screens/quiz_screen.dart';

class LessonQuizPage extends StatefulWidget {
  const LessonQuizPage({super.key});

  @override
  State<LessonQuizPage> createState() => _LessonQuizPageState();
}

class _LessonQuizPageState extends State<LessonQuizPage> {
  final EducationRepository _repository = getIt<EducationRepository>();
  final QuizRepository _quizRepository = getIt<QuizRepository>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'اختبار الدروس',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<Lesson>>(
        stream: _repository.watchLessons(),
        builder: (context, lessonSnapshot) {
          if (lessonSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final lessons = (lessonSnapshot.data ?? [])
              .where((l) => l.hasQuiz)
              .toList();

          if (lessons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد اختبارات متاحة حالياً',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return _LessonQuizCard(
                lesson: lesson,
                quizRepository: _quizRepository,
              );
            },
          );
        },
      ),
    );
  }
}

class _LessonQuizCard extends StatelessWidget {
  const _LessonQuizCard({required this.lesson, required this.quizRepository});

  final Lesson lesson;
  final QuizRepository quizRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<QuizAttempt?>(
      future: quizRepository.getLatestCompletedAttempt(
        'current-user-id',
        lesson.id,
      ),
      builder: (context, attemptSnapshot) {
        final lastAttempt = attemptSnapshot.data;
        final hasResult = lastAttempt != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _startQuiz(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: hasResult
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        hasResult ? Icons.check_circle : Icons.quiz_rounded,
                        color: hasResult
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title + Score
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (hasResult)
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'آخر نتيجة: ${lastAttempt.score}%',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'لم يتم الاختبار بعد',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Start button
                    FilledButton.tonal(
                      onPressed: () => _startQuiz(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(hasResult ? 'إعادة' : 'ابدأ'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startQuiz(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            QuizScreen(lessonId: lesson.id, lessonTitle: lesson.title),
      ),
    );
  }
}
