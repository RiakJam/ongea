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
  final String initialPostId; // Only need the post ID to start with

  const VideoFullScreenPage({
    required this.initialPostId,
  });

  @override
  _VideoFullScreenPageState createState() => _VideoFullScreenPageState();
}

class _VideoFullScreenPageState extends State<VideoFullScreenPage> {
  // New properties for infinite scrolling
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _videos = [];
  bool _isLoadingMore = false;
  bool _hasMoreVideos = true;
  String? _lastPostKey;
  Map<String, VideoPlayerController> _videoControllers = {};
  int _currentVideoIndex = 0;

  // Existing properties
  bool _showVideoControls = true;
  bool _isUserPaused = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  User? get _currentUser => _auth.currentUser;
  String? get _currentUserId => _currentUser?.uid;

  // Local state for instant feedback - now for current video
  bool _localIsLiked = false;
  bool _localIsSaved = false;
  bool _localIsFollowing = false;
  int _localLikes = 0;
  int _localComments = 0;
  int _localGifts = 0;
  int _localShares = 0;

  // Stream subscriptions - will be updated when video changes
  StreamSubscription<DatabaseEvent>? _likeSubscription;
  StreamSubscription<DatabaseEvent>? _saveSubscription;
  StreamSubscription<DatabaseEvent>? _followSubscription;
  StreamSubscription<DatabaseEvent>? _giftSubscription;
  StreamSubscription<DatabaseEvent>? _shareSubscription;
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<DatabaseEvent>? _postSubscription;

  @override
  void initState() {
    super.initState();

    // Start by loading the initial post data
    _loadInitialPostData();
    
    // Listen for auth state changes
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _cancelSubscriptions();
          if (_videos.isNotEmpty) {
            _initializeFirebaseListeners();
          }
        });
      }
    });
  }

  Future<void> _loadInitialPostData() async {
    try {
      // Fetch the initial post data from Firebase
      final postSnapshot = await _database.child('posts/${widget.initialPostId}').get();
      
      if (postSnapshot.exists && postSnapshot.value != null) {
        final post = Map<String, dynamic>.from(postSnapshot.value as Map);
        
        // Get user data for this post
        final userData = await _getUserData(post['userId'] ?? '');
        
        // Add the initial video to the list
        _videos.add({
          'videoUrl': post['videoUrl'],
          'userName': userData['userName'] ?? post['userName'] ?? 'Unknown User',
          'userAvatar': userData['avatarUrl'] ?? post['userAvatar'] ?? '',
          'caption': post['caption'] ?? '',
          'likes': (post['likes'] is int) ? post['likes'] : 0,
          'comments': (post['comments'] is Map) ? post['comments'].length : 0,
          'postId': widget.initialPostId,
          'userId': post['userId'] ?? '',
        });
        
        // Initialize video controller for the first video
        _initializeVideoController(0);
        
        // Initialize Firebase listeners for the first video
        _initializeFirebaseListeners();
        
        // Load more videos
        _loadMoreVideos();
      }
    } catch (e) {
      print('Error loading initial post data: $e');
    }
  }
// here 
Future<void> _loadMoreVideos() async {
  if (_isLoadingMore || !_hasMoreVideos) return;

  setState(() {
    _isLoadingMore = true;
  });

  try {
    // Get all posts to select randomly
    final allPostsSnapshot = await _database.child('posts').get();
    if (allPostsSnapshot.value == null) {
      setState(() {
        _hasMoreVideos = false;
      });
      return;
    }

    final allPosts = Map<dynamic, dynamic>.from(allPostsSnapshot.value as Map);
    
    // Filter for video posts and exclude already loaded ones
    final videoPosts = allPosts.entries.where((entry) {
      final post = Map<String, dynamic>.from(entry.value);
      final isVideo = post['mediaType'] == 'video' && post['videoUrl'] != null;
      final notLoaded = !_videos.any((v) => v['postId'] == entry.key);
      return isVideo && notLoaded;
    }).toList();

    // If no more videos available
    if (videoPosts.isEmpty) {
      setState(() {
        _hasMoreVideos = false;
      });
      return;
    }

    // Shuffle the available videos for randomness
    videoPosts.shuffle();

    // Limit to 10 posts per load
    final postsToLoad = videoPosts.take(10).toList();
    
    final List<Map<String, dynamic>> videoList = [];

    for (var postEntry in postsToLoad) {
      final key = postEntry.key;
      final value = postEntry.value;
      final post = Map<String, dynamic>.from(value);

      // Get user data for this post
      final userData = await _getUserData(post['userId'] ?? '');

      videoList.add({
        'videoUrl': post['videoUrl'],
        'userName': userData['userName'] ?? post['userName'] ?? 'Unknown User',
        'userAvatar': userData['avatarUrl'] ?? post['userAvatar'] ?? '',
        'caption': post['caption'] ?? '',
        'likes': (post['likes'] is int) ? post['likes'] : 0,
        'comments': (post['comments'] is Map) ? post['comments'].length : 0,
        'postId': key,
        'userId': post['userId'] ?? '',
      });
    }

    setState(() {
      _videos.addAll(videoList);
      
      // Initialize video controllers for new videos
      for (int i = _videos.length - videoList.length; i < _videos.length; i++) {
        _initializeVideoController(i);
      }
    });

  } catch (e) {
    print('Error loading more videos: $e');
  } finally {
    setState(() {
      _isLoadingMore = false;
    });
  }
}

  // Helper method to get user data from Firebase
  Future<Map<String, dynamic>> _getUserData(String userId) async {
    if (userId.isEmpty) return {};

    try {
      final userSnapshot = await _database.child('users/$userId').get();
      if (userSnapshot.exists && userSnapshot.value != null) {
        return Map<String, dynamic>.from(userSnapshot.value as Map);
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }

    return {};
  }
// maybe here 
  void _initializeVideoController(int index) {
    final video = _videos[index];
    final String videoUrl = video['videoUrl'] ?? '';
    final String postId = video['postId'];

    if (videoUrl.isEmpty) return;

    // If we already have a controller for this video, don't create a new one
    if (_videoControllers.containsKey(postId)) {
      return;
    }

    // Create a new controller
    try {
      final controller = VideoPlayerController.network(videoUrl);
      _videoControllers[postId] = controller;

      controller
          .initialize()
          .then((_) {
            if (mounted) {
              setState(() {});
            }
            controller.setLooping(true);

            // Play the video immediately if it's the current one
            if (index == _currentVideoIndex) {
              controller.play();
            }
          })
          .catchError((error) {
            print('Error initializing video controller: $error');
          });
    } catch (e) {
      print('Error creating video controller: $e');
    }
  }

  void _initializeFirebaseListeners() {
    if (_videos.isEmpty) return;

    final currentVideo = _videos[_currentVideoIndex];
    final currentPostId = currentVideo['postId'];

    // Cancel any existing subscriptions
    _cancelSubscriptions();

    // Listen for post updates
    _postSubscription = _database.child('posts/$currentPostId').onValue.listen((
      event,
    ) {
      if (mounted && event.snapshot.value != null) {
        final postData = Map<String, dynamic>.from(event.snapshot.value as Map);
        final videoUrl = postData['videoUrl'];

        // If video URL changed and we don't have a controller yet, initialize it
        if (videoUrl is String &&
            videoUrl.isNotEmpty &&
            !_videoControllers.containsKey(currentPostId)) {
          _initializeVideoController(_currentVideoIndex);
        }
      }
    });

    // Listen for like status
    if (_currentUserId != null) {
      _likeSubscription = _database
          .child('userLikes/$_currentUserId/$currentPostId')
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
          .child('userSaves/$_currentUserId/$currentPostId')
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
          .child('userFollows/$_currentUserId/${currentVideo['userId']}')
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
    _database.child('posts/$currentPostId/likes').onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          _localLikes = (event.snapshot.value as num).toInt();
        });
      }
    });

    // Listen for comment count
    _database.child('posts/$currentPostId/comments').onValue.listen((event) {
      if (mounted && event.snapshot.value is Map) {
        setState(() {
          _localComments = (event.snapshot.value as Map).length;
        });
      }
    });

    // Listen for gift count
    _database.child('gifts/$currentPostId').onValue.listen((event) {
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
    _database.child('posts/$currentPostId/shares').onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          _localShares = (event.snapshot.value as num).toInt();
        });
      }
    });
  }

  void _cancelSubscriptions() {
    _postSubscription?.cancel();
    _likeSubscription?.cancel();
    _saveSubscription?.cancel();
    _followSubscription?.cancel();
    _giftSubscription?.cancel();
    _shareSubscription?.cancel();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cancelSubscriptions();
    _authStateSubscription?.cancel();

    // Dispose all video controllers
    _videoControllers.forEach((key, controller) {
      controller.dispose();
    });

    super.dispose();
  }

  Future<void> _handleLike() async {
    if (_currentUserId == null) {
      _showLoginRequiredModal(context);
      return;
    }

    final currentPostId = _videos[_currentVideoIndex]['postId'];

    try {
      final postRef = _database.child('posts/$currentPostId');
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
        'userLikes/$_currentUserId/$currentPostId',
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

    final currentPostId = _videos[_currentVideoIndex]['postId'];

    try {
      final userSavesRef = _database.child(
        'userSaves/$_currentUserId/$currentPostId',
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

    final currentVideo = _videos[_currentVideoIndex];
    final currentUserId = currentVideo['userId'];

    if (currentUserId == _currentUserId) return;

    try {
      final userFollowsRef = _database.child(
        'userFollows/$_currentUserId/$currentUserId',
      );
      final followSnapshot = await userFollowsRef.get();
      final isFollowing = followSnapshot.exists;

      if (isFollowing) {
        await userFollowsRef.remove();
        await _database
            .child('users/$currentUserId/followersCount')
            .set(ServerValue.increment(-1));
        await _database
            .child('users/$_currentUserId/followingCount')
            .set(ServerValue.increment(-1));
      } else {
        await userFollowsRef.set(ServerValue.timestamp);
        await _database
            .child('users/$currentUserId/followersCount')
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
    if (_currentUserId == null) {
      _showLoginRequiredModal(context);
      return;
    }

    final currentVideo = _videos[_currentVideoIndex];

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GiftPage(
            recipientName: currentVideo['userName'],
            recipientAvatar: currentVideo['userAvatar'],
            recipientId: currentVideo['userId'],
            postId: currentVideo['postId'],
          ),
        ),
      );

      // Refresh gift count after returning from gift page
      final giftSnapshot = await _database
          .child('gifts/${currentVideo['postId']}')
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
    final currentPostId = _videos[_currentVideoIndex]['postId'];
    final String postUrl = 'https://yourapp.com/post/$currentPostId';

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
    final currentPostId = _videos[_currentVideoIndex]['postId'];

    try {
      final postRef = _database.child('posts/$currentPostId');
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

  void _togglePlayPause(int index) {
    final controller = _videoControllers[_videos[index]['postId']];
    if (controller != null) {
      if (controller.value.isPlaying) {
        controller.pause();
        setState(() {
          _isUserPaused = true;
        });
      } else {
        controller.play();
        setState(() {
          _isUserPaused = false;
        });
      }
    }
  }

  void _navigateToUserProfile(String userId) {
    if (userId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              UserProfilePage(userId: userId, currentUserId: _currentUserId),
        ),
      );
    }
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

  Widget _buildVideoItem(int index) {
    final video = _videos[index];
    final VideoPlayerController? controller =
        _videoControllers[video['postId']];
    final bool isInitialized =
        controller != null && controller.value.isInitialized;
    final bool isCurrentVideo = index == _currentVideoIndex;

    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.black,
      child: Stack(
        children: [
          // Video player - Centered
          Center(
            child: isInitialized
                ? AspectRatio(
                    aspectRatio: controller!.value.aspectRatio,
                    child: VideoPlayer(controller),
                  )
                : Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
          ),

          // Video overlay with controls and info
          _buildVideoOverlay(video, index, isCurrentVideo),
        ],
      ),
    );
  }

  Widget _buildVideoOverlay(
    Map<String, dynamic> video,
    int index,
    bool isCurrentVideo,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 600;
    final iconSize = isSmallScreen ? 20.0 : 28.0;
    final buttonSpacing = isSmallScreen ? 8.0 : 12.0;
    final fontSize = isSmallScreen ? 10.0 : 12.0;

    final VideoPlayerController? controller =
        _videoControllers[video['postId']];
    final bool isPlaying = controller != null && controller.value.isPlaying;

    final isOwnPost = _currentUserId?.trim() == video['userId'].trim();
    final shouldShowFollowButton =
        _currentUserId == null || (!isOwnPost && !_localIsFollowing);

    return Stack(
      children: [
        // User info - Show on all videos
        Positioned(
          left: 16,
          bottom: 130.0,
          right: screenWidth * 0.4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _navigateToUserProfile(video['userId']),
                child: CircleAvatar(
                  backgroundImage: video['userAvatar'].isNotEmpty
                      ? NetworkImage(video['userAvatar'])
                      : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                  radius: isSmallScreen ? 16.0 : 20.0,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: GestureDetector(
                  onTap: () => _navigateToUserProfile(video['userId']),
                  child: Text(
                    video['userName'],
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
                        color: _localIsFollowing ? Colors.grey : Colors.blue,
                        fontSize: isSmallScreen ? 12.0 : 14.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Caption - Show on all videos
        Positioned(
          left: 16,
          bottom: 80.0,
          right: screenWidth * 0.4,
          child: Text(
            video['caption'],
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 12.0 : 14.0,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Action buttons (right side) - only show for current video
        if (isCurrentVideo)
          Positioned(
            right: 12,
            bottom: 100.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CompactActionButton(
                  icon: _localIsLiked ? Icons.favorite : Icons.favorite_border,
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
                          CommentSection(postId: video['postId']),
                    );
                  },
                  iconSize: iconSize,
                  fontSize: fontSize,
                ),
                SizedBox(height: buttonSpacing),
                _CompactActionButton(
                  icon: _localIsSaved ? Icons.bookmark : Icons.bookmark_border,
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

        // Video controls (always visible for current video)
        if (isCurrentVideo &&
            controller != null &&
            controller.value.isInitialized)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: [
                  VideoProgressIndicator(
                    controller,
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
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: isSmallScreen ? 18.0 : 22.0,
                        ),
                        onPressed: () => _togglePlayPause(index),
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
                          '${_formatDuration(controller.value.position)} / ${_formatDuration(controller.value.duration)}',
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        itemCount: _videos.length + (_hasMoreVideos ? 1 : 0),
        onPageChanged: (int index) {
          if (index < _videos.length) {
            // Pause previous video
            if (_currentVideoIndex < _videos.length) {
              final prevController =
                  _videoControllers[_videos[_currentVideoIndex]['postId']];
              if (prevController != null && prevController.value.isPlaying) {
                prevController.pause();
              }
            }

            // Play new video
            final newController = _videoControllers[_videos[index]['postId']];
            if (newController != null && !newController.value.isPlaying) {
              newController.play();
            }

            setState(() {
              _currentVideoIndex = index;
            });

            // Update Firebase listeners for the new video
            _initializeFirebaseListeners();

            // Load more videos if we're near the end
            if (index >= _videos.length - 2 &&
                _hasMoreVideos &&
                !_isLoadingMore) {
              _loadMoreVideos();
            }
          }
        },
        itemBuilder: (context, index) {
          if (index < _videos.length) {
            return _buildVideoItem(index);
          } else {
            // Loading indicator at the bottom
            return Container(
              height: MediaQuery.of(context).size.height,
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            );
          }
        },
      ),
    );
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