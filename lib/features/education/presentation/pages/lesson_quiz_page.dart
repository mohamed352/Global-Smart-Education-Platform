import 'package:flutter/material.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';
import 'package:global_smart_education_platform/features/education/presentation/screens/quiz_screen.dart';

/// Lessons that have hardcoded quiz questions in quiz_screen.dart
const _quizLessonIds = {'lesson_1'};

class LessonQuizPage extends StatelessWidget {
  const LessonQuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = getIt<EducationRepository>();

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
        stream: repo.watchLessons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data ?? [];
          // Show lessons that have a quiz (hasQuiz flag OR in hardcoded set)
          final lessons = all
              .where((l) => l.hasQuiz || _quizLessonIds.contains(l.id))
              .toList();

          // If no flagged lessons, show all lessons (every lesson gets a quiz)
          final display = lessons.isEmpty ? all : lessons;

          if (display.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد دروس متاحة حالياً',
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
            itemCount: display.length,
            itemBuilder: (context, index) =>
                _LessonQuizCard(lesson: display[index]),
          );
        },
      ),
    );
  }
}

class _LessonQuizCard extends StatelessWidget {
  const _LessonQuizCard({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
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
                // Icon badge
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.quiz_rounded,
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Title + subtitle
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
                      Text(
                        '5 أسئلة • اختيار من متعدد',
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
                  child: const Text('ابدأ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            QuizScreen(lessonId: lesson.id, lessonTitle: lesson.title),
      ),
    );
  }
}
