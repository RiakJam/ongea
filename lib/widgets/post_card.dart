import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'video_post.dart';
import 'image_post.dart';
import 'text_post.dart';
import 'comment_section.dart';

class PostCard extends StatelessWidget {
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

  bool get _isLiked {
    if (currentUserId == null) return false;
    final likes = post['likes'] is Map ? post['likes'] as Map : {};
    return likes[currentUserId] == true;
  }

  int get _likeCount {
    return post['likesCount'] as int? ?? 0;
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == null) return '';
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
          _buildPostHeader(),
          const SizedBox(height: 10),
          if (post['caption'] != null && post['caption'].toString().isNotEmpty)
            TextPost(text: post['caption'].toString()),
          const SizedBox(height: 10),
          if (post['mediaType'] == 'single_image' ||
              post['mediaType'] == 'multiple_images')
            ImagePost(post: post),
          if (post['mediaType'] == 'video')
            VideoPost(
              videoController: videoController,
              videoKey: videoKey,
              isPlaying: isPlaying,
              isUserPaused: isUserPaused,
              onUserPause: onUserPause,
            ),
          const SizedBox(height: 10),
          _buildPostFooter(context), // Pass context here
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(
            post['userPhoto'] ?? 'https://i.pravatar.cc/150',
          ),
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
          onPressed: () {},
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Follow'),
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
            IconButton(
              icon: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.black,
              ),
              onPressed: () => onLike(post['key']),
            ),
            Text('$_likeCount', style: const TextStyle(color: Colors.black)),

            // Comment button and count
            IconButton(
              icon: const Icon(Icons.comment, color: Colors.black),
              onPressed: () => _showComments(context),
            ),
            const Text('0', style: TextStyle(color: Colors.black)),

            // Share button
            IconButton(
              icon: const Icon(Icons.share, color: Colors.black),
              onPressed: () {
                _showShareOptions(context);
                // Add your share functionality here
                // Example: _shareToDatabase(post['key']);
              },
            ),

            // Gift button and count
            IconButton(
              icon: Icon(
                hasGifted ? Icons.card_giftcard : Icons.card_giftcard_outlined,
                color: hasGifted ? Colors.pink : Colors.black,
              ),
              onPressed: () => onGift(post['key']),
            ),
            Text('$giftCount', style: const TextStyle(color: Colors.black)),

            // Spacer to push bookmark to the end
            const Spacer(),

            // Bookmark button
            IconButton(
              icon: const Icon(Icons.bookmark_border, color: Colors.black),
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
                              platform['color'] as Color? ??
                              Colors.grey.withOpacity(0.2),
                          child: Icon(
                            platform['icon'] as IconData,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          platform['name'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
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
}
