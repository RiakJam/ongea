import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ongea/services/gift_page.dart';

class ChatDetailPage extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String recipientAvatar;

  const ChatDetailPage({
    required this.recipientId,
    required this.recipientName,
    required this.recipientAvatar,
    Key? key,
  }) : super(key: key);

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _controller = TextEditingController();
  
  late String _currentUserId;
  late String _chatId;
  late DatabaseReference _messagesRef;
  late DatabaseReference _conversationRef;
  
  List<Map<String, dynamic>> messages = [];
  StreamSubscription<DatabaseEvent>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid ?? '';
    _initializeChat();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _initializeChat() {
    // Generate unique chat ID based on user IDs (sorted to ensure consistency)
    final List<String> userIds = [_currentUserId, widget.recipientId];
    userIds.sort();
    _chatId = userIds.join('_');

    _messagesRef = _database.child('chats/$_chatId/messages');
    _conversationRef = _database.child('conversations/$_chatId');

    _setupConversation();
    _listenForMessages();
  }

  void _setupConversation() {
    // Create/update conversation metadata
    _conversationRef.set({
      'participants': {
        _currentUserId: true,
        widget.recipientId: true,
      },
      'lastMessage': '',
      'lastMessageTime': ServerValue.timestamp,
      'lastMessageSender': _currentUserId,
      'updatedAt': ServerValue.timestamp,
    });
  }

  void _listenForMessages() {
    _messagesSubscription = _messagesRef
        .orderByChild('timestamp')
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> loadedMessages = [];

        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final message = Map<String, dynamic>.from(value);
            message['key'] = key;
            loadedMessages.add(message);
          }
        });

        // Sort by timestamp
        loadedMessages.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

        setState(() {
          messages = loadedMessages;
        });

        // Mark messages as read
        _markMessagesAsRead();
      } else {
        setState(() {
          messages = [];
        });
      }
    });
  }

  void _markMessagesAsRead() {
    // Mark all messages from recipient as read
    for (var message in messages) {
      if (message['senderId'] != _currentUserId && message['status'] != 'read') {
        _messagesRef.child(message['key']).update({
          'status': 'read',
          'readAt': ServerValue.timestamp,
        });
      }
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final messageData = {
      'text': text.trim(),
      'senderId': _currentUserId,
      'recipientId': widget.recipientId,
      'timestamp': ServerValue.timestamp,
      'status': 'sent',
      'type': 'text',
    };

    try {
      // Push new message
      final newMessageRef = _messagesRef.push();
      await newMessageRef.set(messageData);

      // Update conversation metadata
      await _conversationRef.update({
        'lastMessage': text.trim(),
        'lastMessageTime': ServerValue.timestamp,
        'lastMessageSender': _currentUserId,
        'lastMessageStatus': 'sent',
        'updatedAt': ServerValue.timestamp,
      });

      _controller.clear();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMessageStatus(Map<String, dynamic> message) {
    if (message['senderId'] != _currentUserId) return '';
    
    final status = message['status'] ?? 'sent';
    if (status == 'read') return 'read';
    if (status == 'delivered') return 'delivered';
    return 'sent';
  }

  Widget _buildTick(String status) {
    switch (status) {
      case 'sent':
        return Icon(Icons.check, size: 14, color: Colors.grey.shade600);
      case 'delivered':
        return Icon(Icons.done_all, size: 14, color: Colors.grey.shade600);
      case 'read':
        return Icon(Icons.done_all, size: 14, color: Colors.blue.shade700);
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['senderId'] == _currentUserId;
    final status = _getMessageStatus(message);
    final timestamp = message['timestamp'] is int 
        ? message['timestamp'] as int 
        : (message['timestamp'] as num).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                Text(
                  message['text'] ?? '',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    if (isMe && status.isNotEmpty) ...[
                      SizedBox(width: 4),
                      _buildTick(status),
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
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.recipientAvatar),
              radius: 20,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet\nStart a conversation!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
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
          Container(
            color: Colors.grey.shade50,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.card_giftcard, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GiftPage(
                          recipientName: widget.recipientName,
                          recipientAvatar: widget.recipientAvatar,
                          recipientId: widget.recipientId,
                        ),
                      ),
                    );
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
                            cursorColor: Colors.black,
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Colors.black54),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.black,
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
}