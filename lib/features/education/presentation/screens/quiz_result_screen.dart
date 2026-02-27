import 'package:flutter/material.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.score,
    required this.masteryLevel,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  final int score;
  final String masteryLevel;
  final int totalQuestions;
  final int correctAnswers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color scoreColor;
    final IconData scoreIcon;
    final String message;

    if (score >= 90) {
      scoreColor = Colors.green;
      scoreIcon = Icons.emoji_events;
      message = 'ممتاز! أداء رائع 🎉';
    } else if (score >= 70) {
      scoreColor = Colors.blue;
      scoreIcon = Icons.thumb_up;
      message = 'جيد جداً! استمر 👏';
    } else if (score >= 50) {
      scoreColor = Colors.orange;
      scoreIcon = Icons.trending_up;
      message = 'جيد، يمكنك التحسن 💪';
    } else {
      scoreColor = Colors.red;
      scoreIcon = Icons.refresh;
      message = 'حاول مرة أخرى 📚';
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Trophy/Icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(seconds: 1),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(scoreIcon, size: 80, color: scoreColor),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Score Circle
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: score / 100),
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 16,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              color: scoreColor,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(value * 100).toInt()}%',
                                style: theme.textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'الدرجة النهائية',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Message
                  Text(
                    message,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Details Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(
                            alpha: 0.05,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          context,
                          'الإجابات الصحيحة',
                          '$correctAnswers / $totalQuestions',
                          Icons.check_circle_rounded,
                          Colors.green,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(),
                        ),
                        _buildDetailRow(
                          context,
                          'مستوى الإتقان',
                          _translateMastery(masteryLevel),
                          Icons.stars_rounded,
                          scoreColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('العودة للاختبارات'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _translateMastery(String level) {
    switch (level.toLowerCase()) {
      case 'expert':
        return 'خبير';
      case 'advanced':
        return 'متقدم';
      case 'intermediate':
        return 'متوسط';
      case 'beginner':
        return 'مبتدئ';
      default:
        return 'مبتدئ';
    }
  }
}
