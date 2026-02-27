import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/smart_teacher_cubit.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/smart_teacher_state.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';

/// واجهة محسّنة للمعلم الذكي
class EnhancedTeacherExplanationWidget extends StatefulWidget {
  const EnhancedTeacherExplanationWidget({
    super.key,
    required this.lessonContent,
  });

  final String lessonContent;

  @override
  State<EnhancedTeacherExplanationWidget> createState() =>
      _EnhancedTeacherExplanationWidgetState();

  static void show(BuildContext context, String content) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          EnhancedTeacherExplanationWidget(lessonContent: content),
    );
  }
}

class _EnhancedTeacherExplanationWidgetState
    extends State<EnhancedTeacherExplanationWidget> {
  late SmartTeacherCubit _cubit;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<SmartTeacherCubit>();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SmartTeacherCubit>.value(
      value: _cubit,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المعلم الذكي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Options
              Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildOptionButton(
                        label: 'شرح مفصل',
                        icon: Icons.description,
                        onTap: () =>
                            _cubit.getDetailedExplanation(widget.lessonContent),
                      ),
                      const SizedBox(width: 12),
                      _buildOptionButton(
                        label: 'ملخص',
                        icon: Icons.summarize,
                        onTap: () => _cubit.getSummary(widget.lessonContent),
                      ),
                      const SizedBox(width: 12),
                      _buildOptionButton(
                        label: 'أسئلة',
                        icon: Icons.quiz,
                        onTap: () =>
                            _cubit.generateQuestions(widget.lessonContent),
                      ),
                      const SizedBox(width: 12),
                      _buildOptionButton(
                        label: 'نصائح',
                        icon: Icons.lightbulb,
                        onTap: () => _cubit.getStudyTips('الموضوع الحالي'),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Expanded(
                child: BlocBuilder<SmartTeacherCubit, SmartTeacherState>(
                  builder: (context, state) {
                    if (state is SmartTeacherInitial) {
                      return _buildEmptyState();
                    } else if (state is SmartTeacherLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is SmartTeacherExplanation) {
                      return _buildContentView(state.text);
                    } else if (state is SmartTeacherQuestions) {
                      return _buildContentView(state.questions);
                    } else if (state is SmartTeacherAnswer) {
                      return _buildContentView(state.answer);
                    } else if (state is SmartTeacherSpeaking) {
                      return _buildSpeakingState();
                    } else if (state is SmartTeacherPaused) {
                      return _buildPausedState();
                    } else if (state is SmartTeacherFeedback) {
                      return _buildContentView(state.feedback);
                    } else if (state is SmartTeacherStudyTips) {
                      return _buildContentView(state.tips);
                    } else if (state is SmartTeacherError) {
                      return _buildErrorView(state.message);
                    }
                    return _buildEmptyState();
                  },
                ),
              ),
              // Audio Controls
              BlocBuilder<SmartTeacherCubit, SmartTeacherState>(
                builder: (context, state) =>
                    _buildAudioControls(context, state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildContentView(String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_alt,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'اختر احدى الخيارات حتى يساعدك المعلم الذكي',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volume_up, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'جاري التحدث...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pause_circle, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            'مؤقف مؤقتاً',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioControls(BuildContext context, SmartTeacherState state) {
    final isCurrentlyAvailable =
        state is SmartTeacherExplanation ||
        state is SmartTeacherAnswer ||
        state is SmartTeacherFeedback ||
        state is SmartTeacherQuestions ||
        state is SmartTeacherStudyTips;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (isCurrentlyAvailable)
            FilledButton.icon(
              onPressed: _isPlaying
                  ? () => _cubit.stopSpeaking()
                  : state is SmartTeacherPaused
                  ? () {
                      _isPlaying = true;
                      setState(() {});
                    }
                  : () => _getStringFromState(state).then((text) {
                      _cubit.speak(text);
                      setState(() => _isPlaying = true);
                    }),
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
              label: Text(_isPlaying ? 'إيقاف' : 'تشغيل الصوت'),
            ),
          if (isCurrentlyAvailable && _isPlaying)
            IconButton(
              onPressed: () => _cubit.pauseSpeaking(),
              icon: const Icon(Icons.pause),
              tooltip: 'توقيف مؤقت',
            ),
        ],
      ),
    );
  }

  Future<String> _getStringFromState(SmartTeacherState state) async {
    if (state is SmartTeacherExplanation) return state.text;
    if (state is SmartTeacherQuestions) {
      return state.questions;
    }
    if (state is SmartTeacherAnswer) return state.answer;
    if (state is SmartTeacherFeedback) {
      return state.feedback;
    }
    if (state is SmartTeacherStudyTips) return state.tips;
    return '';
  }
}
