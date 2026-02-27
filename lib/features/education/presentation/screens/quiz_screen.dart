import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/quiz_cubit.dart';
import 'package:global_smart_education_platform/features/education/presentation/screens/quiz_result_screen.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  final String lessonId;
  final String lessonTitle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<QuizCubit>()..loadQuiz(lessonId, lessonTitle),
      child: const _QuizScreenBody(),
    );
  }
}

class _QuizScreenBody extends StatelessWidget {
  const _QuizScreenBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<QuizCubit, QuizState>(
      listener: (context, state) {
        state.maybeWhen(
          completed: (score, masteryLevel, totalQuestions, correctAnswers) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (_) => QuizResultScreen(
                  score: score,
                  masteryLevel: masteryLevel,
                  totalQuestions: totalQuestions,
                  correctAnswers: correctAnswers,
                ),
              ),
            );
          },
          orElse: () {},
        );
      },
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => Scaffold(
            appBar: AppBar(
              title: const Text('جاري التحميل...'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
          active: (questions, currentIndex, answers, attemptId, lessonTitle) =>
              _buildQuizUI(
                context,
                questions,
                currentIndex,
                answers,
                lessonTitle,
              ),
          submitting: () => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تقييم الإجابات...',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          completed: (_, __, ___, ____) => const SizedBox.shrink(),
          error: (message) => Scaffold(
            appBar: AppBar(
              title: const Text('خطأ'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('العودة'),
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

  Widget _buildQuizUI(
    BuildContext context,
    List<QuizQuestion> questions,
    int currentIndex,
    Map<int, String> answers,
    String lessonTitle,
  ) {
    final theme = Theme.of(context);
    final cubit = context.read<QuizCubit>();
    final question = questions[currentIndex];
    final isLast = currentIndex == questions.length - 1;
    final isFirst = currentIndex == 0;
    final currentAnswer = answers[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(lessonTitle),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Text(
                    'السؤال ${currentIndex + 1} من ${questions.length}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (currentIndex + 1) / questions.length,
                        minHeight: 8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        question.questionText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Answer area
                    if (question.questionType == 'multiple_choice')
                      _buildMultipleChoice(
                        context,
                        question,
                        currentAnswer,
                        currentIndex,
                      )
                    else
                      _buildShortAnswer(context, currentAnswer, currentIndex),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (!isFirst)
                    OutlinedButton.icon(
                      onPressed: cubit.goToPrevious,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('السابق'),
                    ),
                  const Spacer(),
                  if (isLast)
                    FilledButton.icon(
                      onPressed: cubit.allAnswered ? cubit.submitQuiz : null,
                      icon: const Icon(Icons.check),
                      label: const Text('إرسال'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: cubit.goToNext,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('التالي'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoice(
    BuildContext context,
    QuizQuestion question,
    String? currentAnswer,
    int questionIndex,
  ) {
    final theme = Theme.of(context);
    final cubit = context.read<QuizCubit>();
    final List<dynamic> options = jsonDecode(question.options) as List<dynamic>;

    return Column(
      children: options.map<Widget>((option) {
        final optionStr = option.toString();
        final isSelected = currentAnswer == optionStr;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : null,
          ),
          child: RadioListTile<String>(
            value: optionStr,
            groupValue: currentAnswer,
            onChanged: (value) {
              if (value != null) {
                cubit.answerQuestion(questionIndex, value);
              }
            },
            title: Text(
              optionStr,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShortAnswer(
    BuildContext context,
    String? currentAnswer,
    int questionIndex,
  ) {
    final theme = Theme.of(context);
    final cubit = context.read<QuizCubit>();

    return TextField(
      controller: TextEditingController(text: currentAnswer ?? ''),
      decoration: InputDecoration(
        hintText: 'اكتب إجابتك هنا...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
      ),
      maxLines: 3,
      onChanged: (value) {
        cubit.answerQuestion(questionIndex, value);
      },
    );
  }
}
