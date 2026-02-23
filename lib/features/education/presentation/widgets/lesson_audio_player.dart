import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/lesson_audio_controls.dart';

class LessonAudioPlayer extends StatelessWidget {
  const LessonAudioPlayer({
    super.key,
    required this.player,
    required this.isReady,
    required this.error,
  });

  final AudioPlayer player;
  final bool isReady;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _PlayerErrorDisplay(error: error!);
    }

    if (!isReady) {
      return const _PlayerLoadingDisplay();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LessonAudioSlider(player: player),
          LessonAudioButtons(player: player),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _PlayerErrorDisplay extends StatelessWidget {
  const _PlayerErrorDisplay({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: <Widget>[
          const Icon(Icons.music_off, size: 20),
          const SizedBox(width: 8),
          Text(error),
        ],
      ),
    );
  }
}

class _PlayerLoadingDisplay extends StatelessWidget {
  const _PlayerLoadingDisplay();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Row(
        children: <Widget>[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading audio...'),
        ],
      ),
    );
  }
}
