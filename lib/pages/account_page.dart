import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:video_player/video_player.dart';

import 'shop_page.dart';
import '../widgets/comment_section.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> userPosts = [];
  bool loadingUser = true;
  bool loadingPosts = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadUserData();
    await _loadUserPosts();
  }

  Future<void> _loadUserData() async {
    setState(() => loadingUser = true);
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => loadingUser = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        userData = doc.data();
      }
    } catch (e) {
      // ignore errors for now
      debugPrint('Error loading user: $e');
    }

    setState(() => loadingUser = false);
  }

  Future<void> _loadUserPosts() async {
    setState(() => loadingPosts = true);
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => loadingPosts = false);
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
              // normalize to Map<String, dynamic>
              final Map<String, dynamic> post = Map<String, dynamic>.from(Map.castFrom(value));
              post['id'] = key.toString();

              // normalize mediaUrls if it's a List or Map
              if (post['mediaUrls'] != null) {
                final raw = post['mediaUrls'];
                if (raw is List) {
                  post['mediaUrls'] = raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
                } else if (raw is Map) {
                  post['mediaUrls'] = raw.values.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
                } else {
                  post['mediaUrls'] = [raw.toString()];
                }
              } else if (post['mediaUrl'] != null) {
                post['mediaUrls'] = [post['mediaUrl'].toString()];
              } else {
                post['mediaUrls'] = <String>[];
              }

              // safe numeric fields
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

      // sort by timestamp desc if available
      posts.sort((a, b) => (_toInt(b['timestamp'])).compareTo(_toInt(a['timestamp'])));

      setState(() => userPosts = posts);
    } catch (e) {
      debugPrint('Error loading posts: $e');
    }

    setState(() => loadingPosts = false);
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  void _openSettings() {
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
              Text('Settings & Privacy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              Divider(),
              ListTile(
                leading: Icon(Icons.lock, color: Colors.black),
                title: Text('Privacy Settings', style: TextStyle(color: Colors.black)),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.monetization_on, color: Colors.black),
                title: Text('Monetization & Payments', style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _showMonetization();
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.black),
                title: Text('Log Out', style: TextStyle(color: Colors.black)),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMonetization() {
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
              Text('Monetization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              Divider(),
              ListTile(
                leading: Icon(Icons.attach_money, color: Colors.black),
                title: Text('Earnings Dashboard', style: TextStyle(color: Colors.black)),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.account_balance_wallet, color: Colors.black),
                title: Text('Payment Methods', style: TextStyle(color: Colors.black)),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.analytics, color: Colors.black),
                title: Text('Content Performance', style: TextStyle(color: Colors.black)),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  void _showShareModal(String postId) {
    final postUrl = 'https://yourapp.com/post/$postId'; // Replace with your actual post URL format
    
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
                  // Copy to clipboard functionality
                  // You'll need to add the clipboard package: import 'package:flutter/services.dart';
                  // Clipboard.setData(ClipboardData(text: postUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Link copied to clipboard')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Colors.black),
                title: Text('Share via...', style: TextStyle(color: Colors.black)),
                onTap: () {
                  // Implement native share functionality
                  // You might want to use the share_plus package for this
                },
              ),
            ],
          ),
        );
      },
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
        crossAxisCount: 2, // two columns
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, index) {
        final post = posts[index];
        final mediaType = (post['mediaType'] ?? 'image').toString();
        final mediaUrls = (post['mediaUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];
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
            child: Center(
              child: Text(
                caption,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        } else if (mediaType == 'image') {
          // show a PageView so user can swipe images inside the grid cell
          final displayUrls = mediaUrls.isNotEmpty ? mediaUrls : [''];
          content = ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                PageView(
                  children: displayUrls.map((url) {
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
                      errorBuilder: (context, error, stack) => Container(color: Colors.grey[300], child: Icon(Icons.broken_image)),
                    );
                  }).toList(),
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
              ],
            ),
          );
        } else if (mediaType == 'video') {
          content = VideoPostWidget(
            videoUrl: mediaUrls.isNotEmpty ? mediaUrls[0] : '',
            caption: caption,
          );
        } else {
          content = Container(color: Colors.grey[200]);
        }

        final likes = _toInt(post['likes']);
        final comments = _toInt(post['comments']);
        final shares = _toInt(post['shares']);
        final saves = _toInt(post['saves']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: content),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _iconWithCount(Icons.favorite_border, likes, onTap: () {}),
                _iconWithCount(Icons.comment, comments, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CommentSection(postId: post['id'] ?? '')));
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
    final name = (userData != null ? (userData!['fullName'] ?? userData!['username']) : 'Riak')?.toString() ?? 'Riak';
    final bio = (userData != null ? (userData!['bio'] ?? '') : '')?.toString() ?? '';
    final username = (userData != null ? (userData!['username'] ?? '') : '')?.toString() ?? '';
    final avatarUrl = (userData != null ? (userData!['avatarUrl'] ?? '') : '')?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(username.isNotEmpty ? username : 'Riak', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: Icon(Icons.settings, color: Colors.black), onPressed: _openSettings),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
          await _loadUserPosts();
        },
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Profile Header
            Column(
              children: [
                // Avatar with safe fallback
                ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: Icon(Icons.person, size: 36),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: Icon(Icons.person, size: 36),
                        ),
                ),

                const SizedBox(height: 10),
                Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(bio, textAlign: TextAlign.center, style: TextStyle(color: Colors.black)),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStat('124', 'Following'),
                    _buildStat('5.3K', 'Followers'),
                    _buildStat('${userPosts.length}', 'Posts'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildOutlinedButton('Edit Profile', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage()));
                    }),
                    const SizedBox(width: 10),
                    _buildOutlinedButton('Shop', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ShopPage()));
                    }),
                    const SizedBox(width: 10),
                    _buildOutlinedButton('Saved', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SavedPage()));
                    }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Your Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 10),
            _buildPostGrid(userPosts),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.black)),
      child: Text(text, style: TextStyle(color: Colors.black)),
    );
  }

  Widget _buildStat(String count, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// Video Post Widget with play functionality
class VideoPostWidget extends StatefulWidget {
  final String videoUrl;
  final String caption;

  const VideoPostWidget({Key? key, required this.videoUrl, required this.caption}) : super(key: key);

  @override
  _VideoPostWidgetState createState() => _VideoPostWidgetState();
}

class _VideoPostWidgetState extends State<VideoPostWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.isNotEmpty) {
      _controller = VideoPlayerController.network(widget.videoUrl)
        ..initialize().then((_) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(true);
        });
    } else {
      _isInitialized = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          if (!_isPlaying && _isInitialized)
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.7), size: 56),
              ),
            ),
          if (widget.caption.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(6),
                color: Colors.black54,
                child: Text(
                  widget.caption,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Saved Page (keeps original look)
class SavedPage extends StatelessWidget {
  final List<String> dummySaved = List.generate(6, (index) => 'https://via.placeholder.com/150/7f7fff');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Saved Contents'), backgroundColor: Colors.white, iconTheme: IconThemeData(color: Colors.black)),
      body: GridView.builder(
        itemCount: dummySaved.length,
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6),
        itemBuilder: (_, index) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(image: NetworkImage(dummySaved[index]), fit: BoxFit.cover),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }
}

// Edit Profile Page (simple local editor; you can extend to save to Firestore)
class EditProfilePage extends StatefulWidget {
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    // optionally prefill from Firestore if available
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() => saving = true);
                    // implement save to Firestore if you want
                    await Future.delayed(Duration(milliseconds: 600));
                    setState(() => saving = false);
                    Navigator.pop(context);
                  },
            child: Text('Save', style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(radius: 50, backgroundColor: Colors.grey[300], child: Icon(Icons.person, size: 40)),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                      child: Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _bioController, maxLines: 3, decoration: InputDecoration(labelText: 'Bio', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () {}, child: Text('Change Password')),
          ],
        ),
      ),
    );
  }
}