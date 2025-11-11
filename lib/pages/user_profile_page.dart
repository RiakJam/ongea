import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
// Import your post components
import '../widgets/post_card.dart';
import '../services/gift_page.dart';
import '../pages/chat_detail_page.dart'; // Import the chat detail page

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String? currentUserId;

  const UserProfilePage({required this.userId, this.currentUserId, Key? key})
    : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;
  List<Map<String, dynamic>> _userPosts = [];

  // For interactions
  final Map<String, int> _giftCounts = {};
  final Map<String, int> _commentCounts = {};
  final Map<String, int> _shareCounts = {};
  final Map<String, int> _likeCounts = {};
  final Map<String, bool> _hasGifted = {};
  final Map<String, bool> _likedPosts = {};
  final Map<String, bool> _savedPosts = {};
  final Map<String, bool> _followingUsers = {};

  // For video posts
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, GlobalKey> _videoKeys = {};
  final Map<String, bool> _videoInitialized = {};
  String? _currentlyPlayingPostId;
  final Map<String, bool> _userPausedVideos = {};
  
  // For scroll and visibility detection
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;
  final Map<String, bool> _isVideoVisible = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadUserData();
    _checkIfFollowing();
    _loadUserPosts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    // Dispose all video controllers
    _videoControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  void _handleScroll() {
    // Debounce scroll events to avoid performance issues
    if (_isScrolling) return;
    
    _isScrolling = true;
    
    // Check visibility after scroll ends
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        _checkVideoVisibility();
        _isScrolling = false;
      }
    });
  }

  void _checkVideoVisibility() {
    final RenderObject? rootRenderObject = context.findRenderObject();
    if (rootRenderObject == null) return;
    
    final ScrollableState? scrollableState = Scrollable.of(context);
    if (scrollableState == null) return;
    
    final RenderBox renderBox = rootRenderObject as RenderBox;
    final Size size = renderBox.size;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    
    final viewport = Rect.fromPoints(
      position,
      position + Offset(size.width, size.height),
    );
    
    // Find which video is most centered in the viewport
    String? mostCenteredPostId;
    double maxVisibility = 0;
    
    for (var post in _userPosts) {
      final postKey = post['key'];
      if (post['mediaType'] != 'video') continue;
      
      final GlobalKey? videoKey = _videoKeys[postKey];
      if (videoKey?.currentContext == null) continue;
      
      final RenderObject? videoRenderObject = videoKey!.currentContext?.findRenderObject();
      if (videoRenderObject == null) continue;
      
      final RenderBox videoBox = videoRenderObject as RenderBox;
      final Offset videoPosition = videoBox.localToGlobal(Offset.zero);
      final videoRect = Rect.fromPoints(
        videoPosition,
        videoPosition + Offset(videoBox.size.width, videoBox.size.height),
      );
      
      // Calculate intersection with viewport
      final intersection = viewport.intersect(videoRect);
      if (intersection.isEmpty) {
        _isVideoVisible[postKey] = false;
        continue;
      }
      
      final visibleArea = intersection.width * intersection.height;
      final totalArea = videoBox.size.width * videoBox.size.height;
      final visibilityRatio = visibleArea / totalArea;
      
      _isVideoVisible[postKey] = visibilityRatio > 0.5;
      
      // Track the most visible video
      if (visibilityRatio > maxVisibility) {
        maxVisibility = visibilityRatio;
        mostCenteredPostId = postKey;
      }
    }
    
    // Play the most centered video, pause others
    _playCenteredVideo(mostCenteredPostId);
  }

  void _playCenteredVideo(String? postIdToPlay) {
    // If user manually paused a video, don't auto-play
    if (postIdToPlay != null && _userPausedVideos[postIdToPlay] == true) {
      return;
    }
    
    for (var post in _userPosts) {
      final postKey = post['key'];
      if (post['mediaType'] != 'video') continue;
      
      final controller = _videoControllers[postKey];
      if (controller == null) continue;
      
      if (postKey == postIdToPlay && _isVideoControllerInitialized(postKey)) {
        if (!controller.value.isPlaying) {
          controller.play();
          setState(() {
            _currentlyPlayingPostId = postKey;
          });
        }
      } else {
        if (controller.value.isPlaying) {
          controller.pause();
        }
      }
    }
  }

  void _loadUserData() async {
    try {
      // Load user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
        });
      }

      // Load followers count from Realtime Database
      final followersSnapshot = await _database
          .child('userFollowers/${widget.userId}')
          .get();
      if (followersSnapshot.exists) {
        setState(() {
          _followersCount = (followersSnapshot.value as Map).length;
        });
      }

      // Load following count from Realtime Database
      final followingSnapshot = await _database
          .child('userFollows/${widget.userId}')
          .get();
      if (followingSnapshot.exists) {
        setState(() {
          _followingCount = (followingSnapshot.value as Map).length;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _loadUserPosts() async {
    try {
      final postsSnapshot = await _database
          .child('posts')
          .orderByChild('userId')
          .equalTo(widget.userId)
          .get();

      if (postsSnapshot.exists) {
        final postsData = postsSnapshot.value as Map<dynamic, dynamic>;
        final postsList = postsData.entries.map((entry) {
          final post = Map<String, dynamic>.from(entry.value as Map);
          post['key'] = entry.key;
          return post;
        }).toList();

        // Sort by timestamp descending (newest first)
        postsList.sort(
          (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0),
        );

        setState(() {
          _userPosts = postsList;
          _postsCount = postsList.length;
        });

        // Initialize video controllers for video posts
        _initializeVideoControllers(postsList);

        // Load interactions for EVERYONE (not just logged-in users)
        _loadInteractions();
      } else {
        setState(() {
          _userPosts = [];
          _postsCount = 0;
        });
      }
    } catch (e) {
      print('Error loading user posts: $e');
      setState(() {
        _userPosts = [];
        _postsCount = 0;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeVideoControllers(List<Map<String, dynamic>> postsList) {
    for (var post in postsList) {
      final postKey = post['key'];
      if (post['mediaType'] == 'video' && post['videoUrl'] != null) {
        try {
          final controller = VideoPlayerController.network(post['videoUrl']);
          _videoControllers[postKey] = controller;
          _videoKeys[postKey] = GlobalKey();
          _userPausedVideos[postKey] = false;
          _videoInitialized[postKey] = false;

          // Initialize the controller
          controller
              .initialize()
              .then((_) {
                if (mounted) {
                  setState(() {
                    _videoInitialized[postKey] = true;
                    controller.setLooping(true);
                  });
                  // Check visibility after all videos are initialized
                  if (_areAllVideosInitialized()) {
                    _scheduleInitialVisibilityCheck();
                  }
                }
              })
              .catchError((error) {
                print(
                  'Error initializing video controller for $postKey: $error',
                );
                if (mounted) {
                  setState(() {
                    _videoInitialized[postKey] = false;
                  });
                }
              });
        } catch (e) {
          print('Error creating video controller for $postKey: $e');
        }
      }
    }
  }

  bool _areAllVideosInitialized() {
    for (var post in _userPosts) {
      final postKey = post['key'];
      if (post['mediaType'] == 'video') {
        if (!_isVideoControllerInitialized(postKey)) {
          return false;
        }
      }
    }
    return true;
  }

  void _scheduleInitialVisibilityCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkVideoVisibility();
      }
    });
  }

  bool _isVideoControllerInitialized(String postKey) {
    return _videoInitialized[postKey] ?? false;
  }

  void _loadInteractions() {
    // Load comment counts, likes, shares from the post data itself for ALL USERS
    for (var post in _userPosts) {
      final postKey = post['key'];

      // Get commentCount directly from post
      final commentCount = post['commentCount'];
      _commentCounts[postKey] = (commentCount is int)
          ? commentCount
          : (commentCount is num ? commentCount.toInt() : 0);

      // Get likes directly from post
      final likes = post['likes'];
      _likeCounts[postKey] = (likes is int)
          ? likes
          : (likes is num ? likes.toInt() : 0);

      // Get shares directly from post
      final shares = post['shares'];
      _shareCounts[postKey] = (shares is int)
          ? shares
          : (shares is num ? shares.toInt() : 0);
    }

    // Only load user-specific interactions if user is logged in
    if (widget.currentUserId == null) return;

    // Load likes (user-specific)
    _database.child('userLikes/${widget.currentUserId}').onValue.listen((
      event,
    ) {
      try {
        final data = event.snapshot.value;
        if (data != null && data is Map<dynamic, dynamic>) {
          setState(() {
            data.forEach((postId, value) {
              if (postId is String) {
                _likedPosts[postId] = true;
              }
            });
          });
        }
      } catch (e) {
        print('Error loading likes: $e');
      }
    });

    // Load saves (user-specific)
    _database.child('userSaves/${widget.currentUserId}').onValue.listen((
      event,
    ) {
      try {
        final data = event.snapshot.value;
        if (data != null && data is Map<dynamic, dynamic>) {
          setState(() {
            data.forEach((postId, value) {
              if (postId is String) {
                _savedPosts[postId] = true;
              }
            });
          });
        }
      } catch (e) {
        print('Error loading saves: $e');
      }
    });

    // Load gifts (user-specific)
    _database.child('gifts').onValue.listen((event) {
      try {
        final data = event.snapshot.value;
        if (data != null && data is Map<dynamic, dynamic>) {
          setState(() {
            _giftCounts.clear();
            _hasGifted.clear();
            data.forEach((postId, gifts) {
              if (postId is String && gifts is Map<dynamic, dynamic>) {
                int total = 0;
                gifts.forEach((userId, count) {
                  if (userId == widget.currentUserId) {
                    _hasGifted[postId] = true;
                  }
                  if (count is int) {
                    total += count;
                  } else if (count is num) {
                    total += count.toInt();
                  }
                });
                _giftCounts[postId] = total;
              }
            });
          });
        }
      } catch (e) {
        print('Error loading gifts: $e');
      }
    });
  }

  void _checkIfFollowing() async {
    if (widget.currentUserId == null) return;

    try {
      final followSnapshot = await _database
          .child('userFollows/${widget.currentUserId}/${widget.userId}')
          .get();

      setState(() {
        _isFollowing = followSnapshot.exists;
      });
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please login to follow users')));
      return;
    }

    if (widget.userId == widget.currentUserId) return;

    try {
      final userFollowsRef = _database.child(
        'userFollows/${widget.currentUserId}/${widget.userId}',
      );

      if (_isFollowing) {
        await userFollowsRef.remove();
        await _database
            .child('userFollowers/${widget.userId}/${widget.currentUserId}')
            .remove();

        // Update counts in Firestore
        await _firestore.collection('users').doc(widget.userId).update({
          'followersCount': FieldValue.increment(-1),
        });
        await _firestore.collection('users').doc(widget.currentUserId).update({
          'followingCount': FieldValue.increment(-1),
        });

        setState(() {
          _isFollowing = false;
          _followersCount--;
        });
      } else {
        await userFollowsRef.set(ServerValue.timestamp);
        await _database
            .child('userFollowers/${widget.userId}/${widget.currentUserId}')
            .set(true);

        // Update counts in Firestore
        await _firestore.collection('users').doc(widget.userId).update({
          'followersCount': FieldValue.increment(1),
        });
        await _firestore.collection('users').doc(widget.currentUserId).update({
          'followingCount': FieldValue.increment(1),
        });

        setState(() {
          _isFollowing = true;
          _followersCount++;
        });
      }
    } catch (e) {
      print('Error toggling follow: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _openDirectMessage() {
    if (widget.currentUserId == null) {
      _showLoginRequiredDialog("send messages");
      return;
    }

    if (widget.userId == widget.currentUserId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("You cannot message yourself")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          recipientId: widget.userId,
          recipientName: _userData['fullName'] ?? 'User',
          recipientAvatar:
              _userData['photoURL'] ?? 'https://i.pravatar.cc/150?img=1',
        ),
      ),
    );
  }

  Future<void> _toggleLike(String postKey) async {
    if (widget.currentUserId == null) {
      _showLoginRequiredDialog("like posts");
      return;
    }

    try {
      final postRef = _database.child('posts/$postKey');
      final postSnapshot = await postRef.get();
      if (!postSnapshot.exists) return;

      final postData = postSnapshot.value;
      if (postData is! Map<dynamic, dynamic>) return;

      final post = Map<String, dynamic>.from(postData);
      final currentLikes = (post['likes'] is int ? post['likes'] as int : 0);
      final isLiked = _likedPosts[postKey] ?? false;

      await postRef.update({
        'likes': isLiked ? currentLikes - 1 : currentLikes + 1,
      });

      final userLikesRef = _database.child(
        'userLikes/${widget.currentUserId}/$postKey',
      );
      if (isLiked) {
        await userLikesRef.remove();
      } else {
        await userLikesRef.set(true);
      }

      setState(() {
        _likedPosts[postKey] = !isLiked;
        _likeCounts[postKey] = isLiked ? currentLikes - 1 : currentLikes + 1;
      });
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error toggling like: $e')));
    }
  }

  Future<void> _toggleSave(String postKey) async {
    if (widget.currentUserId == null) {
      _showLoginRequiredDialog("save posts");
      return;
    }

    try {
      final userSavesRef = _database.child(
        'userSaves/${widget.currentUserId}/$postKey',
      );
      final saveSnapshot = await userSavesRef.get();
      final isSaved = saveSnapshot.exists && saveSnapshot.value == true;

      if (isSaved) {
        await userSavesRef.remove();
      } else {
        await userSavesRef.set(true);
      }

      setState(() {
        _savedPosts[postKey] = !isSaved;
      });
    } catch (e) {
      print('Error toggling save: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error toggling save: $e')));
    }
  }

  Future<void> _sendGift(String postKey) async {
    if (widget.currentUserId == null) {
      _showLoginRequiredDialog("send gifts");
      return;
    }

    try {
      final postRef = _database.child('posts/$postKey');
      final postSnapshot = await postRef.get();
      if (!postSnapshot.exists) return;

      final postData = postSnapshot.value;
      if (postData is! Map<dynamic, dynamic>) return;

      final post = Map<String, dynamic>.from(postData);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GiftPage(
            recipientName: post['userName'] ?? 'User',
            recipientAvatar: post['userPhoto'] ?? 'https://i.pravatar.cc/150',
            recipientId: post['userId'],
            postId: postKey,
          ),
        ),
      );

      // Reload interactions after sending gift
      _loadInteractions();
    } catch (e) {
      print('Error sending gift: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending gift: $e')));
    }
  }

  void _handleVideoPlayPause(String postKey, bool paused) {
    setState(() {
      _userPausedVideos[postKey] = paused;
    });
    
    final controller = _videoControllers[postKey];
    if (controller == null) return;
    
    if (paused) {
      controller.pause();
      if (_currentlyPlayingPostId == postKey) {
        setState(() {
          _currentlyPlayingPostId = null;
        });
      }
    } else {
      // Pause any currently playing video
      if (_currentlyPlayingPostId != null && _currentlyPlayingPostId != postKey) {
        final otherController = _videoControllers[_currentlyPlayingPostId!];
        if (otherController != null && otherController.value.isPlaying) {
          otherController.pause();
        }
      }
      controller.play();
      setState(() {
        _currentlyPlayingPostId = postKey;
      });
    }
  }

  void _showLoginRequiredDialog(String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Login Required"),
          content: Text("You need to be logged in to $action."),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showFollowers() async {
    final followersSnapshot = await _database
        .child('userFollowers/${widget.userId}')
        .get();
    if (followersSnapshot.exists) {
      final followers = (followersSnapshot.value as Map).keys.toList();
      _showUserListDialog(context, 'Followers', followers);
    }
  }

  void _showFollowing() async {
    final followingSnapshot = await _database
        .child('userFollows/${widget.userId}')
        .get();
    if (followingSnapshot.exists) {
      final following = (followingSnapshot.value as Map).keys.toList();
      _showUserListDialog(context, 'Following', following);
    }
  }

  void _showUserListDialog(
    BuildContext context,
    String title,
    List<dynamic> userIds,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore
                    .collection('users')
                    .doc(userIds[index].toString())
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      leading: CircleAvatar(radius: 20),
                      title: Text('Loading...'),
                    );
                  }
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          userData['photoURL'] ??
                              'https://i.pravatar.cc/150?img=1',
                        ),
                        radius: 20,
                      ),
                      title: Text(userData['fullName'] ?? 'Unknown User'),
                      subtitle: Text(userData['username'] ?? ''),
                    );
                  }
                  return ListTile(title: Text('User not found'));
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userData['fullName'] ?? 'User Profile',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (widget.currentUserId != null &&
              widget.userId != widget.currentUserId)
            IconButton(
              icon: Icon(Icons.card_giftcard),
              onPressed: () {
                _sendGiftToUser();
              },
            ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            _userData['photoURL'] ??
                                'https://i.pravatar.cc/150?img=1',
                          ),
                          radius: 50,
                          onBackgroundImageError: (exception, stackTrace) {
                            // Handle image loading errors
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userData['fullName'] ?? 'User',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${_userData['username'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _userData['bio'] ?? 'No bio yet',
                          style: const TextStyle(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () => _showUserPosts(),
                              child: _buildStatColumn(_postsCount, 'Posts'),
                            ),
                            GestureDetector(
                              onTap: _showFollowers,
                              child: _buildStatColumn(
                                _followersCount,
                                'Followers',
                              ),
                            ),
                            GestureDetector(
                              onTap: _showFollowing,
                              child: _buildStatColumn(
                                _followingCount,
                                'Following',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (widget.userId != widget.currentUserId)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (widget.currentUserId !=
                                  null) // Follow button only for logged-in users
                                ElevatedButton(
                                  onPressed: _toggleFollow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isFollowing
                                        ? Colors.grey[300]
                                        : Colors.blue,
                                    foregroundColor: _isFollowing
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                  child: Text(
                                    _isFollowing ? 'Following' : 'Follow',
                                  ),
                                ),
                              // DM button always visible (but will show login prompt if not logged in)
                              ElevatedButton(
                                onPressed: _openDirectMessage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.message, size: 16),
                                    SizedBox(width: 4),
                                    Text('DM'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Posts Section
                  const SizedBox(height: 16),
                  if (_userPosts.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Posts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _userPosts.length,
                          itemBuilder: (context, index) {
                            final post = _userPosts[index];
                            final postKey = post['key'];
                            final postUserId = post['userId'];
                            final isOwnPost =
                                widget.currentUserId != null &&
                                postUserId == widget.currentUserId;

                            // Check if video is initialized
                            final isVideoInitialized =
                                post['mediaType'] == 'video'
                                ? _isVideoControllerInitialized(postKey)
                                : true;

                            return Column(
                              children: [
                                PostCard(
                                  post: post,
                                  videoController: _videoControllers[postKey],
                                  videoKey: _videoKeys[postKey],
                                  isPlaying:
                                      _currentlyPlayingPostId == postKey &&
                                      isVideoInitialized,
                                  isUserPaused:
                                      _userPausedVideos[postKey] ?? false,
                                  onUserPause: (paused) =>
                                      _handleVideoPlayPause(postKey, paused),
                                  currentUserId: widget.currentUserId,
                                  isLiked: _likedPosts[postKey] ?? false,
                                  isSaved: _savedPosts[postKey] ?? false,
                                  isFollowing:
                                      _followingUsers[postUserId] ?? false,
                                  showFollowButton:
                                      !isOwnPost &&
                                      widget.currentUserId != null &&
                                      widget.userId != widget.currentUserId,
                                  onLike: _toggleLike,
                                  onSave: _toggleSave,
                                  onGift: _sendGift,
                                  onFollow: (userId) {
                                    // Handle follow action if needed
                                  },
                                  giftCount: _giftCounts[postKey] ?? 0,
                                  commentCount: _commentCounts[postKey] ?? 0,
                                  shareCount: _shareCounts[postKey] ?? 0,
                                  likeCount: _likeCounts[postKey] ?? 0,
                                  hasGifted: _hasGifted[postKey] ?? false,
                                ),
                                const SizedBox(height: 8),
                                const Divider(height: 1, color: Colors.grey),
                              ],
                            );
                          },
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.post_add,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No posts yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'This user hasn\'t posted anything yet',
                            style: TextStyle(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _sendGiftToUser() async {
    if (widget.currentUserId == null) {
      _showLoginRequiredDialog("send gifts");
      return;
    }

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GiftPage(
            recipientName: _userData['fullName'] ?? 'User',
            recipientAvatar:
                _userData['photoURL'] ?? 'https://i.pravatar.cc/150?img=1',
            recipientId: widget.userId,
          ),
        ),
      );
    } catch (e) {
      print('Error sending gift: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending gift: $e')));
    }
  }

  Widget _buildStatColumn(int count, String label) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  void _showUserPosts() {
    // Already showing posts, so just scroll to them
    Scrollable.ensureVisible(context, duration: Duration(milliseconds: 500));
  }
}