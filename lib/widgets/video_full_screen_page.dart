import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'comment_section.dart';
import '../services/gift_page.dart';
import '../login_page.dart';
import '../pages/user_profile_page.dart';

class VideoFullScreenPage extends StatefulWidget {
  final VideoPlayerController? videoController;
  final String username;
  final String userAvatar;
  final String caption;
  final int likes;
  final int comments;
  final String postId;
  final String userId;

  const VideoFullScreenPage({
    this.videoController,
    this.username = '',
    this.userAvatar = '',
    this.caption = '',
    this.likes = 0,
    this.comments = 0,
    required this.postId,
    required this.userId,
  });

  @override
  _VideoFullScreenPageState createState() => _VideoFullScreenPageState();
}

class _VideoFullScreenPageState extends State<VideoFullScreenPage> {
  bool _showVideoControls = true;
  bool _isUserPaused = false;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Current user from Firebase Auth (not from widget)
  User? get _currentUser => _auth.currentUser;
  String? get _currentUserId => _currentUser?.uid;

  // Local state for instant feedback
  bool _localIsLiked = false;
  bool _localIsSaved = false;
  bool _localIsFollowing = false;
  int _localLikes = 0;
  int _localComments = 0;
  int _localGifts = 0;
  int _localShares = 0;

  // Stream subscriptions
  StreamSubscription<DatabaseEvent>? _likeSubscription;
  StreamSubscription<DatabaseEvent>? _saveSubscription;
  StreamSubscription<DatabaseEvent>? _followSubscription;
  StreamSubscription<DatabaseEvent>? _giftSubscription;
  StreamSubscription<DatabaseEvent>? _shareSubscription;
  StreamSubscription<User?>? _authStateSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize local state with widget values
    _localLikes = widget.likes;
    _localComments = widget.comments;

    // Start playing the video when entering full screen
    if (widget.videoController != null &&
        !widget.videoController!.value.isPlaying) {
      widget.videoController!.play();
    }

    // Listen for auth state changes
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          // Reinitialize Firebase listeners when auth state changes
          _cancelSubscriptions();
          _initializeFirebaseListeners();
        });
      }
    });

    // Initialize Firebase listeners
    _initializeFirebaseListeners();
  }

  void _initializeFirebaseListeners() {
    // Listen for like status
    if (_currentUserId != null) {
      _likeSubscription = _database
          .child('userLikes/$_currentUserId/${widget.postId}')
          .onValue
          .listen((event) {
            if (mounted) {
              setState(() {
                _localIsLiked = event.snapshot.value != null;
              });
            }
          });
    }

    // Listen for save status
    if (_currentUserId != null) {
      _saveSubscription = _database
          .child('userSaves/$_currentUserId/${widget.postId}')
          .onValue
          .listen((event) {
            if (mounted) {
              setState(() {
                _localIsSaved = event.snapshot.value != null;
              });
            }
          });
    }

    // Listen for follow status
    if (_currentUserId != null) {
      _followSubscription = _database
          .child('userFollows/$_currentUserId/${widget.userId}')
          .onValue
          .listen((event) {
            if (mounted) {
              setState(() {
                _localIsFollowing = event.snapshot.value != null;
              });
            }
          });
    }

    // Listen for like count
    _database.child('posts/${widget.postId}/likes').onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          _localLikes = (event.snapshot.value as num).toInt();
        });
      }
    });

    // Listen for comment count
    _database.child('posts/${widget.postId}/comments').onValue.listen((event) {
      if (mounted && event.snapshot.value is Map) {
        setState(() {
          _localComments = (event.snapshot.value as Map).length;
        });
      }
    });

    // Listen for gift count
    _database.child('gifts/${widget.postId}').onValue.listen((event) {
      if (mounted && event.snapshot.value is Map) {
        int totalGifts = 0;
        (event.snapshot.value as Map).forEach((key, value) {
          if (value is int) {
            totalGifts += value;
          }
        });
        setState(() {
          _localGifts = totalGifts;
        });
      }
    });

    // Listen for share count
    _database.child('posts/${widget.postId}/shares').onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          _localShares = (event.snapshot.value as num).toInt();
        });
      }
    });
  }

  void _cancelSubscriptions() {
    _likeSubscription?.cancel();
    _saveSubscription?.cancel();
    _followSubscription?.cancel();
    _giftSubscription?.cancel();
    _shareSubscription?.cancel();
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    _cancelSubscriptions();
    _authStateSubscription?.cancel();

    // Pause video when leaving full screen
    if (widget.videoController != null &&
        widget.videoController!.value.isPlaying) {
      widget.videoController!.pause();
    }
    super.dispose();
  }

  Future<void> _handleLike() async {
    if (_currentUserId == null) {
      _showLoginRequiredModal(context);
      return;
    }

    try {
      final postRef = _database.child('posts/${widget.postId}');
      final postSnapshot = await postRef.get();
      if (!postSnapshot.exists) return;

      final postData = postSnapshot.value;
      if (postData is! Map<dynamic, dynamic>) return;

      final post = Map<String, dynamic>.from(postData);
      final currentLikes = (post['likes'] is int ? post['likes'] as int : 0);
      final isLiked = _localIsLiked;

      await postRef.update({
        'likes': isLiked ? currentLikes - 1 : currentLikes + 1,
      });

      final userLikesRef = _database.child(
        'userLikes/$_currentUserId/${widget.postId}',
      );
      if (isLiked) {
        await userLikesRef.remove();
      } else {
        await userLikesRef.set(true);
      }

      if (mounted) {
        setState(() {
          _localIsLiked = !isLiked;
          _localLikes = isLiked ? currentLikes - 1 : currentLikes + 1;
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error toggling like: $e')));
      }
    }
  }

  Future<void> _handleSave() async {
    if (_currentUserId == null) {
      _showLoginRequiredModal(context);
      return;
    }

    try {
      final userSavesRef = _database.child(
        'userSaves/$_currentUserId/${widget.postId}',
      );
      final saveSnapshot = await userSavesRef.get();
      final isSaved = saveSnapshot.exists && saveSnapshot.value == true;

      if (isSaved) {
        await userSavesRef.remove();
      } else {
        await userSavesRef.set(true);
      }

      if (mounted) {
        setState(() {
          _localIsSaved = !isSaved;
        });
      }
    } catch (e) {
      print('Error toggling save: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error toggling save: $e')));
      }
    }
  }

  Future<void> _handleFollow() async {
    if (_currentUserId == null) {
      _showLoginRequiredModal(context);
      return;
    }

    if (widget.userId == _currentUserId) return;

    try {
      final userFollowsRef = _database.child(
        'userFollows/$_currentUserId/${widget.userId}',
      );
      final followSnapshot = await userFollowsRef.get();
      final isFollowing = followSnapshot.exists;

      if (isFollowing) {
        await userFollowsRef.remove();
        await _database
            .child('users/${widget.userId}/followersCount')
            .set(ServerValue.increment(-1));
        await _database
            .child('users/$_currentUserId/followingCount')
            .set(ServerValue.increment(-1));
      } else {
        await userFollowsRef.set(ServerValue.timestamp);
        await _database
            .child('users/${widget.userId}/followersCount')
            .set(ServerValue.increment(1));
        await _database
            .child('users/$_currentUserId/followingCount')
            .set(ServerValue.increment(1));
      }

      if (mounted) {
        setState(() {
          _localIsFollowing = !isFollowing;
        });
      }
    } catch (e) {
      print('Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error toggling follow: $e')));
      }
    }
  }

  Future<void> _handleGift() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GiftPage(
            recipientName: widget.username,
            recipientAvatar: widget.userAvatar,
            recipientId: widget.userId,
            postId: widget.postId,
          ),
        ),
      );

      // Refresh gift count after returning from gift page
      final giftSnapshot = await _database
          .child('gifts/${widget.postId}')
          .get();
      if (giftSnapshot.value is Map) {
        int totalGifts = 0;
        (giftSnapshot.value as Map).forEach((key, value) {
          if (value is int) {
            totalGifts += value;
          }
        });
        if (mounted) {
          setState(() {
            _localGifts = totalGifts;
          });
        }
      }
    } catch (e) {
      print('Error sending gift: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending gift: $e')));
      }
    }
  }

  Future<void> _handleShare() async {
    _showShareOptions(context);
  }

  void _showShareOptions(BuildContext context) {
    final List<Map<String, dynamic>> platforms = [
      {
        'icon': FontAwesomeIcons.link,
        'name': 'Copy Link',
        'color': Colors.blue,
        'onTap': () => _copyLinkToClipboard(context),
      },
      {
        'icon': FontAwesomeIcons.facebook,
        'name': 'Facebook',
        'color': Color(0xFF1877F2),
        'onTap': () => _showNotImplementedMessage(context, 'Facebook'),
      },
      {
        'icon': FontAwesomeIcons.whatsapp,
        'name': 'WhatsApp',
        'color': Color(0xFF25D366),
        'onTap': () => _showNotImplementedMessage(context, 'WhatsApp'),
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (_) => SizedBox(
        height: 160,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Share to',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: platforms.map((platform) {
                    return GestureDetector(
                      onTap: () {
                        if (platform['onTap'] != null) {
                          platform['onTap']();
                        }
                      },
                      child: Container(
                        width: 80,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  platform['color'] as Color? ??
                                  Colors.grey[300],
                              radius: 24,
                              child: Icon(
                                platform['icon'] as IconData,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              platform['name'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyLinkToClipboard(BuildContext context) {
    Navigator.pop(context);
    final String postUrl = 'https://yourapp.com/post/${widget.postId}';

    // Update share count
    _updateShareCount();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied to clipboard: $postUrl'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _updateShareCount() async {
    try {
      final postRef = _database.child('posts/${widget.postId}');
      final postSnapshot = await postRef.get();
      if (!postSnapshot.exists) return;

      final postData = postSnapshot.value;
      if (postData is! Map<dynamic, dynamic>) return;

      final post = Map<String, dynamic>.from(postData);
      final currentShares = (post['shares'] is int ? post['shares'] as int : 0);

      await postRef.update({'shares': currentShares + 1});

      if (mounted) {
        setState(() {
          _localShares = currentShares + 1;
        });
      }
    } catch (e) {
      print('Error updating share count: $e');
    }
  }

  void _showNotImplementedMessage(BuildContext context, String featureName) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName sharing will be implemented soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showLoginRequiredModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Required'),
          content: Text('You need to log in to perform this action.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to login page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Login'),
            ),
          ],
        );
      },
    );
  }

  void _togglePlayPause() {
    setState(() {
      _isUserPaused = !_isUserPaused;
    });

    if (_isUserPaused) {
      widget.videoController!.pause();
    } else {
      widget.videoController!.play();
    }
  }

  void _navigateToUserProfile() {
    if (widget.userId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfilePage(
            userId: widget.userId,
            currentUserId: _currentUserId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoController == null ||
        !widget.videoController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final isSmallScreen = screenHeight < 600;
    final iconSize = isSmallScreen ? 20.0 : 28.0;
    final buttonSpacing = isSmallScreen ? 8.0 : 12.0;
    final fontSize = isSmallScreen ? 10.0 : 12.0;

    final isOwnPost = _currentUserId?.trim() == widget.userId.trim();
    final shouldShowFollowButton =
        _currentUserId == null || (!isOwnPost && !_localIsFollowing);

    return GestureDetector(
      onTap: () {
        // Keep controls always visible, no need to toggle
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: widget.videoController!.value.aspectRatio,
                child: VideoPlayer(widget.videoController!),
              ),
            ),

            // User info
            Positioned(
              left: 16,
              bottom: 130.0,
              right: screenWidth * 0.4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _navigateToUserProfile,
                    child: CircleAvatar(
                      backgroundImage: widget.userAvatar.isNotEmpty
                          ? NetworkImage(widget.userAvatar)
                          : const AssetImage('assets/default_avatar.png')
                                as ImageProvider,
                      radius: isSmallScreen ? 16.0 : 20.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: GestureDetector(
                      onTap: _navigateToUserProfile,
                      child: Text(
                        widget.username,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14.0 : 16.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (shouldShowFollowButton)
                    Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: TextButton(
                        onPressed: _handleFollow,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6.0 : 8.0,
                            vertical: isSmallScreen ? 2.0 : 4.0,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          _localIsFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            color: _localIsFollowing
                                ? Colors.grey
                                : Colors.blue,
                            fontSize: isSmallScreen ? 12.0 : 14.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Caption
            Positioned(
              left: 16,
              bottom: 80.0,
              right: screenWidth * 0.4,
              child: Text(
                widget.caption,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 12.0 : 14.0,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Action buttons (right side)
            Positioned(
              right: 12,
              bottom: 100.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CompactActionButton(
                    icon: _localIsLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: _formatNumber(_localLikes),
                    color: _localIsLiked ? Colors.blue : Colors.white,
                    onTap: _handleLike,
                    iconSize: iconSize,
                    fontSize: fontSize,
                  ),
                  SizedBox(height: buttonSpacing),
                  _CompactActionButton(
                    icon: Icons.comment,
                    label: _formatNumber(_localComments),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) =>
                            CommentSection(postId: widget.postId),
                      );
                    },
                    iconSize: iconSize,
                    fontSize: fontSize,
                  ),
                  SizedBox(height: buttonSpacing),
                  _CompactActionButton(
                    icon: _localIsSaved
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    label: '',
                    color: _localIsSaved ? Colors.blue : Colors.white,
                    onTap: _handleSave,
                    iconSize: iconSize,
                    fontSize: fontSize,
                  ),
                  SizedBox(height: buttonSpacing),
                  _CompactActionButton(
                    icon: Icons.card_giftcard,
                    label: _formatNumber(_localGifts),
                    onTap: _handleGift,
                    iconSize: iconSize,
                    fontSize: fontSize,
                  ),
                  SizedBox(height: buttonSpacing),
                  _CompactActionButton(
                    icon: Icons.share,
                    label: _formatNumber(_localShares),
                    onTap: _handleShare,
                    iconSize: iconSize,
                    fontSize: fontSize,
                  ),
                ],
              ),
            ),

            // Video controls (always visible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    VideoProgressIndicator(
                      widget.videoController!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.blue,
                        bufferedColor: Colors.grey,
                        backgroundColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isUserPaused ? Icons.play_arrow : Icons.pause,
                            color: Colors.white,
                            size: isSmallScreen ? 18.0 : 22.0,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.volume_up,
                            color: Colors.white,
                            size: isSmallScreen ? 18.0 : 22.0,
                          ),
                          onPressed: () {},
                        ),
                        Expanded(
                          child: Text(
                            '${_formatDuration(widget.videoController!.value.position)} / ${_formatDuration(widget.videoController!.value.duration)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 10.0 : 12.0,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.fullscreen_exit,
                            color: Colors.white,
                            size: isSmallScreen ? 18.0 : 22.0,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Back button
            Positioned(
              top: 40.0,
              left: 12.0,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: isSmallScreen ? 24.0 : 28.0,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;
  final double iconSize;
  final double fontSize;

  const _CompactActionButton({
    required this.icon,
    this.label,
    this.color = Colors.white,
    required this.onTap,
    this.iconSize = 24.0,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: color, size: iconSize),
          onPressed: onTap,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 30, minHeight: 30),
        ),
        if (label != null && label!.isNotEmpty)
          Text(
            label!,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
