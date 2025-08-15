import 'package:flutter/material.dart';

class TextPost extends StatefulWidget {
  final String text;

  const TextPost({required this.text});

  @override
  _TextPostState createState() => _TextPostState();
}

class _TextPostState extends State<TextPost> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final maxLines = _expanded ? null : 3;
    final overflow = _expanded ? TextOverflow.visible : TextOverflow.ellipsis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: maxLines,
          overflow: overflow,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
        if (widget.text.length > 100)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? "Read less" : "Read more",
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}