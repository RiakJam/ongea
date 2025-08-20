// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class CommentSection extends StatefulWidget {
//   final String postId;

//   const CommentSection({required this.postId});

//   @override
//   State<CommentSection> createState() => _CommentSectionState();
// }

// class _CommentSectionState extends State<CommentSection> {
//   final TextEditingController _inputController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _replyingToCommentId;
//   String? _replyingToUsername;
//   final Set<String> _expandedReplies = {};

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.white,
//       child: Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).viewInsets.bottom,
//         ),
//         child: Column(
//           children: [
//             AppBar(
//               title: const Text('Comments', style: TextStyle(color: Colors.white)),
//               backgroundColor: Colors.grey[900],
//               elevation: 0,
//               automaticallyImplyLeading: false,
//               actions: [
//                 IconButton(
//                   icon: const Icon(Icons.close, color: Colors.white), // Changed to white
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ],
//             ),
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: _firestore
//                     .collection('posts')
//                     .doc(widget.postId)
//                     .collection('comments')
//                     .where('parentId', isEqualTo: null) // Only top-level comments
//                     .orderBy('timestamp', descending: false)
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   final comments = snapshot.data!.docs;

//                   return ScrollConfiguration(
//                     behavior: NoScrollbarBehavior(),
//                     child: ListView(
//                       physics: const BouncingScrollPhysics(),
//                       padding: const EdgeInsets.all(12),
//                       children: comments.map((doc) {
//                         return _buildComment(doc);
//                       }).toList(),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             Divider(color: Colors.grey[300]),
//             if (_replyingToUsername != null)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 4),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 12),
//                       child: Text(
//                         'Replying to $_replyingToUsername',
//                         style: TextStyle(color: Colors.black87),
//                       ),
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         setState(() {
//                           _replyingToCommentId = null;
//                           _replyingToUsername = null;
//                           _inputController.clear();
//                         });
//                       },
//                       child: const Text(
//                         'Cancel',
//                         style: TextStyle(color: Colors.redAccent),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _inputController,
//                       style: const TextStyle(color: Colors.black),
//                       decoration: InputDecoration(
//                         hintText: _replyingToCommentId != null
//                             ? 'Write a reply...'
//                             : 'Add a comment...',
//                         hintStyle: const TextStyle(color: Colors.black),
//                         filled: true,
//                         fillColor: Colors.grey[100],
//                         contentPadding: const EdgeInsets.symmetric(
//                           vertical: 12,
//                           horizontal: 16,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(24),
//                           borderSide: BorderSide.none,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   IconButton(
//                     icon: const Icon(Icons.send, color: Colors.black), // Changed to black
//                     onPressed: _postComment,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _postComment() async {
//     final text = _inputController.text.trim();
//     if (text.isEmpty) return;

//     final user = _auth.currentUser;
//     if (user == null) return;

//     final commentRef = _firestore
//         .collection('posts')
//         .doc(widget.postId)
//         .collection('comments')
//         .doc();

//     await commentRef.set({
//       'userId': user.uid,
//       'userName': user.displayName ?? 'Anonymous',
//       'userPhoto': user.photoURL ?? 'https://i.pravatar.cc/150',
//       'text': text,
//       'likes': {},
//       'likeCount': 0,
//       'timestamp': FieldValue.serverTimestamp(),
//       'parentId': _replyingToCommentId,
//     });

//     // Update comment count on the post
//     if (_replyingToCommentId == null) {
//       await _firestore.collection('posts').doc(widget.postId).update({
//         'commentCount': FieldValue.increment(1),
//       });
//     }

//     _inputController.clear();
//     setState(() {
//       _replyingToCommentId = null;
//       _replyingToUsername = null;
//     });
//   }

//   Widget _buildComment(DocumentSnapshot commentDoc) {
//     final comment = commentDoc.data() as Map<String, dynamic>;
//     final commentId = commentDoc.id;
//     final isExpanded = _expandedReplies.contains(commentId);

//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore
//           .collection('posts')
//           .doc(widget.postId)
//           .collection('comments')
//           .where('parentId', isEqualTo: commentId)
//           .orderBy('timestamp', descending: false)
//           .snapshots(),
//       builder: (context, snapshot) {
//         final replies = snapshot.data?.docs ?? [];
//         final replyCount = replies.length;

//         return Padding(
//           padding: const EdgeInsets.only(top: 12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   CircleAvatar(
//                     radius: 18,
//                     backgroundImage: NetworkImage(comment['userPhoto']),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(10),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[100],
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 comment['userName'],
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 comment['text'],
//                                 style: const TextStyle(color: Colors.black),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Row(
//                           children: [
//                             GestureDetector(
//                               onTap: () => _toggleLike(commentDoc),
//                               child: Row(
//                                 children: [
//                                   Text(
//                                     'Like',
//                                     style: TextStyle(
//                                       color: (comment['likes'] as Map).containsKey(_auth.currentUser?.uid)
//                                           ? Colors.red
//                                           : Colors.black,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                   if (comment['likeCount'] > 0) ...[
//                                     const SizedBox(width: 4),
//                                     Text(
//                                       '(${comment['likeCount']})',
//                                       style: TextStyle(color: Colors.grey[600]),
//                                     ),
//                                   ],
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             GestureDetector(
//                               onTap: () {
//                                 setState(() {
//                                   _replyingToCommentId = commentId;
//                                   _replyingToUsername = comment['userName'];
//                                   _inputController.text = '';
//                                 });
//                               },
//                               child: const Text(
//                                 'Reply',
//                                 style: TextStyle(color: Colors.grey),
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             Text(
//                               _formatTimestamp(comment['timestamp']?.millisecondsSinceEpoch ?? 0),
//                               style: TextStyle(
//                                 color: Colors.grey[400],
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),
//                         if (replyCount > 0)
//                           GestureDetector(
//                             onTap: () {
//                               setState(() {
//                                 if (isExpanded) {
//                                   _expandedReplies.remove(commentId);
//                                 } else {
//                                   _expandedReplies.add(commentId);
//                                 }
//                               });
//                             },
//                             child: Padding(
//                               padding: const EdgeInsets.only(top: 6),
//                               child: Text(
//                                 isExpanded
//                                     ? 'Hide Replies ($replyCount)'
//                                     : 'View Replies ($replyCount)',
//                                 style: TextStyle(
//                                   color: Colors.grey[700],
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               if (isExpanded)
//                 ...replies.map((replyDoc) {
//                   return Padding(
//                     padding: const EdgeInsets.only(left: 16.0),
//                     child: _buildComment(replyDoc),
//                   );
//                 }).toList(),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _toggleLike(DocumentSnapshot commentDoc) async {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     final commentRef = commentDoc.reference;
//     final comment = commentDoc.data() as Map<String, dynamic>;
//     final likes = comment['likes'] as Map<String, dynamic>;
//     final isLiked = likes.containsKey(user.uid);

//     await commentRef.update({
//       'likes.${user.uid}': isLiked ? FieldValue.delete() : true,
//       'likeCount': isLiked ? FieldValue.increment(-1) : FieldValue.increment(1),
//     });
//   }

//   String _formatTimestamp(int timestamp) {
//     final now = DateTime.now();
//     final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
//     final difference = now.difference(date);

//     if (difference.inDays > 365) {
//       return '${(difference.inDays / 365).floor()}y';
//     } else if (difference.inDays > 30) {
//       return '${(difference.inDays / 30).floor()}mo';
//     } else if (difference.inDays > 0) {
//       return '${difference.inDays}d';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m';
//     } else {
//       return 'Just now';
//     }
//   }
// }

// class NoScrollbarBehavior extends ScrollBehavior {
//   @override
//   Widget buildScrollbar(
//     BuildContext context,
//     Widget child,
//     ScrollableDetails details,
//   ) {
//     return child;
//   }

//   @override
//   Widget buildOverscrollIndicator(
//     BuildContext context,
//     Widget child,
//     ScrollableDetails details,
//   ) {
//     return child;
//   }

//   @override
//   ScrollPhysics getScrollPhysics(BuildContext context) {
//     return const BouncingScrollPhysics();
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentSection extends StatefulWidget {
  final String postId;

  const CommentSection({required this.postId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _inputController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _replyingToCommentId;
  String? _replyingToUsername;
  final Set<String> _expandedReplies = {};

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
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _database
                    .child('posts/${widget.postId}/comments')
                    .orderByChild('parentId')
                    .equalTo(null) // Only top-level comments
                    .onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final commentsData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
                  if (commentsData == null) {
                    return const Center(child: Text('No comments yet'));
                  }

                  // Convert to list and sort by timestamp
                  final commentsList = commentsData.entries.toList();
                  commentsList.sort((a, b) {
                    final aTimestamp = a.value['timestamp'] ?? 0;
                    final bTimestamp = b.value['timestamp'] ?? 0;
                    return aTimestamp.compareTo(bTimestamp);
                  });

                  return ScrollConfiguration(
                    behavior: NoScrollbarBehavior(),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      children: commentsList.map((entry) {
                        return _buildComment(entry.key, entry.value as Map<dynamic, dynamic>);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            Divider(color: Colors.grey[300]),
            if (_replyingToUsername != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Replying to $_replyingToUsername',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _replyingToCommentId = null;
                          _replyingToUsername = null;
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
                        hintText: _replyingToCommentId != null
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
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _postComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _postComment() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final commentKey = _database
        .child('posts/${widget.postId}/comments')
        .push()
        .key;

    if (commentKey == null) return;

    final commentData = {
      'userId': user.uid,
      'userName': user.displayName ?? 'Anonymous',
      'userPhoto': user.photoURL ?? 'https://i.pravatar.cc/150',
      'text': text,
      'likes': {},
      'likeCount': 0,
      'timestamp': ServerValue.timestamp,
      'parentId': _replyingToCommentId,
    };

    await _database
        .child('posts/${widget.postId}/comments/$commentKey')
        .set(commentData);

    // Update comment count on the post
    if (_replyingToCommentId == null) {
      final postRef = _database.child('posts/${widget.postId}');
      final postSnapshot = await postRef.get();
      
      if (postSnapshot.exists) {
        final postData = postSnapshot.value as Map<dynamic, dynamic>;
        final currentCount = postData['commentCount'] ?? 0;
        await postRef.update({'commentCount': currentCount + 1});
      } else {
        await postRef.update({'commentCount': 1});
      }
    }

    _inputController.clear();
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = null;
    });
  }

  Widget _buildComment(String commentId, Map<dynamic, dynamic> comment) {
    final isExpanded = _expandedReplies.contains(commentId);

    return StreamBuilder<DatabaseEvent>(
      stream: _database
          .child('posts/${widget.postId}/comments')
          .orderByChild('parentId')
          .equalTo(commentId)
          .onValue,
      builder: (context, snapshot) {
        final replies = <MapEntry<String, Map<dynamic, dynamic>>>[];
        int replyCount = 0;

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final repliesData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          replies.addAll(repliesData.entries.map((e) => 
            MapEntry(e.key as String, e.value as Map<dynamic, dynamic>)));
          
          replyCount = replies.length;
          
          // Sort replies by timestamp
          replies.sort((a, b) {
            final aTimestamp = a.value['timestamp'] ?? 0;
            final bTimestamp = b.value['timestamp'] ?? 0;
            return aTimestamp.compareTo(bTimestamp);
          });
        }

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(comment['userPhoto']?.toString() ?? 'https://i.pravatar.cc/150'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment['userName']?.toString() ?? 'Anonymous',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment['text']?.toString() ?? '',
                                style: const TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _toggleLike(commentId, comment),
                              child: Row(
                                children: [
                                  Text(
                                    'Like',
                                    style: TextStyle(
                                      color: _isCommentLikedByUser(comment)
                                          ? Colors.red
                                          : Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if ((comment['likeCount'] ?? 0) > 0) ...[
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
                                  _replyingToCommentId = commentId;
                                  _replyingToUsername = comment['userName']?.toString() ?? 'Anonymous';
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
                              _formatTimestamp(comment['timestamp'] ?? 0),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (replyCount > 0)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedReplies.remove(commentId);
                                } else {
                                  _expandedReplies.add(commentId);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                isExpanded
                                    ? 'Hide Replies ($replyCount)'
                                    : 'View Replies ($replyCount)',
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
                ...replies.map((replyEntry) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: _buildComment(replyEntry.key, replyEntry.value),
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  bool _isCommentLikedByUser(Map<dynamic, dynamic> comment) {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final likes = comment['likes'];
    if (likes is Map) {
      return likes.containsKey(user.uid);
    }
    return false;
  }

  Future<void> _toggleLike(String commentId, Map<dynamic, dynamic> comment) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final commentRef = _database.child('posts/${widget.postId}/comments/$commentId');
    final isLiked = _isCommentLikedByUser(comment);
    final currentLikeCount = comment['likeCount'] ?? 0;

    if (isLiked) {
      // Unlike the comment
      await commentRef.update({
        'likes/${user.uid}': null,
        'likeCount': currentLikeCount - 1,
      });
    } else {
      // Like the comment
      await commentRef.update({
        'likes/${user.uid}': true,
        'likeCount': currentLikeCount + 1,
      });
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    int ts;
    if (timestamp is int) {
      ts = timestamp;
    } else if (timestamp is String) {
      ts = int.tryParse(timestamp) ?? 0;
    } else {
      return 'Just now';
    }
    
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(ts);
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