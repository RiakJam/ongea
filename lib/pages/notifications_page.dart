import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  final List<Map<String, dynamic>> notifications = [
    {
      'type': 'like',
      'user': 'Alice',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'message': 'liked your post.',
      'time': '2m ago',
    },
    {
      'type': 'comment',
      'user': 'Bob',
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'message': 'commented: "Awesome picture!"',
      'time': '5m ago',
    },
    {
      'type': 'follow',
      'user': 'Charlie',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'message': 'started following you.',
      'time': '10m ago',
    },
    {
      'type': 'share',
      'user': 'Dana',
      'avatar': 'https://i.pravatar.cc/150?img=4',
      'message': 'shared your post.',
      'time': '20m ago',
    },
    {
      'type': 'save',
      'user': 'Eve',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'message': 'saved your photo.',
      'time': '30m ago',
    },
    {
      'type': 'system',
      'user': null,
      'avatar': null,
      'message': 'Your password was updated successfully.',
      'time': '1h ago',
    },
    {
      'type': 'monetization',
      'user': null,
      'avatar': null,
      'message': 'You’ve earned \$2.50 from ad revenue.',
      'time': '2h ago',
    },
  ];

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
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.green;
      case 'follow':
        return Colors.blue;
      case 'share':
        return Colors.orange;
      case 'save':
        return Colors.purple;
      case 'system':
        return Colors.grey;
      case 'monetization':
        return Colors.amber;
      default:
        return Colors.white;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: true, // <- Shows the back button
        title: Text('Notifications', style: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(color: Colors.black), // Makes back arrow black
      ),
      body: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (_, __) =>
            Divider(height: 0, color: Colors.grey.shade300),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final type = notif['type'] as String;

          return ListTile(
            tileColor: Colors.white,
            leading: notif['avatar'] != null
                ? CircleAvatar(backgroundImage: NetworkImage(notif['avatar']))
                : CircleAvatar(
                    backgroundColor: _getIconColor(type).withOpacity(0.1),
                    child: Icon(_getIcon(type), color: _getIconColor(type)),
                  ),
            title: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black),
                children: [
                  if (notif['user'] != null)
                    TextSpan(
                      text: notif['user'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  if (notif['user'] != null) TextSpan(text: ' '),
                  TextSpan(text: notif['message']),
                ],
              ),
            ),
            subtitle: Text(notif['time'], style: TextStyle(color: Colors.grey)),
            onTap: () {
              // Optional: handle notification tap
            },
          );
        },
      ),
    );
  }
}

