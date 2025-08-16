import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
import 'package:ongea/services/gift_page.dart';
// import '../widgets/comment_section.dart';
import '../widgets/post_card.dart';
import '../widgets/search_modal.dart';

class HomeFeedPage extends StatefulWidget {
  @override
  _HomeFeedPageState createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref('posts');
  final TextEditingController _searchController = TextEditingController();

  bool _showSearchModal = false;
  String _searchQuery = "";
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatar;
  
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _filteredPosts = [];
  final Map<String, int> _giftCounts = {};
  final Map<String, bool> _hasGifted = {};
  
  final ScrollController _scrollController = ScrollController();
  final Map<int, VideoPlayerController?> _videoControllers = {};
  final Map<int, GlobalKey> _videoKeys = {};
  int? _currentlyPlayingIndex;
  final Map<int, bool> _userPausedVideos = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadCurrentUser();
    _loadPosts();
    _loadGiftCounts();
  }

  void _loadCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = user.displayName ?? 'Anonymous';
        _currentUserAvatar = user.photoURL ?? 'https://i.pravatar.cc/150?img=1';
      });
    }
  }

  void _loadPosts() {
    _database.orderByChild('timestamp').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final postsList = data.entries.map((entry) {
          final post = Map<String, dynamic>.from(entry.value as Map);
          post['key'] = entry.key;
          return post;
        }).toList();
        
        postsList.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        
        setState(() {
          _posts = postsList;
          _initializeVideoControllers();
        });
      }
    });
  }

  void _loadGiftCounts() {
    _database.child('gifts').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _giftCounts.clear();
          _hasGifted.clear();
          data.forEach((postId, gifts) {
            if (gifts is Map) {
              int total = 0;
              gifts.forEach((userId, count) {
                total += (count as int? ?? 0);
                if (userId == _currentUserId) {
                  _hasGifted[postId as String] = true;
                }
              });
              _giftCounts[postId as String] = total;
            }
          });
        });
      }
    });
  }

  void _initializeVideoControllers() {
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    _videoControllers.clear();
    _videoKeys.clear();
    _userPausedVideos.clear();

    for (var i = 0; i < _posts.length; i++) {
      if (_posts[i]['mediaType'] == 'video') {
        _videoControllers[i] = VideoPlayerController.network(_posts[i]['videoUrl'] as String)
          ..initialize().then((_) {
            if (mounted) setState(() {});
            _videoControllers[i]?.setLooping(true);
          });
        _videoKeys[i] = GlobalKey();
        _userPausedVideos[i] = false;
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
          !_userPausedVideos[mostVisibleIndex]!) {
        if (_currentlyPlayingIndex != null) {
          _videoControllers[_currentlyPlayingIndex]?.pause();
        }
        _videoControllers[mostVisibleIndex]?.play();
        setState(() {
          _currentlyPlayingIndex = mostVisibleIndex;
        });
      }
    } else if (_currentlyPlayingIndex != null &&
        !_userPausedVideos[_currentlyPlayingIndex]!) {
      _videoControllers[_currentlyPlayingIndex]?.pause();
      setState(() {
        _currentlyPlayingIndex = null;
      });
    }
  }

  Future<void> _sendGift(String postId) async {
    if (_currentUserId == null) return;
    
    final post = _posts.firstWhere((p) => p['key'] == postId);
    
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
    
    _loadGiftCounts();
  }

  Future<void> _toggleLike(String postKey) async {
    if (_currentUserId == null) return;

    final postRef = _database.child(postKey);
    final postSnapshot = await postRef.get();
    if (!postSnapshot.exists) return;

    final post = Map<String, dynamic>.from(postSnapshot.value as Map);
    final likes = Map<String, dynamic>.from(post['likes'] ?? {});
    final isLiked = likes[_currentUserId] == true;

    await postRef.update({
      'likes/$_currentUserId': isLiked ? null : true,
      'likesCount': isLiked ? (post['likesCount'] ?? 1) - 1 : (post['likesCount'] ?? 0) + 1,
    });
  }

  Future<void> _toggleSave(String postKey) async {
    if (_currentUserId == null) return;

    final userSavesRef = FirebaseDatabase.instance
        .ref('userSaves/$_currentUserId/$postKey');
    
    final saveSnapshot = await userSavesRef.get();
    final isSaved = saveSnapshot.exists;

    if (isSaved) {
      await userSavesRef.remove();
    } else {
      await userSavesRef.set(ServerValue.timestamp);
    }
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
          final user = post['userName'] as String? ?? 'Anonymous';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(_currentUserAvatar ?? 'https://i.pravatar.cc/150?img=1'),
                radius: 20,
              ),
              const SizedBox(width: 10),
              Text(
                _currentUserName ?? 'Loading...',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          IconButton(icon: const Icon(Icons.search), onPressed: _openSearchModal),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
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
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return Column(
                          children: [
                            PostCard(
                              post: post,
                              videoController: _videoControllers[index],
                              videoKey: _videoKeys[index],
                              isPlaying: index == _currentlyPlayingIndex,
                              isUserPaused: _userPausedVideos[index] ?? false,
                              onUserPause: (bool paused) {
                                setState(() {
                                  _userPausedVideos[index] = paused;
                                  if (paused) {
                                    _videoControllers[index]?.pause();
                                    if (_currentlyPlayingIndex == index) {
                                      _currentlyPlayingIndex = null;
                                    }
                                  } else {
                                    _handleScroll();
                                  }
                                });
                              },
                              currentUserId: _currentUserId,
                              onLike: (String postKey) => _toggleLike(postKey),
                              onSave: (String postKey) => _toggleSave(postKey),
                              onGift: (String postKey) => _sendGift(postKey),
                              giftCount: _giftCounts[post['key']] ?? 0,
                              hasGifted: _hasGifted[post['key']] ?? false,
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
              onLike: _toggleLike,
              onSave: _toggleSave,
              onGift: _sendGift,
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
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    super.dispose();
  }
}