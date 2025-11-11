import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ongea/services/gift_page.dart';
import 'dart:async';
import 'dart:math';
import '../widgets/post_card.dart';
import '../widgets/search_page.dart';
import '../widgets/ad_card.dart';
import '../login_page.dart';
import 'user_profile_page.dart';
// import 'package:cached_network_image/cached_network_image.dart';

class HomeFeedPage extends StatefulWidget {
  @override
  _HomeFeedPageState createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _searchController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  bool _shouldShuffle = true;

  bool _showSearchModal = false;
  String _searchQuery = "";
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatar;

  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _filteredPosts = [];
  final Map<String, int> _giftCounts = {};
  final Map<String, int> _commentCounts = {};
  final Map<String, int> _shareCounts = {};
  final Map<String, int> _likeCounts = {};
  final Map<String, bool> _hasGifted = {};
  final Map<String, bool> _likedPosts = {};
  final Map<String, bool> _savedPosts = {};
  final Map<String, bool> _followingUsers = {};

  final ScrollController _scrollController = ScrollController();
  final Map<int, VideoPlayerController?> _videoControllers = {};
  final Map<int, GlobalKey> _videoKeys = {};
  final Map<int, Future<void>?> _videoInitializationFutures = {};
  int? _currentlyPlayingIndex;
  final Map<int, bool> _userPausedVideos = {};

  // Preloading variables
  final int _preloadAheadCount = 3;
  final Map<String, dynamic> _preloadedPostData = {};
  bool _isPreloading = false;
  int _lastPreloadedIndex = -1;

  // Optimization variables
  final Map<String, VideoPlayerController> _preloadedVideoControllers = {};
  final Map<String, bool> _videosBeingPreloaded = {};
  final Map<String, dynamic> _preloadedImages = {};
  Timer? _scrollDebounceTimer;

  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _followsSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);

    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadCurrentUser();
      } else {
        setState(() {
          _currentUserId = null;
          _currentUserName = null;
          _currentUserAvatar = null;
        });
        _loadPosts();
      }
    });
  }

  void _loadCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });

      _database
          .child('users/${user.uid}')
          .once()
          .then((DatabaseEvent event) {
            if (event.snapshot.value != null) {
              final userData = Map<String, dynamic>.from(
                event.snapshot.value as Map,
              );
              setState(() {
                _currentUserName =
                    userData['name'] ?? user.displayName ?? 'User';
                _currentUserAvatar =
                    userData['photoURL'] ??
                    user.photoURL ??
                    'https://i.pravatar.cc/150?img=1';
              });
            } else {
              setState(() {
                _currentUserName = user.displayName ?? 'User';
                _currentUserAvatar =
                    user.photoURL ?? 'https://i.pravatar.cc/150?img=1';
              });
            }
          })
          .catchError((error) {
            setState(() {
              _currentUserName = user.displayName ?? 'User';
              _currentUserAvatar =
                  user.photoURL ?? 'https://i.pravatar.cc/150?img=1';
            });
          });

      _loadPosts();
      _loadInteractions();
    }
  }

  void _precacheImages(List<Map<String, dynamic>> posts) {
    for (var post in posts) {
      if (post['mediaType'] == 'image') {
        final imageUrl = post['imageUrl'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty && !_preloadedImages.containsKey(imageUrl)) {
          _preloadedImages[imageUrl] = true;
          
          // Pre-cache the image
          precacheImage(NetworkImage(imageUrl), context).catchError((e) {
            print('Error pre-caching image: $e');
          });
        }
      }
      
      // Also pre-cache user avatars
      final userPhoto = post['userPhoto'] as String?;
      if (userPhoto != null && userPhoto.isNotEmpty && !_preloadedImages.containsKey(userPhoto)) {
        _preloadedImages[userPhoto] = true;
        precacheImage(NetworkImage(userPhoto), context).catchError((e) {
          print('Error pre-caching avatar: $e');
        });
      }
    }
  }

  void _preloadVideos(List<Map<String, dynamic>> posts) {
    for (var post in posts) {
      if (post['mediaType'] == 'video') {
        final videoUrl = post['videoUrl'] as String?;
        if (videoUrl != null && 
            videoUrl.isNotEmpty && 
            !_preloadedVideoControllers.containsKey(videoUrl) &&
            !_videosBeingPreloaded.containsKey(videoUrl)) {
          
          _videosBeingPreloaded[videoUrl] = true;
          
          // Preload in background
          Future.microtask(() async {
            try {
              final controller = VideoPlayerController.network(videoUrl);
              await controller.initialize();
              controller.setLooping(true);
              
              if (mounted) {
                setState(() {
                  _preloadedVideoControllers[videoUrl] = controller;
                  _videosBeingPreloaded.remove(videoUrl);
                });
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  _videosBeingPreloaded.remove(videoUrl);
                });
              }
              print('Error preloading video: $e');
            }
          });
        }
      }
    }
  }

  void _loadPosts() {
    _database
        .child('posts')
        .onValue
        .listen(
          (event) {
            try {
              final data = event.snapshot.value;
              if (data != null && data is Map<dynamic, dynamic>) {
                final postsList = <Map<String, dynamic>>[];

                data.forEach((key, value) {
                  if (value is Map<dynamic, dynamic>) {
                    final post = Map<String, dynamic>.from(value);
                    post['key'] = key;
                    postsList.add(post);
                  }
                });

                // Pre-cache images and preload videos
                _precacheImages(postsList);
                _preloadVideos(postsList);

                // ✅ Shuffle only if flagged
                if (_shouldShuffle) {
                  final random = Random();
                  postsList.shuffle(random);
                  _shouldShuffle = false; // reset after one shuffle
                }

                setState(() {
                  _posts = postsList;
                  _initializeVideoControllers();

                  for (var post in _posts) {
                    final postKey = post['key'] as String? ?? '';

                    final comments = post['comments'];
                    _commentCounts[postKey] = comments is Map
                        ? comments.length
                        : 0;

                    final shares = post['shares'];
                    _shareCounts[postKey] = (shares is int)
                        ? shares
                        : (shares is num ? shares.toInt() : 0);

                    final likes = post['likes'];
                    _likeCounts[postKey] = (likes is int)
                        ? likes
                        : (likes is num ? likes.toInt() : 0);
                  }
                });
              } else {
                setState(() {
                  _posts = [];
                  _initializeVideoControllers();
                });
              }
            } catch (e) {
              print('Error loading posts: $e');
              setState(() {
                _posts = [];
                _initializeVideoControllers();
              });
            }
          },
          onError: (error) {
            print('Firebase Database Error: $error');
            setState(() {
              _posts = [];
              _initializeVideoControllers();
            });
          },
        );
  }

  void _cleanupDistantVideos(int currentIndex) {
    final cleanupThreshold = 10; // Number of posts to keep around current view
    
    _videoControllers.forEach((index, controller) {
      if ((index - currentIndex).abs() > cleanupThreshold) {
        // Don't dispose preloaded controllers, just pause them
        final videoUrl = _posts[index]['videoUrl'] as String?;
        if (videoUrl == null || !_preloadedVideoControllers.containsKey(videoUrl)) {
          controller?.pause();
          controller?.dispose();
        } else {
          controller?.pause();
        }
        _videoControllers.remove(index);
        _videoKeys.remove(index);
        _userPausedVideos.remove(index);
        _videoInitializationFutures.remove(index);
      }
    });
  }

  void _loadInteractions() {
    if (_currentUserId == null) return;

    _database
        .child('userLikes/$_currentUserId')
        .onValue
        .listen(
          (event) {
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
          },
          onError: (error) {
            print('Error loading likes: $error');
          },
        );

    _database
        .child('userSaves/$_currentUserId')
        .onValue
        .listen(
          (event) {
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
          },
          onError: (error) {
            print('Error loading saves: $error');
          },
        );

    _database
        .child('gifts')
        .onValue
        .listen(
          (event) {
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
                        if (userId == _currentUserId) {
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
          },
          onError: (error) {
            print('Error loading gifts: $error');
          },
        );

    // Load follows from Firestore
    _loadFollowsFromFirestore();
  }

  void _loadFollowsFromFirestore() {
    if (_currentUserId == null) return;

    // Cancel any existing subscription
    _followsSubscription?.cancel();

    _followsSubscription = _firestore
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .listen(
          (DocumentSnapshot<Map<String, dynamic>> snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data();
              final followingList = data?['following'] as List<dynamic>? ?? [];

              final Map<String, bool> updatedFollowing = {};
              for (var userId in followingList) {
                if (userId is String) {
                  updatedFollowing[userId] = true;
                }
              }

              setState(() {
                _followingUsers.clear();
                _followingUsers.addAll(updatedFollowing);
              });
            }
          },
          onError: (error) {
            print('Error loading follows from Firestore: $error');
          },
        );
  }

  void _initializeVideoControllers({int startIndex = 0}) {
    for (var i = 0; i < startIndex; i++) {
      if (_videoControllers.containsKey(i) &&
          (i >= _posts.length || _posts[i]['mediaType'] != 'video')) {
        final videoUrl = _posts[i]['videoUrl'] as String?;
        if (videoUrl == null || !_preloadedVideoControllers.containsKey(videoUrl)) {
          _videoControllers[i]?.dispose();
        }
        _videoControllers.remove(i);
        _videoKeys.remove(i);
        _userPausedVideos.remove(i);
        _videoInitializationFutures.remove(i);
      }
    }

    final endIndex = min(_posts.length, startIndex + _preloadAheadCount + 5);

    for (var i = startIndex; i < endIndex; i++) {
      if (i >= _posts.length) break;

      final mediaType = _posts[i]['mediaType'];
      final videoUrl = _posts[i]['videoUrl'];

      if (mediaType == 'video' && videoUrl is String && videoUrl.isNotEmpty) {
        if (!_videoControllers.containsKey(i)) {
          // Use preloaded controller if available
          if (_preloadedVideoControllers.containsKey(videoUrl)) {
            _videoControllers[i] = _preloadedVideoControllers[videoUrl];
            _videoKeys[i] = GlobalKey();
            _userPausedVideos[i] = false;
            
            // No need to initialize again
            if (i == 0 && _currentlyPlayingIndex == null) {
              _videoControllers[i]?.play();
              setState(() {
                _currentlyPlayingIndex = 0;
              });
            }
          } else {
            // Fallback to normal initialization
            try {
              final controller = VideoPlayerController.network(videoUrl);
              _videoControllers[i] = controller;
              _videoKeys[i] = GlobalKey();
              _userPausedVideos[i] = false;

              _videoInitializationFutures[i] = controller
                  .initialize()
                  .then((_) {
                    if (mounted) setState(() {});
                    controller.setLooping(true);

                    if (i == 0 && _currentlyPlayingIndex == null) {
                      controller.play();
                      setState(() {
                        _currentlyPlayingIndex = 0;
                      });
                    }
                  })
                  .catchError((error) {
                    print('Error initializing video controller: $error');
                  });
            } catch (e) {
              print('Error creating video controller: $e');
            }
          }
        }
      }
    }

    _lastPreloadedIndex = endIndex - 1;
  }

  void _preloadContent(int currentIndex) {
    if (_isPreloading || _posts.isEmpty) return;

    _isPreloading = true;
    final preloadEndIndex = min(_posts.length, 5);

    for (var i = 0; i < preloadEndIndex; i++) {
      if (_posts[i]['mediaType'] == 'video') {
        final videoUrl = _posts[i]['videoUrl'];
        if (videoUrl is String &&
            videoUrl.isNotEmpty &&
            !_videoControllers.containsKey(i)) {
          try {
            final controller = VideoPlayerController.network(videoUrl);
            _videoControllers[i] = controller;
            _videoKeys[i] = GlobalKey();
            _userPausedVideos[i] = false;

            _videoInitializationFutures[i] = controller
                .initialize()
                .then((_) {
                  controller.setLooping(true);
                })
                .catchError((error) {
                  print('Error preinitializing video controller: $error');
                });
          } catch (e) {
            print('Error precreating video controller: $e');
          }
        }
      }

      final userId = _posts[i]['userId'];
      if (userId is String && !_preloadedPostData.containsKey(userId)) {
        _database.child('users/$userId').once().then((DatabaseEvent event) {
          if (event.snapshot.value != null) {
            final userData = Map<String, dynamic>.from(
              event.snapshot.value as Map,
            );
            _preloadedPostData[userId] = userData;
          }
        });
      }
    }

    if (currentIndex > _lastPreloadedIndex) {
      final preloadStartIndex = max(_lastPreloadedIndex + 1, 5);
      final preloadEndIndex = min(
        _posts.length,
        currentIndex + _preloadAheadCount + 1,
      );

      for (var i = preloadStartIndex; i < preloadEndIndex; i++) {
        if (_posts[i]['mediaType'] == 'video') {
          final videoUrl = _posts[i]['videoUrl'];
          if (videoUrl is String &&
              videoUrl.isNotEmpty &&
              !_videoControllers.containsKey(i)) {
            try {
              final controller = VideoPlayerController.network(videoUrl);
              _videoControllers[i] = controller;
              _videoKeys[i] = GlobalKey();
              _userPausedVideos[i] = false;

              _videoInitializationFutures[i] = controller
                  .initialize()
                  .then((_) {
                    controller.setLooping(true);
                  })
                  .catchError((error) {
                    print('Error preinitializing video controller: $error');
                  });
            } catch (e) {
              print('Error precreating video controller: $e');
            }
          }
        }

        final userId = _posts[i]['userId'];
        if (userId is String && !_preloadedPostData.containsKey(userId)) {
          _database.child('users/$userId').once().then((DatabaseEvent event) {
            if (event.snapshot.value != null) {
              final userData = Map<String, dynamic>.from(
                event.snapshot.value as Map,
              );
              _preloadedPostData[userId] = userData;
            }
          });
        }
      }

      _lastPreloadedIndex = preloadEndIndex - 1;
    }

    _isPreloading = false;
  }

  void _handleScroll() {
    if (!mounted) return;
    
    // Debounce scroll events to avoid excessive processing
    if (_scrollDebounceTimer != null) {
      _scrollDebounceTimer!.cancel();
    }
    
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      int? mostVisibleIndex;
      double maxVisiblePercentage = 0;
      int currentVisibleIndex = -1;

      for (var i = 0; i < _posts.length; i++) {
        if (_posts[i]['mediaType'] != 'video') continue;

        final key = _videoKeys[i];
        if (key?.currentContext == null) continue;

        final renderObject = key?.currentContext?.findRenderObject();
        if (renderObject == null || !(renderObject is RenderBox)) continue;

        final position = renderObject.localToGlobal(Offset.zero);
        final size = renderObject.size;
        final screenHeight = MediaQuery.of(context).size.height;

        final visibleHeight =
            (position.dy + size.height < 0 || position.dy > screenHeight)
            ? 0.0
            : (position.dy + size.height > screenHeight
                  ? screenHeight - (position.dy > 0 ? position.dy : 0)
                  : (position.dy < 0 ? position.dy + size.height : size.height));

        final visiblePercentage = visibleHeight / size.height;

        if (visiblePercentage > maxVisiblePercentage) {
          maxVisiblePercentage = visiblePercentage;
          mostVisibleIndex = i;
        }

        if (visiblePercentage > 0.1 && currentVisibleIndex == -1) {
          currentVisibleIndex = i;
        }
      }

      if (currentVisibleIndex != -1) {
        _preloadContent(currentVisibleIndex);
        _cleanupDistantVideos(currentVisibleIndex);
      }

      if (mostVisibleIndex != null && maxVisiblePercentage > 0.5) {
        if (_currentlyPlayingIndex != mostVisibleIndex &&
            !(_userPausedVideos[mostVisibleIndex] ?? false)) {
          if (_currentlyPlayingIndex != null) {
            _videoControllers[_currentlyPlayingIndex]?.pause();
          }

          if (_videoInitializationFutures.containsKey(mostVisibleIndex)) {
            _videoInitializationFutures[mostVisibleIndex]!.then((_) {
              if (mounted) {
                _videoControllers[mostVisibleIndex]?.play();
                setState(() {
                  _currentlyPlayingIndex = mostVisibleIndex;
                });
              }
            });
          } else {
            _videoControllers[mostVisibleIndex]?.play();
            setState(() {
              _currentlyPlayingIndex = mostVisibleIndex;
            });
          }
        }
      } else if (_currentlyPlayingIndex != null &&
          !(_userPausedVideos[_currentlyPlayingIndex] ?? false)) {
        _videoControllers[_currentlyPlayingIndex]?.pause();
        setState(() {
          _currentlyPlayingIndex = null;
        });
      }
    });
  }

  Future<void> _sendGift(String postId) async {
    if (_currentUserId == null) {
      _showLoginRequiredDialog(context, "send gifts");
      return;
    }

    try {
      final postRef = _database.child('posts/$postId');
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
            postId: postId,
            // Pass the preloaded video URL for instant playback
            // initialVideoUrl: post['videoUrl'],
          ),
        ),
      );

      _loadInteractions();
    } catch (e) {
      print('Error sending gift: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending gift: $e')));
    }
  }

  Future<void> _toggleLike(String postKey) async {
    if (_currentUserId == null) {
      _showLoginRequiredDialog(context, "like posts");
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
        'userLikes/$_currentUserId/$postKey',
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
    if (_currentUserId == null) {
      _showLoginRequiredDialog(context, "save posts");
      return;
    }

    try {
      final userSavesRef = _database.child(
        'userSaves/$_currentUserId/$postKey',
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

  Future<void> _toggleFollow(String userId) async {
    if (_currentUserId == null) {
      _showLoginRequiredDialog(context, "follow users");
      return;
    }
    if (userId == _currentUserId) return;

    try {
      final currentUserRef = _firestore.collection('users').doc(_currentUserId);
      final targetUserRef = _firestore.collection('users').doc(userId);

      // Get current user data
      final currentUserDoc = await currentUserRef.get();
      final currentUserData = currentUserDoc.data();

      // Get target user data
      final targetUserDoc = await targetUserRef.get();
      final targetUserData = targetUserDoc.data();

      // Check if following already exists
      final currentUserFollowing =
          currentUserData?['following'] as List<dynamic>? ?? [];
      final isFollowing = currentUserFollowing.contains(userId);

      if (isFollowing) {
        // 🔽 Unfollow - Remove from arrays and decrement counts
        await currentUserRef.update({
          'following': FieldValue.arrayRemove([userId]),
          'followingCount': FieldValue.increment(-1),
        });

        await targetUserRef.update({
          'followers': FieldValue.arrayRemove([_currentUserId]),
          'followersCount': FieldValue.increment(-1),
        });
      } else {
        // 🔼 Follow - Add to arrays and increment counts
        await currentUserRef.update({
          'following': FieldValue.arrayUnion([userId]),
          'followingCount': FieldValue.increment(1),
        });

        await targetUserRef.update({
          'followers': FieldValue.arrayUnion([_currentUserId]),
          'followersCount': FieldValue.increment(1),
        });
      }

      // Update local state
      setState(() {
        _followingUsers[userId] = !isFollowing;
      });
    } catch (e) {
      print('Error toggling follow: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error toggling follow: $e')));
    }
  }

  void _showLoginRequiredDialog(BuildContext context, String action) {
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

  void _openSearchPage() {
    // Pause any currently playing video before navigating
    if (_currentlyPlayingIndex != null) {
      _videoControllers[_currentlyPlayingIndex]?.pause();
      setState(() {
        _currentlyPlayingIndex = null;
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(
          currentUserId: _currentUserId,
          likedPosts: _likedPosts,
          savedPosts: _savedPosts,
          followingUsers: _followingUsers,
          onLike: _toggleLike,
          onSave: _toggleSave,
          onGift: _sendGift,
          onFollow: _toggleFollow,
          giftCounts: _giftCounts,
          hasGifted: _hasGifted,
          commentCounts: _commentCounts,
          shareCounts: _shareCounts,
          likeCounts: _likeCounts,
        ),
      ),
    );
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isNotEmpty) {
        _filteredPosts = _posts.where((post) {
          final user = post['userName'] as String? ?? 'Guest';
          final text = post['caption'] as String? ?? '';
          return user.toLowerCase().contains(query.toLowerCase()) ||
              text.toLowerCase().contains(query.toLowerCase());
        }).toList();
      } else {
        _filteredPosts.clear();
      }
    });
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _currentUserId != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfilePage(
                                userId: _currentUserId!,
                                currentUserId: _currentUserId,
                              ),
                            ),
                          );
                        }
                      : null,
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(
                      _currentUserAvatar ?? 'https://i.pravatar.cc/150?img=1',
                    ),
                    radius: 20,
                  ),
                ),
                const SizedBox(width: 10),
                if (_currentUserId == null)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Login',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(
                            userId: _currentUserId!,
                            currentUserId: _currentUserId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentUserName ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: _openSearchPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SafeArea(bottom: false, child: _buildTopBar()),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollUpdateNotification ||
                    scrollNotification is ScrollStartNotification) {
                  _handleScroll();
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 1));
                  _loadPosts();
                  if (_currentUserId != null) {
                    _loadInteractions();
                  }
                },
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _posts.length + (_posts.length ~/ 3),
                  itemBuilder: (context, index) {
                    if (index > 0 && index % 4 == 0) {
                      return Column(
                        children: [
                          const SizedBox(height: 8),
                          const AdCard(
                            isTestAd: true, // set to false in production
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Colors.grey),
                        ],
                      );
                    }

                    final postIndex = index - (index ~/ 4);
                    if (postIndex >= _posts.length) {
                      return const SizedBox.shrink();
                    }

                    final post = _posts[postIndex];
                    final postKey = post['key'] as String? ?? '';
                    final postUserId = post['userId'] as String?;
                    final isFollowing = _followingUsers[postUserId] ?? false;
                    final isOwnPost =
                        _currentUserId != null && postUserId == _currentUserId;

                    return Column(
                      children: [
                        PostCard(
                          post: post,
                          videoController: _videoControllers[postIndex],
                          videoKey: _videoKeys[postIndex],
                          isPlaying: postIndex == _currentlyPlayingIndex,
                          isUserPaused: _userPausedVideos[postIndex] ?? false,
                          onUserPause: (bool paused) {
                            setState(() {
                              _userPausedVideos[postIndex] = paused;
                              if (paused) {
                                _videoControllers[postIndex]?.pause();
                                if (_currentlyPlayingIndex == postIndex) {
                                  _currentlyPlayingIndex = null;
                                }
                              } else {
                                _handleScroll();
                              }
                            });
                          },
                          currentUserId: _currentUserId,
                          isLiked: _likedPosts[postKey] ?? false,
                          isSaved: _savedPosts[postKey] ?? false,
                          isFollowing: isFollowing,
                          showFollowButton: !isOwnPost,
                          onLike: _toggleLike,
                          onSave: _toggleSave,
                          onGift: _sendGift,
                          onFollow: _toggleFollow,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _followsSubscription?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    
    // Dispose all video controllers
    for (var controller in _videoControllers.values) {
      final videoUrl = controller?.dataSource;
      if (videoUrl == null || !_preloadedVideoControllers.containsKey(videoUrl)) {
        controller?.dispose();
      }
    }
    
    // Dispose preloaded video controllers
    for (var controller in _preloadedVideoControllers.values) {
      controller.dispose();
    }
    
    _scrollDebounceTimer?.cancel();
    
    super.dispose();
  }
}