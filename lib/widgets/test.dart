import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostPage extends StatelessWidget {
  final String postId; // e.g. "-OYSE3w0FPTHSkxjZ-zP"

  const PostPage({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Post")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("posts")
            .doc(postId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Post not found"));
          }

          final post = snapshot.data!.data() as Map<String, dynamic>;

          List<String> imageUrls = [];
          if (post["imageUrls"] is Map) {
            // Extract images from Firestore map
            imageUrls = (post["imageUrls"] as Map)
                .values
                .map((e) => e.toString())
                .toList();
          } else if (post["imageUrls"] is List) {
            imageUrls = List<String>.from(post["imageUrls"]);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🖼 Image carousel
                if (imageUrls.isNotEmpty)
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(Icons.broken_image,
                                    size: 50, color: Colors.red),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                                child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                            ));
                          },
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: Text("No images available"),
                    ),
                  ),

                SizedBox(height: 16),

                /// 📝 Post Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post["caption"] ?? "",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),

                      SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(Icons.person, size: 20, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(post["userName"] ?? "Unknown user",
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),

                      SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.red, size: 18),
                          SizedBox(width: 4),
                          Text("${post["likes"] ?? 0} Likes"),

                          SizedBox(width: 16),
                          Icon(Icons.comment, size: 18),
                          SizedBox(width: 4),
                          Text("${post["comments"] ?? 0} Comments"),

                          SizedBox(width: 16),
                          Icon(Icons.bookmark, size: 18),
                          SizedBox(width: 4),
                          Text("${post["saves"] ?? 0} Saves"),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
