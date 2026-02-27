import 'package:flutter/material.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';

class AppErrorBoundary extends StatefulWidget {
  const AppErrorBoundary({super.key, required this.child, this.onRetry});

  final Widget child;
  final VoidCallback? onRetry;

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
  }

  void resetError() {
    setState(() {
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'حدث خطأ غير متوقع',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'نعتذر، واجهنا مشكلة في عرض هذا الجزء.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  resetError();
                  widget.onRetry?.call();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      );
    }

    return widget.child;
  }

  @override
  void activate() {
    super.activate();
  }

  // Use ErrorWidget.builder or just catch errors if manually triggered
  void catchError(Object error) {
    AppLogger.instance.e('UI Error caught by boundary', error: error);
    setState(() {
      _hasError = true;
    });
  }
}
