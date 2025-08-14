import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DM',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: ConversationsListPage(),
    );
  }
}

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
                        color: Colors.green,
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

class ChatDetailPage extends StatefulWidget {
  final Map<String, dynamic> conversation;

  const ChatDetailPage({required this.conversation});

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final List<Map<String, dynamic>> messages = [
    {
      'sender': 'me',
      'text': 'Hey there! How are you doing today?',
      'status': 'sent',
      'time': '10:30 AM',
    },
    {
      'sender': 'me',
      'text': 'Did you check that link I sent you about the project?',
      'status': 'delivered',
      'time': '10:32 AM',
    },
    {
      'sender': 'other',
      'text':
          'Yes I did! Looks really great. I think we should move forward with this approach.',
      'time': '10:45 AM',
    },
    {
      'sender': 'me',
      'text': 'Awesome! 😄 I\'ll start working on the implementation then.',
      'status': 'seen',
      'time': '10:46 AM',
    },
    {
      'sender': 'other',
      'text': 'Perfect! Let me know if you need any help.',
      'time': '10:48 AM',
    },
  ];

  final TextEditingController _controller = TextEditingController();
  bool _showMediaOptions = false;

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      messages.add({
        'sender': 'me',
        'text': text,
        'status': 'sent',
        'time': _formatTime(DateTime.now()),
      });
    });
    _controller.clear();
  }

  void _sendMedia(String type) {
    setState(() {
      messages.add({
        'sender': 'me',
        'type': type,
        'content': type == 'image'
            ? 'https://picsum.photos/300/200'
            : 'Video File',
        'status': 'sent',
        'time': _formatTime(DateTime.now()),
      });
      _showMediaOptions = false;
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTick(String status) {
    switch (status) {
      case 'sent':
        return Icon(Icons.check, size: 14, color: Colors.grey.shade600);
      case 'delivered':
        return Icon(Icons.done_all, size: 14, color: Colors.grey.shade600);
      case 'seen':
        return Icon(Icons.done_all, size: 14, color: Colors.blue.shade700);
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['sender'] == 'me';
    final isMedia = message['type'] != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.green.shade100 : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMe ? 16 : 0),
                topRight: Radius.circular(isMe ? 0 : 16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMedia && message['type'] == 'image')
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      message['content'],
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (isMedia && message['type'] == 'video')
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        size: 50,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                if (!isMedia)
                  Text(
                    message['text'],
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message['time'],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isMe && message['status'] != null) ...[
                      SizedBox(width: 4),
                      _buildTick(message['status']),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ), // Black back button
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.conversation['avatar']),
                  radius: 20,
                ),
                if (widget.conversation['isOnline'])
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black, // Black user name
                  ),
                ),
                Text(
                  widget.conversation['isOnline'] ? 'Online' : 'Offline',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(
          color: Colors.black,
        ), // Makes all app bar icons black
        actions: [IconButton(icon: Icon(Icons.more_vert), onPressed: () {})],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: ListView.builder(
                reverse: true,
                padding: EdgeInsets.only(top: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final reversedIndex = messages.length - 1 - index;
                  return _buildMessageBubble(messages[reversedIndex]);
                },
              ),
            ),
          ),
          if (_showMediaOptions)
            Container(
              height: 120,
              color: Colors.white,
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMediaOption(Icons.photo, 'Photo', 'image'),
                  _buildMediaOption(Icons.videocam, 'Video', 'video'),
                  _buildMediaOption(
                    Icons.insert_drive_file,
                    'Document',
                    'document',
                  ),
                ],
              ),
            ),
          Container(
            color: Colors.grey.shade50,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add, color: Colors.green.shade700),
                  onPressed: () {
                    setState(() {
                      _showMediaOptions = !_showMediaOptions;
                    });
                  },
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            maxLines: 3,
                            minLines: 1,
                            style: TextStyle(
                              color: Colors.black,
                            ), // Add this line to set text color to black
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                              ), // Optional: style for hint text
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.green.shade700,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOption(IconData icon, String label, String type) {
    return InkWell(
      onTap: () => _sendMedia(type),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.withOpacity(0.1),
            child: Icon(icon, color: Colors.green.shade700),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

