import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  final String? highlightComment;

  const PostDetailPage({required this.postId, this.highlightComment});

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? _post;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  void _loadPost() {
    _database.child('posts/${widget.postId}').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _post = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post'),
      ),
      body: _post == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Display post content here
                  // You can reuse your PostCard widget or build a detailed view
                  if (widget.highlightComment != null)
                    // Highlight the specific comment if needed
                    Container(),
                ],
              ),
            ),
    );
  }
}