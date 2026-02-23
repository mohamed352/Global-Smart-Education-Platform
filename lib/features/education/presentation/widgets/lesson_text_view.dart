import 'package:flutter/material.dart';

class LessonTextView extends StatelessWidget {
  const LessonTextView({super.key, required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    final List<String> lines = content.split('\n');
    final List<Widget> widgets = <Widget>[];

    for (final String line in lines) {
      final String trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      final bool isHeading = _isHeading(trimmed);

      if (isHeading) {
        widgets.add(
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 12, bottom: 4),
            child: Text(
              trimmed,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        );
      } else {
        widgets.add(
          Text(
            trimmed,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  bool _isHeading(String text) {
    return text.length < 40 &&
        !text.endsWith('.') &&
        !text.endsWith('\u061f') &&
        !_isListNumber(text);
  }

  bool _isListNumber(String text) {
    return text.startsWith('1.') ||
        text.startsWith('2.') ||
        text.startsWith('3.') ||
        text.startsWith('4.') ||
        text.startsWith('5.');
  }
}
