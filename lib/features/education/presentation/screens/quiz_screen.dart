import 'package:flutter/material.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';

// ---------------------------------------------------------------------------
// Data model — purely in-memory, no DB dependency
// ---------------------------------------------------------------------------
class _QuizQuestion {
  const _QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
  });
  final String questionText;
  final List<String> options; // empty list = short answer
  final String correctAnswer;
  bool get isMultipleChoice => options.isNotEmpty;
}

// ---------------------------------------------------------------------------
// Hardcoded questions — النظام الشمسي
// ---------------------------------------------------------------------------
const Map<String, List<_QuizQuestion>> _lessonQuestions = {};

// Default questions used for all lessons
const List<_QuizQuestion> _defaultQuestions = [
  _QuizQuestion(
    questionText: 'كم عدد الكواكب في المجموعة الشمسية؟',
    options: ['7', '8', '9', '10'],
    correctAnswer: '8',
  ),
  _QuizQuestion(
    questionText: 'أي الكواكب هو الأقرب إلى الشمس؟',
    options: ['الزهرة', 'المريخ', 'عطارد', 'الأرض'],
    correctAnswer: 'عطارد',
  ),
  _QuizQuestion(
    questionText: 'ما هو أكبر كوكب في المجموعة الشمسية؟',
    options: ['زحل', 'أورانوس', 'نبتون', 'المشتري'],
    correctAnswer: 'المشتري',
  ),
  _QuizQuestion(
    questionText: 'أي الكواكب يُعرف بحلقاته الشهيرة؟',
    options: ['المشتري', 'زحل', 'أورانوس', 'نبتون'],
    correctAnswer: 'زحل',
  ),
  _QuizQuestion(
    questionText: 'كم تستغرق الأرض للدوران حول الشمس دورة كاملة؟',
    options: ['24 ساعة', '30 يوماً', '365 يوماً', '100 يوم'],
    correctAnswer: '365 يوماً',
  ),
];

// ---------------------------------------------------------------------------
// Main QuizScreen — fully standalone StatefulWidget
// ---------------------------------------------------------------------------
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  final String lessonId;
  final String lessonTitle;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  late final List<_QuizQuestion> _questions;
  final Map<int, String> _answers = {};
  int _currentIndex = 0;
  final TextEditingController _textController = TextEditingController();
  late AnimationController _progressAnimController;
  late Animation<double> _progressAnimation;
  final EducationRepository _repository = getIt<EducationRepository>();

  @override
  void initState() {
    super.initState();
    _questions = _lessonQuestions[widget.lessonId] ?? _defaultQuestions;
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1 / _questions.length)
        .animate(
          CurvedAnimation(
            parent: _progressAnimController,
            curve: Curves.easeOut,
          ),
        );
    _progressAnimController.forward();
  }

  @override
  void dispose() {
    _progressAnimController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentIndex < _questions.length - 1) {
      final nextProgress = (_currentIndex + 2) / _questions.length;
      _progressAnimation =
          Tween<double>(
            begin: (_currentIndex + 1) / _questions.length,
            end: nextProgress,
          ).animate(
            CurvedAnimation(
              parent: _progressAnimController,
              curve: Curves.easeOut,
            ),
          );
      _progressAnimController
        ..reset()
        ..forward();
      setState(() {
        _currentIndex++;
        _textController.text = _answers[_currentIndex] ?? '';
      });
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _textController.text = _answers[_currentIndex] ?? '';
      });
    }
  }

  void _answerQuestion(String answer) {
    setState(() => _answers[_currentIndex] = answer);
  }

  bool get _allAnswered => _answers.length == _questions.length;

  Future<void> _submitQuiz() async {
    int correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      if ((_answers[i] ?? '').trim() == _questions[i].correctAnswer.trim()) {
        correct++;
      }
    }
    final score = ((correct / _questions.length) * 100).round();

    // Map to db mastery keys
    String mastery;
    if (score >= 90) {
      mastery = 'expert';
    } else if (score >= 75) {
      mastery = 'advanced';
    } else if (score >= 50) {
      mastery = 'intermediate';
    } else {
      mastery = 'beginner';
    }

    // Save progress to database
    await _repository.updateProgress(
      userId: 'current-user-id', // Using the same ID as StudentProgressPage
      lessonId: widget.lessonId,
      incrementBy: 100, // Mark as completed when quiz is done
      score: score,
      masteryLevel: mastery,
    );

    if (!mounted) return;

    // Show result summary and go back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم إكمال الاختبار بنجاح! نتيجتك: $score%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = _questions[_currentIndex];
    final currentAnswer = _answers[_currentIndex];
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _questions.length - 1;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.lessonTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'السؤال ${_currentIndex + 1}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'من ${_questions.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_currentIndex + 1) / _questions.length,
                        minHeight: 10,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question text card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.5,
                            ),
                            theme.colorScheme.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withValues(
                              alpha: 0.03,
                            ),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        question.questionText,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Answers
                    if (question.isMultipleChoice)
                      ...question.options.map((option) {
                        final isSelected = currentAnswer == option;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _answerQuestion(option),
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.05,
                                        )
                                      : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outlineVariant
                                              .withValues(alpha: 0.5),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme
                                                    .colorScheme
                                                    .outlineVariant,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                    else
                      TextField(
                        controller: _textController,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'اكتب إجابتك هنا...',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        maxLines: 4,
                        onChanged: _answerQuestion,
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -5),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (!isFirst)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _goToPrevious,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('السابق'),
                      ),
                    ),
                  if (!isFirst) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: isLast
                          ? (_allAnswered ? _submitQuiz : null)
                          : (currentAnswer != null ? _goToNext : null),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: isLast ? Colors.green : null,
                      ),
                      child: Text(isLast ? 'إرسال الاختبار' : 'السؤال التالي'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
