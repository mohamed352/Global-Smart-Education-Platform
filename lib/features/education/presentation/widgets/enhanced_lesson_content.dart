import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/lesson_cubit.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/enhanced_teacher_explanation_widget.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/lesson_audio_player.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/lesson_text_view.dart';

/// محتوى الدرس المحسّن مع دعم الوسائط
class EnhancedLessonContent extends StatefulWidget {
  const EnhancedLessonContent({
    super.key,
    required this.lesson,
    required this.isCompleted,
  });

  final Lesson lesson;
  final bool isCompleted;

  @override
  State<EnhancedLessonContent> createState() =>
      _EnhancedLessonContentState();
}

class _EnhancedLessonContentState
    extends State<EnhancedLessonContent>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _audioPlayer;
  late TabController _tabController;
  bool _isPlayerReady = false;
  String? _playerError;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _tabController = TabController(
      length: _getTabs().length,
      vsync: this,
    );
    _initAudio();
  }

  List<String> _getTabs() {
    final tabs = ['المحتوى'];
    if (widget.lesson.audioPath.isNotEmpty) {
      tabs.add('الصوت');
    }
    // imagePath و videoPath غير متاحة في نموذج البيانات الحالي
    return tabs;
  }

  Future<void> _initAudio() async {
    log.i('Initializing audio: ${widget.lesson.audioPath}');
    if (widget.lesson.audioPath.isEmpty) {
      setState(() => _playerError = 'لا يوجد صوت متاح');
      return;
    }

    try {
      final String path = widget.lesson.audioPath;
      bool isLocalFile = false;
      if (path.contains(':\\') || path.contains(':/')) {
        final File file = File(path);
        if (file.existsSync()) {
          isLocalFile = true;
        }
      }

      if (isLocalFile) {
        log.i('Loading audio from local file: $path');
        await _audioPlayer.setAudioSource(
          AudioSource.file(path),
        );
      } else {
        log.i('Loading audio from assets: $path');
        await _audioPlayer.setAsset(path);
      }

      await _audioPlayer.load().timeout(
        const Duration(seconds: 5),
      );

      log.i('Audio loaded successfully');
      if (mounted) {
        setState(() => _isPlayerReady = true);
      }
    } catch (e, stack) {
      log.e(
        'Failed to load audio',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        setState(() {
          _playerError =
              e.runtimeType.toString().contains(
                'TimeoutException',
              )
              ? 'انتهت مهلة تحميل الصوت'
              : 'فشل تحميل الصوت';
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: _getTabs()
              .map((tab) => Tab(text: tab))
              .toList(),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                EnhancedTeacherExplanationWidget.show(
                  context,
                  widget.lesson.content,
                ),
            icon: const Icon(Icons.psychology_alt),
            tooltip: 'شرح ذكي',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // تبويب المحتوى
          _buildContentTab(),

          // تبويب الصوت (إن وجد)
          if (widget.lesson.audioPath.isNotEmpty)
            _buildAudioTab(),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    return Column(
      children: [
        Expanded(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: LessonTextView(
                content: widget.lesson.content,
              ),
            ),
          ),
        ),
        _CompletionBar(
          isCompleted: widget.isCompleted,
          onComplete: () =>
              context.read<LessonCubit>().markCompleted(),
        ),
      ],
    );
  }

  Widget _buildAudioTab() {
    return Column(
      children: [
        LessonAudioPlayer(
          player: _audioPlayer,
          isReady: _isPlayerReady,
          error: _playerError,
        ),
        _CompletionBar(
          isCompleted: widget.isCompleted,
          onComplete: () =>
              context.read<LessonCubit>().markCompleted(),
        ),
      ],
    );
  }
}

class _CompletionBar extends StatelessWidget {
  const _CompletionBar({
    required this.isCompleted,
    required this.onComplete,
  });
  final bool isCompleted;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: isCompleted
          ? const _CompletedStatus()
          : FilledButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.done_all),
              label: const Text('تم إنهاء الدرس'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  48,
                ),
              ),
            ),
    );
  }
}

class _CompletedStatus extends StatelessWidget {
  const _CompletedStatus();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'تم إنهاء هذا الدرس',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }
}
