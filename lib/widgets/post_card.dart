import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'video_post.dart';
import 'image_post.dart';
import 'text_post.dart';
import 'comment_section.dart';
import '../pages/user_profile_page.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VideoPlayerController? videoController;
  final GlobalKey? videoKey;
  final bool isPlaying;
  final bool isUserPaused;
  final Function(bool) onUserPause;
  final String? currentUserId;
  final bool isLiked;
  final bool isSaved;
  final bool isFollowing;
  final bool showFollowButton;
  final Function(String) onLike;
  final Function(String) onSave;
  final Function(String) onGift;
  final Function(String) onFollow;
  final int giftCount;
  final int commentCount;
  final int shareCount;
  final bool hasGifted;
  final int likeCount;

  const PostCard({
    required this.post,
    this.videoController,
    this.videoKey,
    this.isPlaying = false,
    this.isUserPaused = false,
    required this.onUserPause,
    this.currentUserId,
    this.isLiked = false,
    this.isSaved = false,
    this.isFollowing = false,
    this.showFollowButton = true,
    required this.onLike,
    required this.onSave,
    required this.onGift,
    required this.onFollow,
    this.giftCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.hasGifted = false,
    this.likeCount = 0,
    Key? key,
  }) : super(key: key);
  

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(context),
          const SizedBox(height: 10),
          if (post['caption'] != null && post['caption'].toString().isNotEmpty)
            TextPost(text: post['caption'].toString()),
          const SizedBox(height: 10),
          if (post['mediaType'] == 'image' ||
              post['mediaType'] == 'multiple_images')
            ImagePost(post: post),
          if (post['mediaType'] == 'video')
            VideoPost(
              videoController: videoController,
              postId: post['key'] ?? '', // Use post key as postId
              userId: post['userId'] ?? '', // Use the user ID from post
              // You can also add other optional parameters if needed
              username: post['userName'] ?? '',
              userAvatar: post['userPhoto'] ?? '',
              caption: post['caption'] ?? '',
              likes: likeCount,
              comments: commentCount,
            ),
          const SizedBox(height: 10),
          _buildPostFooter(context),
        ],
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context) {
    return Row(
      children: [
        // Make the avatar clickable
        GestureDetector(
          onTap: () {
            if (post['userId'] != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    userId: post['userId'],
                    currentUserId: currentUserId,
                  ),
                ),
              );
            }
          },
          child: CircleAvatar(
            backgroundImage: NetworkImage(
              post['userPhoto'] ?? 'https://i.pravatar.cc/150',
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Make the username clickable
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (post['userId'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfilePage(
                      userId: post['userId'],
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              }
            },
            child: Text(
              post['userName'] ?? 'Anonymous',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        // Only show follow button if showFollowButton is true
        if (showFollowButton)
          TextButton(
            onPressed: () {
              if (post['userId'] != null) {
                onFollow(post['userId']);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: isFollowing ? Colors.grey : Colors.blue,
            ),
            child: Text(isFollowing ? 'Following' : 'Follow'),
          ),
      ],
    );
  }

  Widget _buildPostFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Like button and count
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.blue : Colors.black,
                  ),
                  onPressed: () => onLike(post['key']),
                ),
                Text(
                  '$likeCount',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),

            // Comment button and count
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.comment, color: Colors.black),
                  onPressed: () => _showComments(context),
                ),
                Text(
                  '$commentCount',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),

            // Share button and count
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.black),
                  onPressed: () {
                    _showShareOptions(context);
                  },
                ),
                Text(
                  '$shareCount',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),

            // Gift button and count
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    hasGifted
                        ? Icons.card_giftcard
                        : Icons.card_giftcard_outlined,
                    color: hasGifted ? Colors.pink : Colors.black,
                  ),
                  onPressed: () => onGift(post['key']),
                ),
                Text('$giftCount', style: const TextStyle(color: Colors.black)),
              ],
            ),

            // Spacer to push bookmark to the end
            const Spacer(),

            // Bookmark button
            IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? Colors.blue : Colors.black,
              ),
              onPressed: () => onSave(post['key']),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            _formatTimestamp(post['timestamp']),
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      context: context,
      builder: (_) => CommentSection(postId: post['key']),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.zero),
      ),
    );
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
    final String postUrl = 'https://yourapp.com/post/${post['key']}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied to clipboard: $postUrl'),
        duration: Duration(seconds: 2),
      ),
    );
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
}