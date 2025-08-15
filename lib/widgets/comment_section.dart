import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

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