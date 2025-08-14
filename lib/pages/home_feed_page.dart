import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: NoScrollbarBehavior(),
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black,
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(color: Colors.black),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.black),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
      home: Scaffold(body: HomeFeedPage()),
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

class HomeFeedPage extends StatefulWidget {
  @override
  _HomeFeedPageState createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  final String currentUserName = "John Doe";
  final String currentUserAvatar = "https://i.pravatar.cc/150?img=1";
  bool _showSearchModal = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final posts = [
    {
      'type': 'text',
      'user': 'John Doe',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'text':
          'Just enjoying a great day outside! #sunshine @naturelover https://example.com' *
          2,
    },
    {
      'type': 'video',
      'user': 'Video Fan',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'text': 'Watch this cool clip! #bee @insectlover https://flutter.dev',
      'videoUrl':
          'https://sample-videos.com/video123/mp4/480/asdasdas.mp4', // landscape
    },
    {
      'type': 'image',
      'user': 'Jane Smith',
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'text':
          'Check out this view! #landscape @travelgram https://picsum.photos ' *
          2,
      'imageUrls': [
        'https://picsum.photos/id/237/800/600',
        'https://picsum.photos/id/238/800/600',
        'https://picsum.photos/id/239/800/600',
        'https://picsum.photos/id/240/800/600',
        'https://picsum.photos/id/241/800/600',
        'https://picsum.photos/id/242/800/600',
        'https://picsum.photos/id/243/800/600',
        'https://picsum.photos/id/244/800/600',
      ],
    },
    {
      'type': 'video',
      'user': 'Tall Video Guy',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'text': 'Vertical vibes #reelstyle @portraitmode https://vertical.com',
      'videoUrl':
          'https://samplelib.com/lib/preview/mp4/sample-5s.mp4', // short & portrait-style
    },
    {
      'type': 'video',
      'user': 'Slow Motion Buff',
      'avatar': 'https://i.pravatar.cc/150?img=7',
      'text': 'Slow-mo magic! #slowmotion @videofx https://motionworld.com',
      'videoUrl':
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4', // original
    },
  ];

  List<Map<String, dynamic>> get _filteredPosts {
    if (_searchQuery.isEmpty) return [];
    return posts.where((post) {
      final user = post['user'] as String;
      final text = post['text'] as String;
      return user.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          text.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  final ScrollController _scrollController = ScrollController();
  final Map<int, VideoPlayerController?> _videoControllers = {};
  final Map<int, GlobalKey> _videoKeys = {};
  int? _currentlyPlayingIndex;
  final Map<int, bool> _userPausedVideos = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _initializeVideoControllers();
  }

  void _initializeVideoControllers() {
    for (var i = 0; i < posts.length; i++) {
      if (posts[i]['type'] == 'video') {
        _videoControllers[i] =
            VideoPlayerController.network(posts[i]['videoUrl'] as String)
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

    for (var i = 0; i < posts.length; i++) {
      if (posts[i]['type'] != 'video') continue;

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
                backgroundImage: NetworkImage(currentUserAvatar),
                radius: 20,
              ),
              SizedBox(width: 10),
              Text(
                currentUserName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          IconButton(icon: Icon(Icons.search), onPressed: _openSearchModal),
        ],
      ),
    );
  }

  Widget _buildSearchModal() {
    return ModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),

        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: Colors.black), // Text color when typing
              decoration: InputDecoration(
                hintText: 'Search posts...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                ), // Only the placeholder is grey
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.black,
                ), // Black search icon
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.black,
                  ), // Black close icon
                  onPressed: _closeSearchModal,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.black), // Black border
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.black,
                  ), // Black border when enabled
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.black,
                  ), // Black border when focused
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            SizedBox(height: 16),
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
                        final originalIndex = posts.indexWhere(
                          (p) => p == post,
                        );
                        if (originalIndex == -1) return SizedBox.shrink();

                        return Column(
                          children: [
                            PostCard(
                              post: post,
                              videoController: _videoControllers[originalIndex],
                              videoKey: _videoKeys[originalIndex],
                              isPlaying:
                                  originalIndex == _currentlyPlayingIndex,
                              isUserPaused:
                                  _userPausedVideos[originalIndex] ?? false,
                              onUserPause: (bool paused) {
                                setState(() {
                                  _userPausedVideos[originalIndex] = paused;
                                  if (paused) {
                                    _videoControllers[originalIndex]?.pause();
                                    if (_currentlyPlayingIndex ==
                                        originalIndex) {
                                      _currentlyPlayingIndex = null;
                                    }
                                  } else {
                                    _handleScroll();
                                  }
                                });
                              },
                            ),
                            SizedBox(height: 8),
                            Divider(height: 1, color: Colors.grey[300]),
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
  return SafeArea( // ✅ Prevents overlapping with status bar (time, battery, etc.)
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
                    await Future.delayed(Duration(seconds: 2));
                    setState(() {});
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
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
                          ),
                          SizedBox(height: 8),
                          Divider(height: 1, color: Colors.grey[300]),
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
      decoration: BoxDecoration(color: Colors.white),
      child: builder(context),
    );
  }
}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VideoPlayerController? videoController;
  final GlobalKey? videoKey;
  final bool isPlaying;
  final bool isUserPaused;
  final Function(bool) onUserPause;

  const PostCard({
    required this.post,
    this.videoController,
    this.videoKey,
    this.isPlaying = false,
    this.isUserPaused = false,
    required this.onUserPause,
  });

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isFollowing = false;
  bool liked = false;
  bool saved = false;
  bool expanded = false;
  int currentImageIndex = 0;
  bool _showVideoControls = false;
  bool _isVideoInitialized = false;
  final PageController _pageController = PageController();
  bool _controlsHovered = false;

  int likeCount = 12;
  int commentCount = 3;
  int shareCount = 5;

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
      // User had paused, now wants to resume
      widget.onUserPause(false);
    } else {
      // Video is playing, user wants to pause
      widget.onUserPause(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(post['avatar'])),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  post['user'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => isFollowing = !isFollowing),
                style: TextButton.styleFrom(
                  foregroundColor: isFollowing ? Colors.red : Colors.red,
                ),
                child: Text(isFollowing ? 'Following' : 'Follow'),
              ),
            ],
          ),
          SizedBox(height: 10),
          if (post['text'] != null) _buildPostText(post['text']),
          SizedBox(height: 10),
          if (post['type'] == 'image') _buildImageSlider(post),
          if (post['type'] == 'video')
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
                              colors: VideoProgressColors(
                                playedColor: Colors.red,
                                bufferedColor: Colors.grey,
                                backgroundColor: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(child: CircularProgressIndicator()),
          SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? Colors.red : Colors.black,
                ),
                onPressed: () => setState(() {
                  liked = !liked;
                  likeCount += liked ? 1 : -1;
                }),
              ),
              Text('$likeCount', style: TextStyle(color: Colors.black)),

              IconButton(
                icon: Icon(Icons.comment, color: Colors.black),
                onPressed: () {
                  _showComments(context);
                  setState(() => commentCount++);
                },
              ),
              Text('$commentCount', style: TextStyle(color: Colors.black)),

              IconButton(
                icon: Icon(Icons.share, color: Colors.black),
                onPressed: () {
                  _showShareOptions(context);
                  setState(() => shareCount++);
                },
              ),
              Text('$shareCount', style: TextStyle(color: Colors.black)),

              Spacer(),
              IconButton(
                icon: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  color: saved ? Colors.red : Colors.black,
                ),
                onPressed: () => setState(() => saved = !saved),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostText(String text) {
    final maxLines = expanded ? null : 1;
    final overflow = expanded ? TextOverflow.visible : TextOverflow.ellipsis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: maxLines,
          overflow: overflow,
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
        if (text.trim().length >
            30) // Only show if text is longer than 30 chars
          GestureDetector(
            onTap: () => setState(() => expanded = !expanded),
            child: Text(
              expanded ? "Read less" : "Read more",
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildImageSlider(Map<String, dynamic> post) {
    final List<String> images = List<String>.from(post['imageUrls']);
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
                        setState(() => currentImageIndex = index),
                    itemBuilder: (_, i) => Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.black,
                        child: Icon(Icons.error),
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
                        icon: Icon(
                          Icons.arrow_back_ios,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: Duration(milliseconds: 300),
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
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: Duration(milliseconds: 300),
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
        SizedBox(height: 8),
        if (images.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentImageIndex == index ? Colors.red : Colors.black,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              platform['color'] as Color? ??
                              Colors.grey.withOpacity(0.2),
                          child: Icon(
                            platform['icon'] as IconData,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          platform['name'] as String,
                          style: TextStyle(fontSize: 12, color: Colors.white),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      context: context,
      builder: (_) => CommentSection(),
    );
  }
}

class CommentSection extends StatefulWidget {
  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final List<Map<String, dynamic>> comments = [
    {
      'user': 'Alice',
      'avatar': 'https://i.pravatar.cc/150?img=4',
      'text': 'Nice!',
      'liked': false,
      'likeCount': 5,
      'replies': [
        {
          'user': 'Bob',
          'avatar': 'https://i.pravatar.cc/150?img=5',
          'text': 'Totally agree!',
          'liked': false,
          'likeCount': 2,
          'replies': [],
        },
      ],
    },
  ];

  final TextEditingController _inputController = TextEditingController();
  int? _replyingToIndex;
  int? _replyingToParentIndex;
  final Set<String> _expandedReplies = {};

  String _commentKey(int index, [int? parentIndex]) =>
      parentIndex != null ? '$parentIndex-$index' : '$index';

  void _submitInput() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    if (_replyingToIndex != null) {
      _addReply(text, _replyingToIndex!, _replyingToParentIndex);
    } else {
      _addComment(text);
    }

    _inputController.clear();
    _replyingToIndex = null;
    _replyingToParentIndex = null;
    setState(() {});
  }

  void _addComment(String text) {
    setState(() {
      comments.add({
        'user': 'You',
        'avatar': 'https://i.pravatar.cc/150?img=8',
        'text': text,
        'liked': false,
        'likeCount': 0,
        'replies': [],
      });
    });
  }

  void _addReply(String text, int parentIndex, [int? grandParentIndex]) {
    setState(() {
      final reply = {
        'user': 'You',
        'avatar': 'https://i.pravatar.cc/150?img=8',
        'text': text,
        'liked': false,
        'likeCount': 0,
        'replies': [],
      };

      if (grandParentIndex != null) {
        comments[grandParentIndex]['replies'][parentIndex]['replies'].add(
          reply,
        );
      } else {
        comments[parentIndex]['replies'].add(reply);
      }
    });
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
          // Main comment row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(comment['avatar']),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment['user'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            comment['text'],
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
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
                                SizedBox(width: 4),
                                Text(
                                  '(${comment['likeCount']})',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _replyingToIndex = index;
                              _replyingToParentIndex = parentIndex;
                              _inputController.text = '';
                            });
                          },
                          child: Text(
                            'Reply',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          '2h',
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
          // Recursively show replies if expanded
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
              title: Text('Comments', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.grey[900],
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.green),
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
                  children: comments.asMap().entries.map((entry) {
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
                      child: Text(
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
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: _replyingToIndex != null
                            ? 'Write a reply...'
                            : 'Add a comment...',
                        hintStyle: TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(
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
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.green),
                    onPressed: _submitInput,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
