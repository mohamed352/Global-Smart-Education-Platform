import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class LessonAudioSlider extends StatelessWidget {
  const LessonAudioSlider({super.key, required this.player});
  final AudioPlayer player;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      builder: (context, durationSnap) {
        final totalDuration = durationSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (context, posSnap) {
            final position = posSnap.data ?? Duration.zero;
            return Column(
              children: <Widget>[
                Slider(
                  max: totalDuration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                  value: position.inMilliseconds.toDouble().clamp(
                        0,
                        totalDuration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                      ),
                  onChanged: (value) => player.seek(Duration(milliseconds: value.toInt())),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(_formatDuration(position)),
                      Text(_formatDuration(totalDuration)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class LessonAudioButtons extends StatelessWidget {
  const LessonAudioButtons({super.key, required this.player});
  final AudioPlayer player;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.replay_10),
          onPressed: () {
            final newPos = player.position - const Duration(seconds: 10);
            player.seek(newPos < Duration.zero ? Duration.zero : newPos);
          },
        ),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final isPlaying = playerState?.playing ?? false;
            final processingState = playerState?.processingState;

            if (processingState == ProcessingState.completed) {
              return IconButton.filled(
                icon: const Icon(Icons.replay, size: 32),
                onPressed: () {
                  player.seek(Duration.zero);
                  player.play();
                },
              );
            }

            return IconButton.filled(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 32),
              onPressed: isPlaying ? player.pause : player.play,
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.forward_10),
          onPressed: () {
            final total = player.duration ?? Duration.zero;
            final newPos = player.position + const Duration(seconds: 10);
            player.seek(newPos > total ? total : newPos);
          },
        ),
      ],
    );
  }
}
