import 'package:flutter/material.dart';

// Edit Post Page
class EditPostPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final String mediaType;
  final List<String> imageUrls;
  final String videoUrl;
  final String caption;
  final Function(String, List<String>) onSave;
  final Function() onDelete;

  const EditPostPage({
    Key? key,
    required this.post,
    required this.mediaType,
    required this.imageUrls,
    required this.videoUrl,
    required this.caption,
    required this.onSave,
    required this.onDelete,
  }) : super(key: key);

  @override
  _EditPostPageState createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late TextEditingController _captionController;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<String> _currentImageUrls = [];

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.caption);
    _currentImageUrls = List.from(widget.imageUrls);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _removeImage(int index) {
    setState(() {
      _currentImageUrls.removeAt(index);
      if (_currentPage >= _currentImageUrls.length && _currentImageUrls.isNotEmpty) {
        _currentPage = _currentImageUrls.length - 1;
      } else if (_currentImageUrls.isEmpty) {
        _currentPage = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Post'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Post'),
                  content: Text('Are you sure you want to delete this post? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onDelete();
                        Navigator.pop(context);
                      },
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          TextButton(
            onPressed: () {
              widget.onSave(_captionController.text, _currentImageUrls);
              Navigator.pop(context);
            },
            child: Text('Save', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.mediaType == 'image' && _currentImageUrls.isNotEmpty)
              _buildImageCarousel(),
            if (widget.mediaType == 'video' && widget.videoUrl.isNotEmpty)
              _buildVideoPreview(),
            if (widget.mediaType == 'text')
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.caption,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            SizedBox(height: 16),
            TextField(
              controller: _captionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Caption',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            // Additional edit options could be added here
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Column(
      children: [
        Container(
          constraints: BoxConstraints(maxHeight: 400),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _currentImageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Image.network(
                    _currentImageUrls[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, color: Colors.grey[600]),
                    ),
                  ),
                  if (_currentImageUrls.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (_currentImageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_currentImageUrls.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? Colors.blue : Colors.grey,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      constraints: BoxConstraints(maxHeight: 400),
      color: Colors.black,
      child: Center(
        child: Icon(Icons.play_circle_filled, color: Colors.white, size: 50),
      ),
    );
  }
}

// Saved Page
class SavedPage extends StatelessWidget {
  final List<String> dummySaved = List.generate(6, (index) => 'https://picsum.photos/150?random=$index');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Saved Contents'), backgroundColor: Colors.white, iconTheme: IconThemeData(color: Colors.black)),
      body: GridView.builder(
        itemCount: dummySaved.length,
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6),
        itemBuilder: (_, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: Image.network(
              dummySaved[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Icon(Icons.broken_image, color: Colors.grey[600]),
            ),
          );
        },
      ),
    );
  }
}

// Edit Profile Page
class EditProfilePage extends StatefulWidget {
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    // Initialize with dummy data (you would load actual user data here)
    _nameController.text = 'John Doe';
    _bioController.text = 'Software Developer | Flutter Enthusiast';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() => saving = true);
                    await Future.delayed(Duration(milliseconds: 600));
                    if (mounted) {
                      setState(() => saving = false);
                      Navigator.pop(context);
                    }
                  },
            child: saving 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
                  )
                : Text('Save', style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, size: 50, color: Colors.grey[600]),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Handle profile picture change
              },
              child: Text('Change Profile Picture'),
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Handle change password
              },
              child: Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}