import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/lesson_cubit.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/lesson_audio_player.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/lesson_text_view.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/teacher_explanation_widget.dart';

class LessonContent extends StatefulWidget {
  const LessonContent({
    super.key,
    required this.lesson,
    required this.isCompleted,
  });

  final Lesson lesson;
  final bool isCompleted;

  @override
  State<LessonContent> createState() => _LessonContentState();
}

class _LessonContentState extends State<LessonContent> {
  late final AudioPlayer _audioPlayer;
  bool _isPlayerReady = false;
  String? _playerError;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    log.i('Initializing audio: ${widget.lesson.audioPath}');
    if (widget.lesson.audioPath.isEmpty) {
      setState(() => _playerError = 'No audio available');
      return;
    }

    try {
      final String path = widget.lesson.audioPath;
      
      // Check if it's a local filesystem path (e.g., starting with C:\ or D:\)
      // or if it exists as a file on the system.
      bool isLocalFile = false;
      if (path.contains(':\\') || path.contains(':/')) {
        final File file = File(path);
        if (file.existsSync()) {
          isLocalFile = true;
        }
      }

      if (isLocalFile) {
        log.i('Loading audio from local file: $path');
        await _audioPlayer.setAudioSource(AudioSource.file(path));
      } else {
        log.i('Loading audio from assets: $path');
        await _audioPlayer.setAsset(path);
      }
      
      await _audioPlayer.load().timeout(const Duration(seconds: 5));
      
      log.i('Audio loaded successfully');
      if (mounted) {
        setState(() => _isPlayerReady = true);
      }
    } catch (e, stack) {
      log.e('Failed to load audio', error: e, stackTrace: stack);
      if (mounted) {
        setState(() {
          _playerError = e is TimeoutException 
              ? 'Audio loading timed out' 
              : 'Could not load audio';
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        actions: [
          IconButton(
            onPressed: () => TeacherExplanationWidget.show(context, widget.lesson.content),
            icon: const Icon(Icons.psychology_alt),
            tooltip: 'Explain with AI',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: LessonTextView(content: widget.lesson.content),
              ),
            ),
          ),
          LessonAudioPlayer(
            player: _audioPlayer,
            isReady: _isPlayerReady,
            error: _playerError,
          ),
          _CompletionBar(
            isCompleted: widget.isCompleted,
            onComplete: () => context.read<LessonCubit>().markCompleted(),
          ),
        ],
      ),
    );
  }
}

class _CompletionBar extends StatelessWidget {
  const _CompletionBar({required this.isCompleted, required this.onComplete});
  final bool isCompleted;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: isCompleted
          ? const _CompletedStatus()
          : FilledButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.done_all),
              label: const Text('Mark as Completed'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
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
      children: <Widget>[
        Icon(Icons.check_circle, color: Colors.green.shade600),
        const SizedBox(width: 8),
        Text(
          'Lesson Completed',
          style: TextStyle(
            color: Colors.green.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
