import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/repositories/education_repository.dart';
import 'package:video_player/video_player.dart';

class AlternativeTeacherScreen extends StatefulWidget {
  const AlternativeTeacherScreen({super.key});

  @override
  State<AlternativeTeacherScreen> createState() => _AlternativeTeacherScreenState();
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
        _videoController = VideoPlayerController.networkUrl(Uri.parse(lesson.videoPath));
      } else {
        // Assume asset or local file
        _videoController = VideoPlayerController.asset(lesson.videoPath);
      }
      
      try {
        await _videoController!.initialize();
        setState(() {});
      } catch (e) {
        debugPrint('Error initializing video: $e');
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
        appBar: AppBar(title: const Text('Alternative Teacher')),
        body: const Center(child: Text('No lessons found.')),
      );
    }

    final lesson = _lessons[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alternative Teacher'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lesson Title
              Text(
                lesson.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
              
              // Video Player Placeholder or Actual Player
              if (lesson.videoPath.isNotEmpty && _videoController != null && _videoController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      VideoPlayer(_videoController!),
                      VideoProgressIndicator(_videoController!, allowScrubbing: true),
                      Center(
                        child: IconButton(
                          icon: Icon(
                            _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 50,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _videoController!.value.isPlaying
                                  ? _videoController!.pause()
                                  : _videoController!.play();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                )
              else if (lesson.videoPath.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator()),
                ),

              const SizedBox(height: 16),

              // Audio Control
              if (lesson.audioPath.isNotEmpty)
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: const Text('Audio Explanation'),
                    subtitle: Text(lesson.audioPath),
                    onTap: _toggleAudio,
                  ),
                ),

              const SizedBox(height: 24),

              // Lesson Text Content
              Text(
                'Lesson Content',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              Text(
                lesson.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
              
              const SizedBox(height: 100), // Space for bottom button
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nextLesson,
        label: const Text('Next Lesson'),
        icon: const Icon(Icons.navigate_next),
      ),
    );
  }
}
