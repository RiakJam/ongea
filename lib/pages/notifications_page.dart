import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'post_detail_page.dart'; // You'll need to create this

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    if (_currentUserId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _database
        .child('notifications/$_currentUserId')
        .orderByChild('timestamp')
        .onValue
        .listen((DatabaseEvent event) {
      try {
        final data = event.snapshot.value;
        final List<Map<String, dynamic>> notificationsList = [];

        if (data != null && data is Map<dynamic, dynamic>) {
          data.forEach((key, value) {
            if (value is Map<dynamic, dynamic>) {
              final notification = Map<String, dynamic>.from(value);
              notification['key'] = key;
              notificationsList.add(notification);
            }
          });

          // Sort by timestamp (newest first)
          notificationsList.sort((a, b) {
            final aTimestamp = a['timestamp'] ?? 0;
            final bTimestamp = b['timestamp'] ?? 0;
            return (bTimestamp is int ? bTimestamp : 0).compareTo(
              aTimestamp is int ? aTimestamp : 0,
            );
          });
        }

        setState(() {
          _notifications = notificationsList;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading notifications: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print('Error loading notifications: $error');
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _markAsRead(String notificationKey) async {
    if (_currentUserId == null) return;
    
    try {
      await _database
          .child('notifications/$_currentUserId/$notificationKey/isRead')
          .set(true);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  String _formatTimestamp(int timestamp) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      case 'share':
        return Icons.share;
      case 'save':
        return Icons.bookmark;
      case 'system':
        return Icons.info;
      case 'monetization':
        return Icons.monetization_on;
      case 'new_post':
        return Icons.add_circle;
      case 'reply':
        return Icons.reply;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'follow':
        return Colors.green;
      case 'share':
        return Colors.orange;
      case 'save':
        return Colors.purple;
      case 'system':
        return Colors.grey;
      case 'monetization':
        return Colors.amber;
      case 'new_post':
        return Colors.teal;
      case 'reply':
        return Colors.indigo;
      default:
        return Colors.black;
    }
  }

  String _getNotificationMessage(Map<String, dynamic> notification) {
    final type = notification['type'] as String? ?? '';
    final userName = notification['userName'] as String? ?? 'Someone';
    final postPreview = notification['postPreview'] as String? ?? '';
    
    switch (type) {
      case 'like':
        return '$userName liked your post "$postPreview"';
      case 'comment':
        return '$userName commented on your post "$postPreview"';
      case 'reply':
        return '$userName replied to your comment on "$postPreview"';
      case 'follow':
        return '$userName started following you';
      case 'share':
        return '$userName shared your post "$postPreview"';
      case 'save':
        return '$userName saved your post "$postPreview"';
      case 'new_post':
        return '$userName posted something new: "$postPreview"';
      case 'system':
        return notification['message'] as String? ?? 'System notification';
      case 'monetization':
        return notification['message'] as String? ?? 'You earned money';
      default:
        return 'New notification';
    }
  }

  void _navigateToPost(BuildContext context, Map<String, dynamic> notification) {
    final postId = notification['postId'] as String?;
    final type = notification['type'] as String? ?? '';
    
    if (postId != null && postId.isNotEmpty) {
      // Mark notification as read
      final notificationKey = notification['key'] as String?;
      if (notificationKey != null) {
        _markAsRead(notificationKey);
      }
      
      // Navigate to post detail page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailPage(
            postId: postId,
            highlightComment: type == 'comment' || type == 'reply' 
                ? notification['commentId'] as String? 
                : null,
          ),
        ),
      );
    } else if (type == 'follow') {
      // Navigate to user profile
      final userId = notification['userId'] as String?;
      if (userId != null) {
        // Navigate to user profile page
        // Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfilePage(userId: userId)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: true,
        title: Text('Notifications', style: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.checklist),
              onPressed: () {
                // Mark all as read functionality
                for (var notification in _notifications) {
                  final key = notification['key'] as String?;
                  if (key != null) {
                    _markAsRead(key);
                  }
                }
              },
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No notifications yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 0, color: Colors.grey.shade300),
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final type = notification['type'] as String? ?? '';
                    final isRead = notification['isRead'] as bool? ?? false;
                    final timestamp = notification['timestamp'] as int? ?? 0;
                    final userAvatar = notification['userAvatar'] as String?;
                    
                    return ListTile(
                      tileColor: isRead ? Colors.white : Colors.blue.shade50,
                      leading: userAvatar != null && userAvatar.isNotEmpty
                          ? CircleAvatar(backgroundImage: NetworkImage(userAvatar))
                          : CircleAvatar(
                              backgroundColor: _getIconColor(type).withOpacity(0.1),
                              child: Icon(_getIcon(type), color: _getIconColor(type), size: 20),
                            ),
                      title: Text(
                        _getNotificationMessage(notification),
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(color: Colors.grey),
                      ),
                      trailing: !isRead
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      onTap: () => _navigateToPost(context, notification),
                    );
                  },
                ),
    );
  }
}