import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPost extends StatefulWidget {
  final VideoPlayerController? videoController;
  final GlobalKey? videoKey;
  final bool isPlaying;
  final bool isUserPaused;
  final Function(bool) onUserPause;

  const VideoPost({
    this.videoController,
    this.videoKey,
    this.isPlaying = false,
    this.isUserPaused = false,
    required this.onUserPause,
  });

  @override
  _VideoPostState createState() => _VideoPostState();
}

class _VideoPostState extends State<VideoPost> {
  bool _showVideoControls = false;
  bool _controlsHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.videoController == null || !widget.videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showVideoControls = !_showVideoControls;
        });
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _controlsHovered = true),
        onExit: (_) => setState(() => _controlsHovered = false),
        child: Stack(
          key: widget.videoKey,
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: widget.videoController!.value.aspectRatio,
              child: VideoPlayer(widget.videoController!),
            ),
            if (_showVideoControls || _controlsHovered || !widget.isPlaying || widget.isUserPaused)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: IconButton(
                        icon: Icon(
                          widget.isUserPaused ? Icons.play_arrow : Icons.pause,
                          size: 50,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                widget.videoController!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePlayPause() {
    if (widget.isUserPaused) {
      widget.onUserPause(false);
    } else {
      widget.onUserPause(true);
    }
  }
}