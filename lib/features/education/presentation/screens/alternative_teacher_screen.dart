import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';

class AlternativeTeacherScreen extends StatefulWidget {
  const AlternativeTeacherScreen({super.key});

  @override
  State<AlternativeTeacherScreen> createState() =>
      _AlternativeTeacherScreenState();
}

class _AlternativeTeacherScreenState extends State<AlternativeTeacherScreen> {
  final EducationRepository _repository = getIt<EducationRepository>();
  final AudioPlayer _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoController;

  List<Lesson> _lessons = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    final lessons = await _repository.getLessons();
    if (mounted) {
      setState(() {
        _lessons = lessons;
        _isLoading = false;
        if (_lessons.isNotEmpty) {
          _initializeMedia();
        }
      });
    }
  }

  Future<void> _initializeMedia() async {
    // Reset players
    await _audioPlayer.stop();
    setState(() => _isAudioPlaying = false);

    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }

    final lesson = _lessons[_currentIndex];

    // Initialize Video if available
    if (lesson.videoPath.isNotEmpty) {
      if (lesson.videoPath.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(lesson.videoPath),
        );
      } else {
        _videoController = VideoPlayerController.asset(lesson.videoPath);
      }

      try {
        await _videoController!.initialize();
        setState(() {});
      } catch (e) {
        log.e('Error initializing video', error: e);
      }
    }
  }

  void _nextLesson() {
    if (_lessons.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _lessons.length;
      _initializeMedia();
    });
  }

  Future<void> _toggleAudio() async {
    final lesson = _lessons[_currentIndex];
    if (lesson.audioPath.isEmpty) return;

    if (_isAudioPlaying) {
      await _audioPlayer.pause();
    } else {
      Source source;
      if (lesson.audioPath.startsWith('assets/')) {
        source = AssetSource(lesson.audioPath.replaceFirst('assets/', ''));
      } else {
        source = DeviceFileSource(lesson.audioPath);
      }
      await _audioPlayer.play(source);
    }
    setState(() {
      _isAudioPlaying = !_isAudioPlaying;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_lessons.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('الدروس')),
        body: const Center(child: Text('لا توجد دروس حالياً.')),
      );
    }

    final lesson = _lessons[_currentIndex];
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Elegant Hero Header
          _buildSliverAppBar(context, lesson),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Media Section (Video or Illustration)
                  _buildMediaSection(context, lesson),
                  const SizedBox(height: 24),

                  // Audio Explanation Section
                  if (lesson.audioPath.isNotEmpty)
                    _buildAudioSection(context, lesson),

                  const SizedBox(height: 32),

                  // Content Section
                  Text(
                    'محتوى الدرس',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Text(
                      lesson.content,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.8,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),

                  const SizedBox(height: 120), // Bottom padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildBottomActions(context, lesson),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Lesson lesson) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
                theme.colorScheme.secondary,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.school,
                  size: 200,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'الدرس ${_currentIndex + 1} من ${_lessons.length}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lesson.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context, Lesson lesson) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child:
          lesson.videoPath.isNotEmpty &&
              _videoController != null &&
              _videoController!.value.isInitialized
          ? AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_videoController!),
                  _VideoOverlay(
                    controller: _videoController!,
                    onToggle: () => setState(() {}),
                  ),
                ],
              ),
            )
          : Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surfaceContainerHighest,
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا يوجد فيديو متاح لهذا الدرس',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAudioSection(BuildContext context, Lesson lesson) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          _AudioPlayButton(isPlaying: _isAudioPlaying, onTap: _toggleAudio),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'استمع للشرح الصوتي',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'شرح مفصل بصوت المدرس',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, Lesson lesson) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _nextLesson,
          icon: const Icon(Icons.skip_next),
          label: const Text(
            'الدرس التالي',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoOverlay extends StatelessWidget {
  const _VideoOverlay({required this.controller, required this.onToggle});
  final VideoPlayerController controller;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
              onToggle();
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: AnimatedOpacity(
                  opacity: controller.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: Theme.of(context).colorScheme.primary,
              bufferedColor: Colors.white24,
              backgroundColor: Colors.white10,
            ),
          ),
        ),
      ],
    );
  }
}

class _AudioPlayButton extends StatelessWidget {
  const _AudioPlayButton({required this.isPlaying, required this.onTap});
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
      ),
    );
  }
}
