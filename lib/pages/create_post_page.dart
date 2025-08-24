import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref('posts');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _selectedVideo;
  VideoPlayerController? _videoController;
  final List<File> _selectedImages = [];

  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _captionController.addListener(() => setState(() {}));
  }

  Future<void> _pickImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (images.isEmpty) return;

      if (_selectedImages.length + images.length > 10) {
        setState(() => _errorMessage = "You can select up to 10 images");
        return;
      }

      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
        _selectedVideo = null;
        _disposeVideo();
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = "Couldn't load images. Please try again.");
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        final videoFile = File(video.path);
        await _handleSelectedVideo(videoFile);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load video. Please try another file.";
      });
    }
  }

  Future<void> _handleSelectedVideo(File videoFile) async {
    try {
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();

      if (!mounted) return;

      _disposeVideo();

      setState(() {
        _selectedVideo = videoFile;
        _selectedImages.clear();
        _videoController = controller;
        _isLoading = false;
      });

      _videoController?.play();
    } catch (e) {
      setState(() {
        _errorMessage = "Unsupported video format. Please try another file.";
        _isLoading = false;
      });
    }
  }

  void _disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
  }

  void _removeVideo() {
    _disposeVideo();
    setState(() => _selectedVideo = null);
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<String?> _uploadMedia(File file, String type) async {
    try {
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      Reference storageRef = _storage.ref().child('posts/$type/$fileName');
      UploadTask uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: type == 'videos' ? 'video/mp4' : 'image/jpeg',
        ),
      );
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      setState(
        () => _errorMessage = "Failed to upload $type. Please try again.",
      );
      return null;
    }
  }

  Future<void> _submitPost() async {
    if (_captionController.text.isEmpty &&
        _selectedVideo == null &&
        _selectedImages.isEmpty) {
      setState(
        () => _errorMessage = "Please add text, image, or video to post.",
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Prepare post data
      Map<String, dynamic> postData = {
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName ?? 'Anonymous',
        'userPhoto': user.photoURL,
        'caption': _captionController.text.trim(),
        'timestamp': ServerValue.timestamp,
        'likes': 0,
        'comments': 0,
        'saves': 0,
        'shares': 0,
        'status': 'active',
      };

      // Handle video upload
      if (_selectedVideo != null) {
        String? videoUrl = await _uploadMedia(_selectedVideo!, 'videos');
        if (videoUrl != null) {
          postData['videoUrl'] = videoUrl;
          postData['mediaType'] = 'video';
          postData['duration'] =
              _videoController?.value.duration.inSeconds ?? 0;
        } else {
          throw Exception("Failed to upload video");
        }
      }
      // Handle image uploads
      else if (_selectedImages.isNotEmpty) {
        List<String> imageUrls = [];
        for (var image in _selectedImages) {
          String? imageUrl = await _uploadMedia(image, 'images');
          if (imageUrl != null) {
            imageUrls.add(imageUrl);
          } else {
            throw Exception("Failed to upload images");
          }
        }
        postData['imageUrls'] = imageUrls;
        postData['mediaType'] = 'image'; // ✅ This must match your rules
      } else {
        // Text-only post
        postData['mediaType'] = 'text';
      }

      // Push to database - using push() to generate a unique key
      DatabaseReference newPostRef = _database.push();
      await newPostRef.set(postData);

      setState(() {
        _isUploading = false;
        _successMessage = "Post created successfully!";
      });

      // Clear form after successful post
      _captionController.clear();
      _selectedImages.clear();
      _selectedVideo = null;
      _disposeVideo();

      // Removed the automatic navigation code
      // The user will stay on the page and can create another post if desired
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage =
            "Failed to post: ${e.toString().replaceAll('Exception: ', '')}";
      });
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    _captionController.dispose();
    super.dispose();
  }

  Widget _buildMediaPreview() {
    if (_selectedVideo != null) {
      return Column(
        children: [
          AspectRatio(
            aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
            child: Stack(
              children: [
                VideoPlayer(_videoController!),
                Positioned.fill(
                  child: Center(
                    child: IconButton(
                      icon: Icon(
                        _videoController!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white.withOpacity(
                          0.8,
                        ), // Still works but deprecated
                        size: 50,
                      ),
                      onPressed: () {
                        setState(() {
                          _videoController!.value.isPlaying
                              ? _videoController!.pause()
                              : _videoController!.play();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _removeVideo,
          ),
        ],
      );
    } else if (_selectedImages.isNotEmpty) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.file(_selectedImages[index], fit: BoxFit.cover),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Post',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton(
              onPressed: _isUploading ? null : _submitPost,
              style: TextButton.styleFrom(
                backgroundColor:
                    _captionController.text.isNotEmpty ||
                        _selectedVideo != null ||
                        _selectedImages.isNotEmpty
                    ? Colors.blue
                    : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: NetworkImage(
                        _auth.currentUser?.photoURL ??
                            "https://i.pravatar.cc/150?img=5",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _captionController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          hintText: "What's on your mind?",
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        autofocus: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_selectedVideo != null || _selectedImages.isNotEmpty)
                  Column(
                    children: [
                      _buildMediaPreview(),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Add to your post section - simplified without privacy selector
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Add to your post",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.photo_library,
                            label: "Photo",
                            color: Colors.green,
                            onTap: _pickImage,
                          ),
                          _buildActionButton(
                            icon: Icons.videocam,
                            label: "Video",
                            color: Colors.red,
                            onTap: _pickVideo,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_errorMessage != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_successMessage != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _successMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

          if (_isLoading || _isUploading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.black, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
