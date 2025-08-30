import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_database/firebase_database.dart';
import 'post_card.dart';

class SearchPage extends StatefulWidget {
  final String? currentUserId;
  final Map<String, bool> likedPosts;
  final Map<String, bool> savedPosts;
  final Map<String, bool> followingUsers;
  final Function(String) onLike;
  final Function(String) onSave;
  final Function(String) onGift;
  final Function(String) onFollow;
  final Map<String, int> giftCounts;
  final Map<String, bool> hasGifted;
  final Map<String, int> commentCounts;
  final Map<String, int> shareCounts;
  final Map<String, int> likeCounts;

  const SearchPage({
    required this.currentUserId,
    required this.likedPosts,
    required this.savedPosts,
    required this.followingUsers,
    required this.onLike,
    required this.onSave,
    required this.onGift,
    required this.onFollow,
    required this.giftCounts,
    required this.hasGifted,
    required this.commentCounts,
    required this.shareCounts,
    required this.likeCounts,
    Key? key,
  }) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String _searchQuery = "";
  List<Map<String, dynamic>> _filteredPosts = [];
  final Map<int, VideoPlayerController?> _videoControllers = {};
  final Map<int, GlobalKey> _videoKeys = {};
  final Map<int, bool> _isVideoInitialized = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _updateSearchQuery(_searchController.text);
    });
  }

  void _searchInDatabase(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredPosts.clear();
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final postsSnapshot = await _database.child('posts').get();
      
      if (postsSnapshot.exists && postsSnapshot.value is Map) {
        final postsData = postsSnapshot.value as Map<dynamic, dynamic>;
        final searchResults = <Map<String, dynamic>>[];

        postsData.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final post = Map<String, dynamic>.from(value);
            final userName = post['userName'] as String? ?? '';
            final caption = post['caption'] as String? ?? '';
            
            if (userName.toLowerCase().contains(query.toLowerCase()) ||
                caption.toLowerCase().contains(query.toLowerCase())) {
              post['key'] = key;
              searchResults.add(post);
            }
          }
        });

        setState(() {
          _filteredPosts = searchResults;
          _isLoading = false;
          _initializeVideoControllers();
        });
      } else {
        setState(() {
          _filteredPosts = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching database: $e');
      setState(() {
        _isLoading = false;
        _filteredPosts = [];
      });
    }
  }

  void _initializeVideoControllers() {
    // Clear existing controllers
    _videoControllers.forEach((index, controller) {
      controller?.dispose();
    });
    _videoControllers.clear();
    _videoKeys.clear();
    _isVideoInitialized.clear();

    for (var i = 0; i < _filteredPosts.length; i++) {
      final post = _filteredPosts[i];
      final mediaType = post['mediaType'];
      final videoUrl = post['videoUrl'];

      if (mediaType == 'video' && videoUrl is String && videoUrl.isNotEmpty) {
        try {
          final controller = VideoPlayerController.network(videoUrl);
          _videoControllers[i] = controller;
          _videoKeys[i] = GlobalKey();
          
          controller.initialize().then((_) {
            if (mounted) {
              setState(() {
                _isVideoInitialized[i] = true;
              });
            }
            controller.setLooping(true);
            // Ensure video starts paused
            controller.pause();
          }).catchError((error) {
            print('Error initializing video controller: $error');
          });
        } catch (e) {
          print('Error creating video controller: $e');
        }
      } else {
        // For images or non-video posts, mark as initialized
        _isVideoInitialized[i] = true;
      }
    }
  }

  void _handleVideoPlayPause(int index, bool play) {
    final controller = _videoControllers[index];
    if (controller != null && _isVideoInitialized[index] == true) {
      if (play) {
        controller.play();
      } else {
        controller.pause();
      }
    }
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });

    // Debounce the search to avoid too many database calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query && query.isNotEmpty) {
        _searchInDatabase(query);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Dispose all video controllers
    _videoControllers.forEach((index, controller) {
      controller?.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Search posts...',
            hintStyle: const TextStyle(color: Colors.black54),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () {
                _searchController.clear();
                _updateSearchQuery('');
              },
            ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _searchQuery.isEmpty
                ? const Center(
                    child: Text(
                      'Search for posts or users',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  )
                : _filteredPosts.isEmpty
                    ? const Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = _filteredPosts[index];
                          final isFollowing = widget.followingUsers[post['userId']] ?? false;
                          final isOwnPost = widget.currentUserId != null && post['userId'] == widget.currentUserId;
                          final isVideoInitialized = _isVideoInitialized[index] ?? false;

                          return Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                PostCard(
                                  post: post,
                                  videoController: _videoControllers[index],
                                  videoKey: _videoKeys[index],
                                  isPlaying: false, // Never auto-play
                                  isUserPaused: true, // Always start paused
                                  onUserPause: (bool paused) {
                                    _handleVideoPlayPause(index, !paused);
                                  },
                                  currentUserId: widget.currentUserId,
                                  isLiked: widget.likedPosts[post['key']] ?? false,
                                  isSaved: widget.savedPosts[post['key']] ?? false,
                                  isFollowing: isFollowing,
                                  showFollowButton: !isOwnPost,
                                  onLike: widget.onLike,
                                  onSave: widget.onSave,
                                  onGift: widget.onGift,
                                  onFollow: widget.onFollow,
                                  giftCount: widget.giftCounts[post['key']] ?? 0,
                                  hasGifted: widget.hasGifted[post['key']] ?? false,
                                  commentCount: widget.commentCounts[post['key']] ?? 0,
                                  shareCount: widget.shareCounts[post['key']] ?? 0,
                                  likeCount: widget.likeCounts[post['key']] ?? 0,
                                ),
                                const SizedBox(height: 8),
                                const Divider(height: 1, color: Colors.grey),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}