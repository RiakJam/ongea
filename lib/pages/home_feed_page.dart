import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ongea/services/gift_page.dart';
import 'dart:async';
import '../widgets/post_card.dart';
import '../widgets/search_modal.dart';
import '../widgets/ad_card.dart';
import '../login_page.dart';
import 'user_profile_page.dart';
class HomeFeedPage extends StatefulWidget {
  @override
  _HomeFeedPageState createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _searchController = TextEditingController();

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
  int? _currentlyPlayingIndex;
  final Map<int, bool> _userPausedVideos = {};

  StreamSubscription<User?>? _authStateSubscription;

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

  void _loadPosts() {
    _database
        .child('posts')
        .orderByChild('timestamp')
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

                postsList.sort((a, b) {
                  final aTimestamp = a['timestamp'] ?? 0;
                  final bTimestamp = b['timestamp'] ?? 0;
                  return (bTimestamp is int ? bTimestamp : 0).compareTo(
                    aTimestamp is int ? aTimestamp : 0,
                  );
                });

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

    _database
        .child('userFollows/$_currentUserId')
        .onValue
        .listen(
          (event) {
            try {
              final data = event.snapshot.value;
              if (data != null && data is Map<dynamic, dynamic>) {
                setState(() {
                  _followingUsers.clear();
                  data.forEach((followedUserId, value) {
                    if (followedUserId is String) {
                      _followingUsers[followedUserId] = true;
                    }
                  });
                });
              }
            } catch (e) {
              print('Error loading follows: $e');
            }
          },
          onError: (error) {
            print('Error loading follows: $error');
          },
        );
  }

  void _initializeVideoControllers() {
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    _videoControllers.clear();
    _videoKeys.clear();
    _userPausedVideos.clear();

    for (var i = 0; i < _posts.length; i++) {
      final mediaType = _posts[i]['mediaType'];
      final videoUrl = _posts[i]['videoUrl'];

      if (mediaType == 'video' && videoUrl is String && videoUrl.isNotEmpty) {
        try {
          _videoControllers[i] = VideoPlayerController.network(videoUrl)
            ..initialize()
                .then((_) {
                  if (mounted) setState(() {});
                  _videoControllers[i]?.setLooping(true);
                })
                .catchError((error) {
                  print('Error initializing video controller: $error');
                });
          _videoKeys[i] = GlobalKey();
          _userPausedVideos[i] = false;
        } catch (e) {
          print('Error creating video controller: $e');
        }
      }
    }
  }

  void _handleScroll() {
    if (!mounted) return;

    int? mostVisibleIndex;
    double maxVisiblePercentage = 0;

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
    }

    if (mostVisibleIndex != null && maxVisiblePercentage > 0.5) {
      if (_currentlyPlayingIndex != mostVisibleIndex &&
          !(_userPausedVideos[mostVisibleIndex] ?? false)) {
        if (_currentlyPlayingIndex != null) {
          _videoControllers[_currentlyPlayingIndex]?.pause();
        }
        _videoControllers[mostVisibleIndex]?.play();
        setState(() {
          _currentlyPlayingIndex = mostVisibleIndex;
        });
      }
    } else if (_currentlyPlayingIndex != null &&
        !(_userPausedVideos[_currentlyPlayingIndex] ?? false)) {
      _videoControllers[_currentlyPlayingIndex]?.pause();
      setState(() {
        _currentlyPlayingIndex = null;
      });
    }
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
      final userFollowsRef = _database.child(
        'userFollows/$_currentUserId/$userId',
      );
      final followSnapshot = await userFollowsRef.get();
      final isFollowing = followSnapshot.exists;

      if (isFollowing) {
        await userFollowsRef.remove();
        await _database
            .child('users/$userId/followersCount')
            .set(ServerValue.increment(-1));
        await _database
            .child('users/$_currentUserId/followingCount')
            .set(ServerValue.increment(-1));
      } else {
        await userFollowsRef.set(ServerValue.timestamp);
        await _database
            .child('users/$userId/followersCount')
            .set(ServerValue.increment(1));
        await _database
            .child('users/$_currentUserId/followingCount')
            .set(ServerValue.increment(1));
      }

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

  void _openSearchModal() {
    setState(() {
      _showSearchModal = true;
    });
  }

  void _closeSearchModal() {
    setState(() {
      _showSearchModal = false;
      _searchQuery = "";
      _searchController.clear();
      _filteredPosts.clear();
    });
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
                // Make the avatar clickable
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
                  // Make the username clickable
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
                onPressed: _openSearchModal,
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
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Top bar with transparent background
              _buildTopBar(),
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
                      itemCount:
                          _posts.length +
                          (_posts.length ~/ 3), // Account for ad cards
                      itemBuilder: (context, index) {
                        // Check if we should show an ad (after every 3 posts)
                        if (index > 0 && index % 4 == 0) {
                          return Column(
                            children: [
                              const SizedBox(height: 8),
                              AdCard(
                                adText: "Check out our premium features!",
                                imageUrl:
                                    "https://via.placeholder.com/400x150.png?text=Sponsor+Ad",
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1, color: Colors.grey),
                            ],
                          );
                        }

                        // Calculate the actual post index accounting for ads
                        final postIndex = index - (index ~/ 4);
                        if (postIndex >= _posts.length) {
                          return const SizedBox.shrink();
                        }

                        final post = _posts[postIndex];
                        final postKey = post['key'] as String? ?? '';
                        final postUserId = post['userId'] as String?;
                        final isFollowing =
                            _followingUsers[postUserId] ?? false;

                        // Check if this is the current user's own post
                        final isOwnPost =
                            _currentUserId != null &&
                            postUserId == _currentUserId;

                        return Column(
                          children: [
                            PostCard(
                              post: post,
                              videoController: _videoControllers[postIndex],
                              videoKey: _videoKeys[postIndex],
                              isPlaying: postIndex == _currentlyPlayingIndex,
                              isUserPaused:
                                  _userPausedVideos[postIndex] ?? false,
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
                              // Hide follow button on own posts
                              showFollowButton: !isOwnPost,
                              onLike: (String postKey) => _toggleLike(postKey),
                              onSave: (String postKey) => _toggleSave(postKey),
                              onGift: (String postKey) => _sendGift(postKey),
                              onFollow: (String userId) =>
                                  _toggleFollow(userId),
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
          // Search modal overlay
          if (_showSearchModal)
            SearchModal(
              context: context,
              searchController: _searchController,
              searchQuery: _searchQuery,
              filteredPosts: _filteredPosts,
              posts: _posts,
              videoControllers: _videoControllers,
              videoKeys: _videoKeys,
              currentlyPlayingIndex: _currentlyPlayingIndex,
              userPausedVideos: _userPausedVideos,
              currentUserId: _currentUserId,
              likedPosts: _likedPosts,
              savedPosts: _savedPosts,
              followingUsers: _followingUsers,
              commentCounts: _commentCounts,
              shareCounts: _shareCounts,
              likeCounts: _likeCounts,
              onLike: _toggleLike,
              onSave: _toggleSave,
              onGift: _sendGift,
              onFollow: _toggleFollow,
              giftCounts: _giftCounts,
              hasGifted: _hasGifted,
              onClose: _closeSearchModal,
              onUpdateSearchQuery: _updateSearchQuery,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    super.dispose();
  }
}
