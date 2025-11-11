import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:video_player/video_player.dart';

import '../widgets/comment_section.dart';
import 'edit_page.dart';

class UsersPost extends StatefulWidget {
  final Function(int)? onPostCountChanged;

  const UsersPost({Key? key, this.onPostCountChanged}) : super(key: key);

  @override
  _UsersPostState createState() => _UsersPostState();
}

class _UsersPostState extends State<UsersPost> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  List<Map<String, dynamic>> userPosts = [];
  bool loadingPosts = true;
  bool _isMounted = false;

  // Video management
  final Map<int, VideoPlayerController?> _videoControllers = {};
  final Map<int, bool> _userPausedVideos = {};
  final Map<int, Future<void>?> _videoInitializationFutures = {};
  int? _currentlyPlayingIndex;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadUserPosts();
  }

  @override
  void dispose() {
    _isMounted = false;
    // Dispose all video controllers
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    _videoControllers.clear();
    _userPausedVideos.clear();
    _videoInitializationFutures.clear();
    super.dispose();
  }

  Future<void> _loadUserPosts() async {
    if (!_isMounted) return;
    
    if (mounted) {
      setState(() => loadingPosts = true);
    }
    
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() => loadingPosts = false);
      }
      return;
    }

    try {
      final ref = _database.ref('posts');
      final query = ref.orderByChild('userId').equalTo(uid);
      final snapshot = await query.get();

      List<Map<String, dynamic>> posts = [];

      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          try {
            if (value is Map) {
              final Map<String, dynamic> post = Map<String, dynamic>.from(Map.castFrom(value));
              post['id'] = key.toString();

              // FIX: Get video URL from videoUrl field (like HomeFeedPage)
              String videoUrl = '';
              if (post['videoUrl'] is String && (post['videoUrl'] as String).isNotEmpty) {
                videoUrl = post['videoUrl'] as String;
              }
              
              // Normalize imageUrls for images
              if (post['imageUrls'] != null) {
                final raw = post['imageUrls'];
                if (raw is List) {
                  post['imageUrls'] = raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
                } else if (raw is Map) {
                  post['imageUrls'] = raw.values.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
                } else {
                  post['imageUrls'] = [raw.toString()];
                }
              } else if (post['mediaUrl'] != null) {
                post['imageUrls'] = [post['mediaUrl'].toString()];
              } else {
                post['imageUrls'] = <String>[];
              }

              // Store video URL separately for easy access
              post['_videoUrl'] = videoUrl;

              // Safe numeric fields
              post['likes'] = _toInt(post['likes']);
              post['comments'] = _toInt(post['commentCount'] ?? post['comments']);
              post['shares'] = _toInt(post['shares']);
              post['saves'] = _toInt(post['saves']);

              posts.add(post);
            }
          } catch (e) {
            debugPrint('Skipping post $key due to parsing error: $e');
          }
        });
      }

      // Sort by timestamp desc
      posts.sort((a, b) => (_toInt(b['timestamp'])).compareTo(_toInt(a['timestamp'])));

      if (mounted) {
        setState(() {
          userPosts = posts;
          widget.onPostCountChanged?.call(posts.length);
          _initializeVideoControllers();
        });
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
    }

    if (mounted) {
      setState(() => loadingPosts = false);
    }
  }

  void _initializeVideoControllers() {
    // Dispose existing controllers
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    _videoControllers.clear();
    _userPausedVideos.clear();
    _videoInitializationFutures.clear();

    // Initialize new controllers for video posts
    for (var i = 0; i < userPosts.length; i++) {
      final post = userPosts[i];
      final mediaType = (post['mediaType'] ?? 'image').toString();
      
      // FIX: Use the videoUrl field directly (like HomeFeedPage)
      final videoUrl = post['_videoUrl'] ?? '';
      
      if (mediaType == 'video' && videoUrl.isNotEmpty) {
        try {
          final controller = VideoPlayerController.network(videoUrl);
          _videoControllers[i] = controller;
          _userPausedVideos[i] = false;

          _videoInitializationFutures[i] = controller.initialize().then((_) {
            if (mounted) {
              setState(() {});
            }
            controller.setLooping(true);
          }).catchError((error) {
            debugPrint('Error initializing video controller: $error');
          });
        } catch (e) {
          debugPrint('Error creating video controller: $e');
        }
      }
    }
  }

  void _toggleVideoPlayback(int index) {
    if (!_videoControllers.containsKey(index)) return;

    final controller = _videoControllers[index];
    if (controller == null || !controller.value.isInitialized) return;

    if (mounted) {
      setState(() {
        if (controller.value.isPlaying) {
          controller.pause();
          _userPausedVideos[index] = true;
          if (_currentlyPlayingIndex == index) {
            _currentlyPlayingIndex = null;
          }
        } else {
          controller.play();
          _userPausedVideos[index] = false;
          _currentlyPlayingIndex = index;
          
          // Pause other videos
          for (var i = 0; i < userPosts.length; i++) {
            if (i != index && _videoControllers.containsKey(i)) {
              _videoControllers[i]?.pause();
            }
          }
        }
      });
    }
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  void _showShareModal(String postId) {
    final postUrl = 'https://yourapp.com/post/$postId';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Share Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              Divider(),
              ListTile(
                leading: Icon(Icons.copy, color: Colors.black),
                title: Text('Copy Link', style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Link copied to clipboard')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Colors.black),
                title: Text('Share via...', style: TextStyle(color: Colors.black)),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditModal(int index) {
    final post = userPosts[index];
    final mediaType = (post['mediaType'] ?? 'image').toString();
    final imageUrls = (post['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];
    final caption = (post['caption'] ?? '').toString();
    final videoUrl = post['_videoUrl'] ?? '';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPostPage(
          post: post,
          mediaType: mediaType,
          imageUrls: imageUrls,
          videoUrl: videoUrl,
          caption: caption,
          onSave: (newCaption, newImageUrls) {
            // Update the post with new data
            setState(() {
              userPosts[index]['caption'] = newCaption;
              userPosts[index]['imageUrls'] = newImageUrls;
            });
            // Here you would also update the post in the database
          },
          onDelete: () {
            // Delete the post
            setState(() {
              userPosts.removeAt(index);
            });
            // Here you would also delete the post from the database
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildPostGrid(List<Map<String, dynamic>> posts) {
    if (loadingPosts) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: CircularProgressIndicator()));
    }

    if (posts.isEmpty) {
      return Center(child: Text('No posts yet', style: TextStyle(color: Colors.black)));
    }

    return GridView.builder(
      itemCount: posts.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, index) {
        final post = posts[index];
        final mediaType = (post['mediaType'] ?? 'image').toString();
        final imageUrls = (post['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];
        final caption = (post['caption'] ?? '').toString();

        Widget content;
        if (mediaType == 'text') {
          content = Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Edit button for text posts
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _showEditModal(index),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (mediaType == 'image') {
          final displayUrls = imageUrls.isNotEmpty ? imageUrls : [''];
          content = ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Image carousel with page indicator
                _buildImageCarousel(displayUrls, caption),
                // Edit button for image posts
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _showEditModal(index),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (mediaType == 'video') {
          // FIX: Use the videoUrl field directly (like HomeFeedPage)
          final videoUrl = post['_videoUrl'] ?? '';
          final controller = _videoControllers[index];
          final isInitialized = controller != null && controller.value.isInitialized;
          final isPlaying = controller != null && controller.value.isPlaying;
          final isUserPaused = _userPausedVideos[index] ?? false;

          content = GestureDetector(
            onTap: () => _toggleVideoPlayback(index),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isInitialized
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 1, // Force square aspect ratio
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: controller!.value.size.width,
                                height: controller.value.size.height,
                                child: VideoPlayer(controller),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.videocam, size: 40, color: Colors.grey[600]),
                          ),
                        ),
                ),
                if (isInitialized && (!isPlaying || isUserPaused))
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.7), size: 56),
                    ),
                  ),
                if (!isInitialized)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (caption.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      color: Colors.black54,
                      child: Text(
                        caption,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                // Edit button for video posts
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _showEditModal(index),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          content = Container(
            color: Colors.grey[200],
            child: Stack(
              children: [
                Center(child: Icon(Icons.error, color: Colors.grey[600])),
                // Edit button for unknown post types
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _showEditModal(index),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final likes = _toInt(post['likes']);
        final comments = _toInt(post['comments']);
        final shares = _toInt(post['shares']);
        final saves = _toInt(post['saves']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: content,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _iconWithCount(Icons.favorite_border, likes, onTap: () {}),
                _iconWithCount(Icons.comment, comments, onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        body: CommentSection(postId: post['id'] ?? ''),
                      ),
                    ),
                  );
                }),
                _iconWithCount(Icons.share, shares, onTap: () {
                  _showShareModal(post['id'] ?? '');
                }),
                _iconWithCount(Icons.bookmark_border, saves, onTap: () {}),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageCarousel(List<String> imageUrls, String caption) {
    final PageController pageController = PageController();
    int currentPage = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Stack(
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final url = imageUrls[index];
                if (url.isEmpty) {
                  return Container(color: Colors.grey[300], child: Icon(Icons.broken_image));
                }
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null));
                  },
                  errorBuilder: (context, error, stack) => Container(
                    color: Colors.grey[300], 
                    child: Icon(Icons.broken_image, color: Colors.grey[600])
                  ),
                );
              },
            ),
            // Page indicator
            if (imageUrls.length > 1)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(imageUrls.length, (index) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentPage == index ? Colors.white : Colors.white54,
                      ),
                    );
                  }),
                ),
              ),
            // Caption
            if (caption.isNotEmpty)
              Positioned(
                bottom: imageUrls.length > 1 ? 24 : 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(6),
                  color: Colors.black54,
                  child: Text(
                    caption,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _iconWithCount(IconData icon, int count, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.black, size: 18),
          const SizedBox(width: 4),
          Text('$count', style: TextStyle(color: Colors.black, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPostGrid(userPosts);
  }
}