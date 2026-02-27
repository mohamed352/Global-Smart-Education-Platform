import 'dart:math';
import 'package:flutter/material.dart';

class MasteryChartWidget extends StatelessWidget {
  const MasteryChartWidget({
    super.key,
    required this.progress,
    required this.masteryLevel,
    this.size = 150,
  });

  final double progress; // 0.0 to 1.0
  final String masteryLevel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _MasteryPainter(
              progress: progress,
              color: _getMasteryColor(masteryLevel, theme),
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                _translateMastery(masteryLevel),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMasteryColor(String level, ThemeData theme) {
    switch (level.toLowerCase()) {
      case 'expert':
        return Colors.amber;
      case 'advanced':
        return theme.colorScheme.primary;
      case 'intermediate':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _translateMastery(String level) {
    switch (level.toLowerCase()) {
      case 'expert':
        return 'ممتاز';
      case 'advanced':
        return 'متقدم';
      case 'intermediate':
        return 'جيد';
      case 'beginner':
        return 'مقبول';
      default:
        return 'مقبول';
    }
  }
}

class _MasteryPainter extends CustomPainter {
  _MasteryPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;
    final strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MasteryPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
