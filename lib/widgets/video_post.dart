// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'comment_section.dart';
// import '../services/gift_page.dart';

// class VideoPost extends StatefulWidget {
//   final VideoPlayerController? videoController;
//   final GlobalKey? videoKey;
//   final bool isPlaying;
//   final bool isUserPaused;
//   final Function(bool) onUserPause;
//   final int videoIndex;
//   final Function(int)? onVideoChange;
//   final int totalVideos;
//   final String username;
//   final String userAvatar;
//   final String caption;
//   final int likes;
//   final int comments;
//   final bool isLiked;
//   final bool isSaved;
//   final bool isFollowing;
//   final bool showFollowButton;
//   final Function()? onLike;
//   final Function()? onSave;
//   final Function()? onComment;
//   final Function()? onShare;
//   final Function()? onGift;
//   final Function()? onFollow;
//   final String postId;
//   final String userId;
//   final String? currentUserId;

//   const VideoPost({
//     this.videoController,
//     this.videoKey,
//     this.isPlaying = false,
//     this.isUserPaused = false,
//     required this.onUserPause,
//     this.videoIndex = 0,
//     this.onVideoChange,
//     this.totalVideos = 1,
//     this.username = '',
//     this.userAvatar = '',
//     this.caption = '',
//     this.likes = 0,
//     this.comments = 0,
//     this.isLiked = false,
//     this.isSaved = false,
//     this.isFollowing = false,
//     this.showFollowButton = true,
//     this.onLike,
//     this.onSave,
//     this.onComment,
//     this.onShare,
//     this.onGift,
//     this.onFollow,
//     required this.postId,
//     required this.userId,
//     this.currentUserId,
//   });

//   @override
//   _VideoPostState createState() => _VideoPostState();
// }

// class _VideoPostState extends State<VideoPost> {
//   bool _showVideoControls = false;
//   bool _controlsHovered = false;
//   bool _isFullScreen = false;
//   double _verticalDragStart = 0.0;

//   // Local state for instant feedback
//   bool _localIsLiked = false;
//   bool _localIsSaved = false;
//   int _localLikes = 0;
//   int _localComments = 0;

//   @override
//   void initState() {
//     super.initState();
//     // Initialize local state with widget values
//     _localIsLiked = widget.isLiked;
//     _localIsSaved = widget.isSaved;
//     _localLikes = widget.likes;
//     _localComments = widget.comments;
//   }

//   @override
//   void didUpdateWidget(VideoPost oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // Update local state if widget values change
//     if (oldWidget.isLiked != widget.isLiked) {
//       _localIsLiked = widget.isLiked;
//     }
//     if (oldWidget.isSaved != widget.isSaved) {
//       _localIsSaved = widget.isSaved;
//     }
//     if (oldWidget.likes != widget.likes) {
//       _localLikes = widget.likes;
//     }
//     if (oldWidget.comments != widget.comments) {
//       _localComments = widget.comments;
//     }
//   }

//   void _handleLike() {
//     setState(() {
//       _localIsLiked = !_localIsLiked;
//       _localLikes = _localIsLiked ? _localLikes + 1 : _localLikes - 1;
//     });

//     if (widget.onLike != null) {
//       widget.onLike!();
//     }
//   }

//   void _handleSave() {
//     setState(() {
//       _localIsSaved = !_localIsSaved;
//     });

//     if (widget.onSave != null) {
//       widget.onSave!();
//     }
//   }

//   void _handleFollow() {
//     if (widget.onFollow != null) {
//       widget.onFollow!();
//     } else {
//       // Default follow behavior if no callback provided
//       _showLoginRequiredModal(context);
//     }
//   }

//   void _showLoginRequiredModal(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Login Required'),
//           content: Text('You need to log in to follow users.'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text('Ok'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.videoController == null ||
//         !widget.videoController!.value.isInitialized) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return GestureDetector(
//       onTap: () {
//         if (!_isFullScreen) {
//           _enterFullScreen(context);
//         } else {
//           setState(() {
//             _showVideoControls = !_showVideoControls;
//           });
//         }
//       },
//       child: MouseRegion(
//         onEnter: (_) => setState(() => _controlsHovered = true),
//         onExit: (_) => setState(() => _controlsHovered = false),
//         child: Stack(
//           key: widget.videoKey,
//           alignment: Alignment.center,
//           children: [
//             AspectRatio(
//               aspectRatio: 16 / 9,
//               child: ClipRect(
//                 child: FittedBox(
//                   fit: BoxFit.cover,
//                   child: SizedBox(
//                     width: widget.videoController!.value.size.width,
//                     height: widget.videoController!.value.size.height,
//                     child: VideoPlayer(widget.videoController!),
//                   ),
//                 ),
//               ),
//             ),

//             if (_showVideoControls ||
//                 _controlsHovered ||
//                 !widget.isPlaying ||
//                 widget.isUserPaused)
//               Positioned.fill(
//                 child: Container(
//                   color: Colors.black.withOpacity(0.3),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8.0,
//                           vertical: 8.0,
//                         ),
//                         child: Row(
//                           children: [
//                             IconButton(
//                               icon: Icon(
//                                 widget.isUserPaused || !widget.isPlaying
//                                     ? Icons.play_arrow
//                                     : Icons.pause,
//                                 size: 24,
//                                 color: Colors.white,
//                               ),
//                               onPressed: _togglePlayPause,
//                             ),

//                             Expanded(
//                               child: VideoProgressIndicator(
//                                 widget.videoController!,
//                                 allowScrubbing: true,
//                                 colors: const VideoProgressColors(
//                                   playedColor: Colors.blue,
//                                   bufferedColor: Colors.grey,
//                                   backgroundColor: Colors.grey,
//                                 ),
//                               ),
//                             ),

//                             if (!_isFullScreen)
//                               IconButton(
//                                 icon: Icon(
//                                   Icons.fullscreen,
//                                   size: 24,
//                                   color: Colors.white,
//                                 ),
//                                 onPressed: () => _enterFullScreen(context),
//                               ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _togglePlayPause() {
//     if (widget.isUserPaused || !widget.isPlaying) {
//       widget.onUserPause(false);
//     } else {
//       widget.onUserPause(true);
//     }
//   }

//   void _enterFullScreen(BuildContext context) {
//     final wasPlaying = widget.isPlaying && !widget.isUserPaused;

//     Navigator.push(
//       context,
//       PageRouteBuilder(
//         opaque: false,
//         pageBuilder: (BuildContext context, _, __) {
//           return Scaffold(
//             backgroundColor: Colors.black,
//             body: LayoutBuilder(
//               builder: (context, constraints) {
//                 final screenHeight = constraints.maxHeight;
//                 final screenWidth = constraints.maxWidth;

//                 final isSmallScreen = screenHeight < 600;
//                 final iconSize = isSmallScreen ? 20.0 : 28.0;
//                 final buttonSpacing = isSmallScreen ? 8.0 : 12.0;
//                 final fontSize = isSmallScreen ? 10.0 : 12.0;
//                 final controlsHeight = 60.0;
//                 final actionButtonsBottom = controlsHeight + 12.0;

//                 final safeAreaTop = isSmallScreen ? 80.0 : 100.0;
//                 final availableHeight =
//                     screenHeight - safeAreaTop - controlsHeight;
//                 final maxButtonHeight = availableHeight / 5;

//                 final isOwnPost =
//                     widget.currentUserId?.trim() == widget.userId.trim();

//                 final shouldShowFollowButton =
//                     widget.currentUserId == null ||
//                     (!isOwnPost && !widget.isFollowing);

//                 return GestureDetector(
//                   onVerticalDragStart: (details) {
//                     _verticalDragStart = details.globalPosition.dy;
//                   },
//                   onVerticalDragUpdate: (details) {
//                     final dragDistance =
//                         details.globalPosition.dy - _verticalDragStart;
//                   },
//                   onVerticalDragEnd: (details) {
//                     if (widget.onVideoChange != null) {
//                       final dragDistance = details.velocity.pixelsPerSecond.dy;

//                       if (dragDistance < -500 &&
//                           widget.videoIndex < widget.totalVideos - 1) {
//                         widget.onVideoChange!(widget.videoIndex + 1);
//                       } else if (dragDistance > 500 && widget.videoIndex > 0) {
//                         widget.onVideoChange!(widget.videoIndex - 1);
//                       }
//                     }
//                   },
//                   onTap: () {
//                     setState(() {
//                       _showVideoControls = !_showVideoControls;
//                     });
//                   },
//                   child: Stack(
//                     children: [
//                       Center(
//                         child: AspectRatio(
//                           aspectRatio:
//                               widget.videoController!.value.aspectRatio,
//                           child: VideoPlayer(widget.videoController!),
//                         ),
//                       ),

//                       // 👤 User Info - moved above caption
//                       Positioned(
//                         left: 16,
//                         bottom: 130.0, // Adjust this to suit your layout
//                         right: screenWidth * 0.4,
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             CircleAvatar(
//                               backgroundImage: widget.userAvatar.isNotEmpty
//                                   ? NetworkImage(widget.userAvatar)
//                                   : const AssetImage(
//                                           'assets/default_avatar.png',
//                                         )
//                                         as ImageProvider,
//                               radius: isSmallScreen ? 16.0 : 20.0,
//                             ),
//                             const SizedBox(width: 8),
//                             Flexible(
//                               child: Text(
//                                 widget.username,
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: isSmallScreen ? 14.0 : 16.0,
//                                 ),
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                             if (shouldShowFollowButton &&
//                                 widget.showFollowButton)
//                               Padding(
//                                 padding: const EdgeInsets.only(left: 6.0),
//                                 child: TextButton(
//                                   onPressed: _handleFollow,
//                                   style: TextButton.styleFrom(
//                                     padding: EdgeInsets.symmetric(
//                                       horizontal: isSmallScreen ? 6.0 : 8.0,
//                                       vertical: isSmallScreen ? 2.0 : 4.0,
//                                     ),
//                                     tapTargetSize:
//                                         MaterialTapTargetSize.shrinkWrap,
//                                     minimumSize: Size.zero,
//                                   ),
//                                   child: Text(
//                                     'Follow',
//                                     style: TextStyle(
//                                       color: Colors.blue,
//                                       fontSize: isSmallScreen ? 12.0 : 14.0,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),

//                       // 📝 Caption
//                       Positioned(
//                         left: 16,
//                         bottom: 80.0,
//                         right: screenWidth * 0.4,
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               widget.caption,
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: isSmallScreen ? 12.0 : 14.0,
//                               ),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ],
//                         ),
//                       ),

//                       // 📌 Action buttons (right side)
//                       Positioned(
//                         right: 12,
//                         bottom: actionButtonsBottom,
//                         child: Container(
//                           constraints: BoxConstraints(
//                             maxHeight: maxButtonHeight * 5,
//                           ),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               _CompactActionButton(
//                                 icon: _localIsLiked
//                                     ? Icons.favorite
//                                     : Icons.favorite_border,
//                                 label: _formatNumber(_localLikes),
//                                 color: _localIsLiked
//                                     ? Colors.blue
//                                     : Colors.white,
//                                 onTap: _handleLike,
//                                 iconSize: iconSize,
//                                 fontSize: fontSize,
//                               ),
//                               SizedBox(height: buttonSpacing),
//                               _CompactActionButton(
//                                 icon: Icons.comment,
//                                 label: _formatNumber(_localComments),
//                                 onTap: () {
//                                   showModalBottomSheet(
//                                     context: context,
//                                     isScrollControlled: true,
//                                     builder: (context) =>
//                                         CommentSection(postId: widget.postId),
//                                   );
//                                 },
//                                 iconSize: iconSize,
//                                 fontSize: fontSize,
//                               ),
//                               SizedBox(height: buttonSpacing),
//                               _CompactActionButton(
//                                 icon: _localIsSaved
//                                     ? Icons.bookmark
//                                     : Icons.bookmark_border,
//                                 label: '',
//                                 color: _localIsSaved
//                                     ? Colors.blue
//                                     : Colors.white,
//                                 onTap: _handleSave,
//                                 iconSize: iconSize,
//                                 fontSize: fontSize,
//                               ),
//                               SizedBox(height: buttonSpacing),
//                               _CompactActionButton(
//                                 icon: Icons.card_giftcard,
//                                 label: 'Gift',
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) => GiftPage(
//                                         recipientName: widget.username,
//                                         recipientAvatar: widget.userAvatar,
//                                         recipientId: widget.userId,
//                                         postId: widget.postId,
//                                       ),
//                                     ),
//                                   );
//                                 },
//                                 iconSize: iconSize,
//                                 fontSize: fontSize,
//                               ),
//                               SizedBox(height: buttonSpacing),
//                               _CompactActionButton(
//                                 icon: Icons.share,
//                                 label: 'Share',
//                                 onTap: widget.onShare ?? () => _shareVideo(),
//                                 iconSize: iconSize,
//                                 fontSize: fontSize,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       // 🎮 Video controls (bottom)
//                       Positioned(
//                         left: 0,
//                         right: 0,
//                         bottom: 0,
//                         child: Container(
//                           color: Colors.black.withOpacity(0.5),
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 6,
//                           ),
//                           child: Column(
//                             children: [
//                               VideoProgressIndicator(
//                                 widget.videoController!,
//                                 allowScrubbing: true,
//                                 colors: const VideoProgressColors(
//                                   playedColor: Colors.blue,
//                                   bufferedColor: Colors.grey,
//                                   backgroundColor: Colors.grey,
//                                 ),
//                               ),
//                               const SizedBox(height: 6),
//                               Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   IconButton(
//                                     icon: Icon(
//                                       widget.isUserPaused || !widget.isPlaying
//                                           ? Icons.play_arrow
//                                           : Icons.pause,
//                                       color: Colors.white,
//                                       size: isSmallScreen ? 18.0 : 22.0,
//                                     ),
//                                     onPressed: _togglePlayPause,
//                                   ),
//                                   IconButton(
//                                     icon: Icon(
//                                       Icons.volume_up,
//                                       color: Colors.white,
//                                       size: isSmallScreen ? 18.0 : 22.0,
//                                     ),
//                                     onPressed: () {},
//                                   ),
//                                   Expanded(
//                                     child: Text(
//                                       '${_formatDuration(widget.videoController!.value.position)} / ${_formatDuration(widget.videoController!.value.duration)}',
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: isSmallScreen ? 10.0 : 12.0,
//                                       ),
//                                     ),
//                                   ),
//                                   IconButton(
//                                     icon: Icon(
//                                       Icons.fullscreen_exit,
//                                       color: Colors.white,
//                                       size: isSmallScreen ? 18.0 : 22.0,
//                                     ),
//                                     onPressed: () => Navigator.pop(context),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       // 🔢 Video index
//                       if (widget.totalVideos > 1)
//                         Positioned(
//                           top: isSmallScreen ? 30.0 : 50.0,
//                           right: 12,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.black.withOpacity(0.5),
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: Text(
//                               '${widget.videoIndex + 1}/${widget.totalVideos}',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: isSmallScreen ? 10.0 : 12.0,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     ).then((_) {
//       if (wasPlaying) {
//         widget.onUserPause(false);
//       }
//     });
//   }

//   String _formatNumber(int number) {
//     if (number >= 1000000) {
//       return '${(number / 1000000).toStringAsFixed(1)}M';
//     } else if (number >= 1000) {
//       return '${(number / 1000).toStringAsFixed(1)}K';
//     }
//     return number.toString();
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, "0");
//     String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
//     String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
//     return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
//   }

//   void _shareVideo() {
//     // Implement share functionality
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }
// }

// class _CompactActionButton extends StatelessWidget {
//   final IconData icon;
//   final String? label;
//   final Color color;
//   final Function() onTap;
//   final double iconSize;
//   final double fontSize;

//   const _CompactActionButton({
//     required this.icon,
//     this.label,
//     this.color = Colors.white,
//     required this.onTap,
//     this.iconSize = 24.0,
//     this.fontSize = 12.0,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         IconButton(
//           icon: Icon(icon, color: color, size: iconSize),
//           onPressed: onTap,
//           padding: EdgeInsets.zero,
//           constraints: BoxConstraints(minWidth: 30, minHeight: 30),
//         ),
//         if (label != null && label!.isNotEmpty)
//           Text(
//             label!,
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: fontSize,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//       ],
//     );
//   }
// }
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoFullScreenPage(
          videoController: widget.videoController,
          username: widget.username,
          userAvatar: widget.userAvatar,
          caption: widget.caption,
          likes: widget.likes,
          comments: widget.comments,
          postId: widget.postId,
          userId: widget.userId,
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

// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'video_full_screen_page.dart';

// class VideoPost extends StatefulWidget {
//   final VideoPlayerController? videoController;
//   final String username;
//   final String userAvatar;
//   final String caption;
//   final int likes;
//   final int comments;
//   final String postId;
//   final String userId;
//   final String? currentUserId;

//   const VideoPost({
//     this.videoController,
//     this.username = '',
//     this.userAvatar = '',
//     this.caption = '',
//     this.likes = 0,
//     this.comments = 0,
//     required this.postId,
//     required this.userId,
//     this.currentUserId,
//   });

//   @override
//   _VideoPostState createState() => _VideoPostState();
// }

// class _VideoPostState extends State<VideoPost> {
//   bool _showVideoControls = false;
//   bool _controlsHovered = false;

//   @override
//   void initState() {
//     super.initState();
//     // Auto-play the video when the widget is initialized
//     if (widget.videoController != null && 
//         widget.videoController!.value.isInitialized &&
//         !widget.videoController!.value.isPlaying) {
//       widget.videoController!.play();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.videoController == null ||
//         !widget.videoController!.value.isInitialized) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return GestureDetector(
//       onTap: () {
//         _openFullScreen(context);
//       },
//       child: MouseRegion(
//         onEnter: (_) => setState(() => _controlsHovered = true),
//         onExit: (_) => setState(() => _controlsHovered = false),
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             AspectRatio(
//               aspectRatio: 16 / 9,
//               child: ClipRect(
//                 child: FittedBox(
//                   fit: BoxFit.cover,
//                   child: SizedBox(
//                     width: widget.videoController!.value.size.width,
//                     height: widget.videoController!.value.size.height,
//                     child: VideoPlayer(widget.videoController!),
//                   ),
//                 ),
//               ),
//             ),
            
//             // Video controls (always visible)
//             Positioned.fill(
//               child: Container(
//                 color: Colors.black.withOpacity(0.3),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8.0,
//                         vertical: 8.0,
//                       ),
//                       child: Row(
//                         children: [
//                           IconButton(
//                             icon: Icon(
//                               widget.videoController!.value.isPlaying
//                                   ? Icons.pause
//                                   : Icons.play_arrow,
//                               size: 24,
//                               color: Colors.white,
//                             ),
//                             onPressed: _togglePlayPause,
//                           ),
//                           Expanded(
//                             child: VideoProgressIndicator(
//                               widget.videoController!,
//                               allowScrubbing: true,
//                               colors: const VideoProgressColors(
//                                 playedColor: Colors.blue,
//                                 bufferedColor: Colors.grey,
//                                 backgroundColor: Colors.grey,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _togglePlayPause() {
//     if (widget.videoController!.value.isPlaying) {
//       widget.videoController!.pause();
//     } else {
//       widget.videoController!.play();
//     }
//     setState(() {}); // Update the UI to reflect the new state
//   }

//   void _openFullScreen(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => VideoFullScreenPage(
//           videoController: widget.videoController,
//           username: widget.username,
//           userAvatar: widget.userAvatar,
//           caption: widget.caption,
//           likes: widget.likes,
//           comments: widget.comments,
//           postId: widget.postId,
//           userId: widget.userId,
//         ),
//         fullscreenDialog: true,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }
// }