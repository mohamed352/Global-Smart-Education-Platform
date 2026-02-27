import 'package:flutter/material.dart';
import 'package:global_smart_education_platform/features/education/presentation/screens/quiz_result_screen.dart';

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

  void _submitQuiz() {
    int correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      if ((_answers[i] ?? '').trim() == _questions[i].correctAnswer.trim()) {
        correct++;
      }
    }
    final score = ((correct / _questions.length) * 100).round();
    String mastery;
    if (score >= 80) {
      mastery = 'خبير';
    } else if (score >= 60) {
      mastery = 'متقدم';
    } else if (score >= 40) {
      mastery = 'متوسط';
    } else {
      mastery = 'مبتدئ';
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => QuizResultScreen(
          score: score,
          masteryLevel: mastery,
          totalQuestions: _questions.length,
          correctAnswers: correct,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = _questions[_currentIndex];
    final currentAnswer = _answers[_currentIndex];
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle, overflow: TextOverflow.ellipsis),
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
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: Row(
                children: [
                  Text(
                    'السؤال ${_currentIndex + 1} من ${_questions.length}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / _questions.length,
                          minHeight: 8,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question text card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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

                    // Answers
                    if (question.isMultipleChoice)
                      ...question.options.map((option) {
                        final isSelected = currentAnswer == option;
                        return GestureDetector(
                          onTap: () => _answerQuestion(option),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                                width: isSelected ? 2 : 1,
                              ),
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                        .withOpacity(0.35)
                                  : theme.colorScheme.surface,
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outlineVariant,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                    else
                      TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'اكتب إجابتك هنا...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                        ),
                        maxLines: 3,
                        onChanged: _answerQuestion,
                      ),
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
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (!isFirst)
                    OutlinedButton.icon(
                      onPressed: _goToPrevious,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('السابق'),
                    ),
                  const Spacer(),
                  if (isLast)
                    FilledButton.icon(
                      onPressed: _allAnswered ? _submitQuiz : null,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('إرسال'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: currentAnswer != null ? _goToNext : null,
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
}
