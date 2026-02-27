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
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Score Circle
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: score / 100),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 12,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            color: scoreColor,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(scoreIcon, size: 36, color: scoreColor),
                            const SizedBox(height: 4),
                            Text(
                              '${(value * 100).toInt()}%',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Message
                Text(
                  message,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        context,
                        'الإجابات الصحيحة',
                        '$correctAnswers / $totalQuestions',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        'المستوى',
                        _translateMastery(masteryLevel),
                        Icons.stars,
                        scoreColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Back button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('العودة للاختبارات'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
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
