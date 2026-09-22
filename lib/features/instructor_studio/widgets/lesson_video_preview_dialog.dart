import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/utils/media_url.dart';

class LessonVideoPreviewDialog extends StatefulWidget {
  final String title;
  final String videoUrl;

  const LessonVideoPreviewDialog({
    super.key,
    required this.title,
    required this.videoUrl,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String videoUrl,
  }) {
    return showDialog(
      context: context,
      builder: (context) => LessonVideoPreviewDialog(
        title: title,
        videoUrl: videoUrl,
      ),
    );
  }

  @override
  State<LessonVideoPreviewDialog> createState() => _LessonVideoPreviewDialogState();
}

class _LessonVideoPreviewDialogState extends State<LessonVideoPreviewDialog> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final resolvedUrl = mediaUrl(widget.videoUrl);
    final uri = Uri.tryParse(resolvedUrl);
    if (uri == null) {
      setState(() {
        _isLoading = false;
        _error = 'Invalid video URL: $resolvedUrl';
      });
      return;
    }

    try {
      _videoController = VideoPlayerController.networkUrl(uri);
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio > 0
            ? _videoController!.value.aspectRatio
            : 16 / 9,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load video: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_outline, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : Chewie(controller: _chewieController!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
