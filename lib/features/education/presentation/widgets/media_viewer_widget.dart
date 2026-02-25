import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';

/// عارض محسّن للصور والفيديو في الدروس
class MediaViewerWidget extends StatefulWidget {
  const MediaViewerWidget({
    super.key,
    required this.mediaPath,
    required this.mediaType, // 'image' or 'video'
    this.title,
  });

  final String mediaPath;
  final String mediaType;
  final String? title;

  @override
  State<MediaViewerWidget> createState() =>
      _MediaViewerWidgetState();
}

class _MediaViewerWidgetState
    extends State<MediaViewerWidget> {
  late VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video') {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.file(
        File(widget.mediaPath),
      );
      await _videoController!.initialize();
      setState(() => _isVideoInitialized = true);
    } catch (e) {
      log.e('Failed to initialize video', error: e);
      setState(() => _error = 'فشل تحميل الفيديو');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaType == 'image') {
      return _buildImageView();
    } else if (widget.mediaType == 'video') {
      return _buildVideoView();
    }
    return Center(
      child: Text(
        'نوع وسائط غير مدعوم: ${widget.mediaType}',
      ),
    );
  }

  Widget _buildImageView() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.title!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(widget.mediaPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  log.e(
                    'Failed to load image',
                    error: error,
                  );
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        const Text('فشل تحميل الصورة'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoView() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 8),
            Text(_error!),
          ],
        ),
      );
    }

    if (!_isVideoInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoController!),
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _videoController!.value.isPlaying
                      ? _videoController!.pause()
                      : _videoController!.play();
                });
              },
              backgroundColor: Colors.black54,
              child: Icon(
                _videoController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة وسائط محسّنة
class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.mediaPath,
    required this.mediaType,
    this.title,
    this.onTap,
    this.onDelete,
  });

  final String mediaPath;
  final String mediaType;
  final String? title;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (mediaType == 'image')
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Image.file(
                      File(mediaPath),
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image_not_supported,
                              ),
                            );
                          },
                    ),
                  )
                else if (mediaType == 'video')
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.videocam, size: 48),
                    ),
                  ),
                if (onDelete != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
