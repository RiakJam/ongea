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
  bool _isFullScreen = false;
  double _verticalDragStart = 0.0;

  @override
  Widget build(BuildContext context) {
    if (widget.videoController == null || !widget.videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        if (!_isFullScreen) {
          // Enter full screen when tapping the video
          _enterFullScreen(context);
        } else {
          // Toggle controls when in full screen
          setState(() {
            _showVideoControls = !_showVideoControls;
          });
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _controlsHovered = true),
        onExit: (_) => setState(() => _controlsHovered = false),
        child: Stack(
          key: widget.videoKey,
          alignment: Alignment.center,
          children: [
            // Cropped video display
            AspectRatio(
              aspectRatio: 16 / 9, // Standard aspect ratio for feed
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: widget.videoController!.value.size.width,
                    height: widget.videoController!.value.size.height,
                    child: VideoPlayer(widget.videoController!),
                  ),
                ),
              ),
            ),
            
            // Controls overlay
            if (_showVideoControls || _controlsHovered || !widget.isPlaying || widget.isUserPaused)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Progress bar with controls in one row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        child: Row(
                          children: [
                            // Play/Pause button
                            IconButton(
                              icon: Icon(
                                widget.isUserPaused || !widget.isPlaying 
                                  ? Icons.play_arrow 
                                  : Icons.pause,
                                size: 24,
                                color: Colors.white,
                              ),
                              onPressed: _togglePlayPause,
                            ),
                            
                            // Progress bar (expands to fill available space)
                            Expanded(
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
                            
                            // Full screen button (only in crop view)
                            if (!_isFullScreen)
                              IconButton(
                                icon: Icon(Icons.fullscreen, size: 24, color: Colors.white),
                                onPressed: () => _enterFullScreen(context),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _togglePlayPause() {
    if (widget.isUserPaused || !widget.isPlaying) {
      widget.onUserPause(false);
    } else {
      widget.onUserPause(true);
    }
  }

  void _enterFullScreen(BuildContext context) {
    // Store the current playing state
    final wasPlaying = widget.isPlaying && !widget.isUserPaused;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: GestureDetector(
              onVerticalDragStart: (details) {
                _verticalDragStart = details.globalPosition.dy;
              },
              onVerticalDragUpdate: (details) {
                // Calculate drag distance for visual feedback if needed
                final dragDistance = details.globalPosition.dy - _verticalDragStart;
              },
              onVerticalDragEnd: (details) {
                final dragDistance = details.velocity.pixelsPerSecond.dy;
                // Exit full screen if user swipes down significantly
                if (dragDistance > 500) {
                  Navigator.pop(context);
                }
              },
              onTap: () {
                setState(() {
                  _showVideoControls = !_showVideoControls;
                });
              },
              child: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: widget.videoController!.value.aspectRatio,
                      child: VideoPlayer(widget.videoController!),
                    ),
                  ),
                  
                  // Controls overlay in full screen
                  if (_showVideoControls)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Progress bar with controls in one row (same as crop view)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  // Play/Pause button
                                  IconButton(
                                    icon: Icon(
                                      widget.isUserPaused || !widget.isPlaying 
                                        ? Icons.play_arrow 
                                        : Icons.pause,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                    onPressed: _togglePlayPause,
                                  ),
                                  
                                  // Progress bar
                                  Expanded(
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
                                  
                                  // Minimize button (replaces fullscreen button)
                                  IconButton(
                                    icon: Icon(Icons.fullscreen_exit, size: 24, color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      // When returning from full screen, resume playing if it was playing
      if (wasPlaying) {
        widget.onUserPause(false);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}