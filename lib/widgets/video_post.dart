import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'video_full_screen_page.dart';

class VideoPost extends StatefulWidget {
  final VideoPlayerController? videoController;
  final String username;
  final String userAvatar;
  final String caption;
  final int likes;
  final int comments;
  final String postId;
  final String userId;
  final String? currentUserId;

  const VideoPost({
    this.videoController,
    this.username = '',
    this.userAvatar = '',
    this.caption = '',
    this.likes = 0,
    this.comments = 0,
    required this.postId,
    required this.userId,
    this.currentUserId,
  });

  @override
  _VideoPostState createState() => _VideoPostState();
}

class _VideoPostState extends State<VideoPost> {
  bool _controlsHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.videoController == null ||
        !widget.videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return VisibilityDetector(
      key: Key(widget.postId),
      onVisibilityChanged: (info) {
        final visiblePercentage = info.visibleFraction * 100;
        if (visiblePercentage > 50) {
          // Play when more than half is visible
          if (!widget.videoController!.value.isPlaying) {
            widget.videoController!.play();
          }
        } else {
          // Pause when mostly out of view
          if (widget.videoController!.value.isPlaying) {
            widget.videoController!.pause();
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          _openFullScreen(context);
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _controlsHovered = true),
          onExit: (_) => setState(() => _controlsHovered = false),
          child: Container(
            // Set a fixed height to make the video taller
            height: 400, // Adjust this value to control how tall the video appears
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Maintain 16:9 aspect ratio but allow slight cropping
                AspectRatio(
                  aspectRatio: 11 / 9,
                  child: ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      // Adjust the alignment to control which part gets cropped
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: widget.videoController!.value.size.width,
                        height: widget.videoController!.value.size.height,
                        child: VideoPlayer(widget.videoController!),
                      ),
                    ),
                  ),
                ),

                // Video controls (always visible)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  widget.videoController!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  size: 24,
                                  color: Colors.white,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                              Expanded(
                                child: VideoProgressIndicator(
                                  widget.videoController!,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(
                                    playedColor: Colors.blue,
                                    bufferedColor: Colors.grey,
                                    backgroundColor: Colors.grey,
                                  ),
                                ),
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
        ),
      ),
    );
  }

  void _togglePlayPause() {
    if (widget.videoController!.value.isPlaying) {
      widget.videoController!.pause();
    } else {
      widget.videoController!.play();
    }
    setState(() {}); // Update UI state
  }

  void _openFullScreen(BuildContext context) {
    // Pause the current video before navigating
    if (widget.videoController!.value.isPlaying) {
      widget.videoController!.pause();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoFullScreenPage(
          // Only pass the essential identifier - the postId
          initialPostId: widget.postId,
        ),
        fullscreenDialog: true,
      ),
    );
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}