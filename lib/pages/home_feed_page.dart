import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ongea/services/gift_page.dart';

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

  Widget _buildSearchModal() {
    return ModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search posts...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: _closeSearchModal,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
              onChanged: _updateSearchQuery,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchQuery.isEmpty
                  ? Center(
                      child: Text(
                        'Search for posts or users',
                        style: TextStyle(color: Colors.black),
                      ),
                    )
                  : _filteredPosts.isEmpty
                      ? Center(
                          child: Text(
                            'No results found',
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredPosts.length,
                          itemBuilder: (context, index) {
                            final post = _filteredPosts[index];
                            final originalIndex = _posts.indexWhere((p) => p['key'] == post['key']);
                            if (originalIndex == -1) return const SizedBox.shrink();

                            return Column(
                              children: [
                                PostCard(
                                  post: post,
                                  videoController: _videoControllers[originalIndex],
                                  videoKey: _videoKeys[originalIndex],
                                  isPlaying: originalIndex == _currentlyPlayingIndex,
                                  isUserPaused: _userPausedVideos[originalIndex] ?? false,
                                  onUserPause: (bool paused) {
                                    setState(() {
                                      _userPausedVideos[originalIndex] = paused;
                                      if (paused) {
                                        _videoControllers[originalIndex]?.pause();
                                        if (_currentlyPlayingIndex == originalIndex) {
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
          ],
        ),
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
          if (_showSearchModal) _buildSearchModal(),
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

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VideoPlayerController? videoController;
  final GlobalKey? videoKey;
  final bool isPlaying;
  final bool isUserPaused;
  final Function(bool) onUserPause;
  final String? currentUserId;
  final Function(String) onLike;
  final Function(String) onSave;
  final Function(String) onGift;
  final int giftCount;
  final bool hasGifted;

  const PostCard({
    required this.post,
    this.videoController,
    this.videoKey,
    this.isPlaying = false,
    this.isUserPaused = false,
    required this.onUserPause,
    this.currentUserId,
    required this.onLike,
    required this.onSave,
    required this.onGift,
    required this.giftCount,
    required this.hasGifted,
  });

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isFollowing = false;
  bool _expanded = false;
  int _currentImageIndex = 0;
  bool _showVideoControls = false;
  bool _isVideoInitialized = false;
  final PageController _pageController = PageController();
  bool _controlsHovered = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoController != null) {
      widget.videoController!.addListener(_videoListener);
      if (widget.videoController!.value.isInitialized) {
        _isVideoInitialized = true;
      } else {
        widget.videoController!.initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      setState(() {
        _showVideoControls = false;
      });
    }
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (widget.videoController != null) {
      widget.videoController!.removeListener(_videoListener);
    }
    _pageController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (widget.isUserPaused) {
      widget.onUserPause(false);
    } else {
      widget.onUserPause(true);
    }
  }

  bool get _isLiked {
    if (widget.currentUserId == null) return false;
    final likes = widget.post['likes'] is Map ? widget.post['likes'] as Map : {};
    return likes[widget.currentUserId] == true;
  }

  bool get _isSaved {
    return false;
  }

  int get _likeCount {
    return widget.post['likesCount'] as int? ?? 0;
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(post['userPhoto'] ?? 'https://i.pravatar.cc/150'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  post['userName'] ?? 'Anonymous',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _isFollowing = !_isFollowing),
                style: TextButton.styleFrom(
                  foregroundColor: _isFollowing ? Colors.red : Colors.red,
                ),
                child: Text(_isFollowing ? 'Following' : 'Follow'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (post['caption'] != null && post['caption'].toString().isNotEmpty)
            _buildPostText(post['caption'].toString()),
          const SizedBox(height: 10),
          if (post['mediaType'] == 'single_image' || post['mediaType'] == 'multiple_images')
            _buildImageSlider(post),
          if (post['mediaType'] == 'video')
            _isVideoInitialized
                ? GestureDetector(
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
                            aspectRatio:
                                widget.videoController!.value.aspectRatio,
                            child: VideoPlayer(widget.videoController!),
                          ),
                          if (_showVideoControls ||
                              _controlsHovered ||
                              !widget.isPlaying ||
                              widget.isUserPaused)
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: _togglePlayPause,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  color: Colors.black.withOpacity(0.3),
                                  child: Center(
                                    child: IconButton(
                                      icon: Icon(
                                        widget.isUserPaused
                                            ? Icons.play_arrow
                                            : Icons.pause,
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
                  )
                : const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.black,
                ),
                onPressed: () => widget.onLike(post['key']),
              ),
              Text('$_likeCount', style: const TextStyle(color: Colors.black)),
              IconButton(
                icon: const Icon(Icons.comment, color: Colors.black),
                onPressed: () => _showComments(context),
              ),
              const Text('0', style: TextStyle(color: Colors.black)),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.black),
                onPressed: () => _showShareOptions(context),
              ),
              IconButton(
                icon: Icon(
                  widget.hasGifted ? Icons.card_giftcard : Icons.card_giftcard_outlined,
                  color: widget.hasGifted ? Colors.pink : Colors.black,
                ),
                onPressed: () => widget.onGift(post['key']),
              ),
              Text(
                '${widget.giftCount}',
                style: const TextStyle(color: Colors.black),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: _isSaved ? Colors.red : Colors.black,
                ),
                onPressed: () => widget.onSave(post['key']),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              _formatTimestamp(post['timestamp']),
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostText(String text) {
    final maxLines = _expanded ? null : 3;
    final overflow = _expanded ? TextOverflow.visible : TextOverflow.ellipsis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: maxLines,
          overflow: overflow,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
        if (text.length > 100)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? "Read less" : "Read more",
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildImageSlider(Map<String, dynamic> post) {
    final List<String> images = post['mediaType'] == 'single_image'
        ? [post['imageUrls'][0]]
        : List<String>.from(post['imageUrls'] ?? []);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                SizedBox(
                  height: constraints.maxWidth * 0.75,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) =>
                        setState(() => _currentImageIndex = index),
                    itemBuilder: (_, i) => Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.black,
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
                if (images.length > 1) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        if (images.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index ? Colors.red : Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showShareOptions(BuildContext context) {
    final platforms = [
      {
        'icon': FontAwesomeIcons.link,
        'name': 'Copy Link',
        'color': Colors.blue,
      },
      {
        'icon': FontAwesomeIcons.facebookMessenger,
        'name': 'Messages',
        'color': Color(0xFF00B2FF),
      },
      {
        'icon': FontAwesomeIcons.envelope,
        'name': 'Email',
        'color': Colors.grey,
      },
      {
        'icon': FontAwesomeIcons.facebook,
        'name': 'Facebook',
        'color': Color(0xFF1877F2),
      },
      {
        'icon': FontAwesomeIcons.whatsapp,
        'name': 'WhatsApp',
        'color': Color(0xFF25D366),
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => SizedBox(
        height: 160,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Share to',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: platforms.length,
                itemBuilder: (context, index) {
                  final platform = platforms[index];
                  return Container(
                    width: 80,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              platform['color'] as Color? ?? Colors.grey.withOpacity(0.2),
                          child: Icon(
                            platform['icon'] as IconData,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          platform['name'] as String,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      context: context,
      builder: (_) => CommentSection(postId: widget.post['key']),
    );
  }
}

class CommentSection extends StatefulWidget {
  final String postId;

  const CommentSection({required this.postId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _inputController = TextEditingController();
  int? _replyingToIndex;
  int? _replyingToParentIndex;
  final Set<String> _expandedReplies = {};

  // In a real app, you would fetch comments from Firebase
  final List<Map<String, dynamic>> _comments = [
    {
      'user': 'Alice',
      'avatar': 'https://i.pravatar.cc/150?img=4',
      'text': 'Nice!',
      'liked': false,
      'likeCount': 5,
      'timestamp': DateTime.now().subtract(Duration(hours: 2)).millisecondsSinceEpoch,
      'replies': [
        {
          'user': 'Bob',
          'avatar': 'https://i.pravatar.cc/150?img=5',
          'text': 'Totally agree!',
          'liked': false,
          'likeCount': 2,
          'timestamp': DateTime.now().subtract(Duration(hours: 1)).millisecondsSinceEpoch,
          'replies': [],
        },
      ],
    },
  ];

  String _commentKey(int index, [int? parentIndex]) =>
      parentIndex != null ? '$parentIndex-$index' : '$index';

  String _formatTimestamp(int timestamp) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            AppBar(
              title: const Text('Comments', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.grey[900],
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.green),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: NoScrollbarBehavior(),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  children: _comments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final comment = entry.value;
                    return _buildComment(comment, index);
                  }).toList(),
                ),
              ),
            ),
            Divider(color: Colors.grey[300]),
            if (_replyingToIndex != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Replying...',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _replyingToIndex = null;
                          _replyingToParentIndex = null;
                          _inputController.clear();
                        });
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: _replyingToIndex != null
                            ? 'Write a reply...'
                            : 'Add a comment...',
                        hintStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.green),
                    onPressed: () {
                      // In a real app, you would save the comment to Firebase
                      _inputController.clear();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComment(
    Map<String, dynamic> comment,
    int index, [
    int? parentIndex,
  ]) {
    final key = _commentKey(index, parentIndex);
    final replies = comment['replies'] as List;
    final isExpanded = _expandedReplies.contains(key);

    return Padding(
      padding: EdgeInsets.only(left: (parentIndex != null ? 16.0 : 0), top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(comment['avatar']),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment['user'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment['text'],
                            style: const TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              comment['liked'] = !comment['liked'];
                              comment['likeCount'] += comment['liked'] ? 1 : -1;
                            });
                          },
                          child: Row(
                            children: [
                              Text(
                                'Like',
                                style: TextStyle(
                                  color: comment['liked']
                                      ? Colors.red
                                      : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (comment['likeCount'] > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(${comment['likeCount']})',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _replyingToIndex = index;
                              _replyingToParentIndex = parentIndex;
                              _inputController.text = '';
                            });
                          },
                          child: const Text(
                            'Reply',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatTimestamp(comment['timestamp']),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (replies.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedReplies.remove(key);
                            } else {
                              _expandedReplies.add(key);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            isExpanded
                                ? 'Hide Replies (${replies.length})'
                                : 'View Replies (${replies.length})',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isExpanded)
            ...replies.asMap().entries.map((entry) {
              final i = entry.key;
              final reply = entry.value;
              return _buildComment(reply, i, index);
            }).toList(),
        ],
      ),
    );
  }
}

class ModalBottomSheet extends StatelessWidget {
  final BuildContext context;
  final Widget Function(BuildContext) builder;

  const ModalBottomSheet({
    required this.context,
    required this.builder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: builder(context),
    );
  }
}

class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}