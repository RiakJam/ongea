import 'package:flutter/material.dart';
import 'chat_detail_page.dart';

class ConversationsListPage extends StatelessWidget {
  final List<Map<String, dynamic>> conversations = [
    {
      'id': '1',
      'name': 'John Doe',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'lastMessage': 'Hey, how are you doing?',
      'time': '10:30 AM',
      'unreadCount': 2,
      'isOnline': true,
    },
    {
      'id': '2',
      'name': 'Jane Smith',
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'lastMessage': 'Meeting at 3pm tomorrow',
      'time': '9:45 AM',
      'unreadCount': 0,
      'isOnline': false,
    },
    {
      'id': '3',
      'name': 'Mike Johnson',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'lastMessage': 'Did you see the latest update?',
      'time': 'Yesterday',
      'unreadCount': 5,
      'isOnline': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text('Chats', style: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        color: Colors.white, // Set ListView background to white
        child: ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(conversation['avatar']),
                    radius: 24,
                  ),
                  if (conversation['isOnline'])
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                conversation['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              subtitle: Text(
                conversation['lastMessage'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.black87),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    conversation['time'],
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (conversation['unreadCount'] > 0)
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        conversation['unreadCount'].toString(),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatDetailPage(conversation: conversation),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}