// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:video_player/video_player.dart';

// class CreatePostPage extends StatefulWidget {
//   const CreatePostPage({Key? key}) : super(key: key);

//   @override
//   State<CreatePostPage> createState() => _CreatePostPageState();
// }

// class _CreatePostPageState extends State<CreatePostPage> {
//   final ImagePicker _picker = ImagePicker();
//   final TextEditingController _captionController = TextEditingController();

//   File? _selectedVideo;
//   VideoPlayerController? _videoController;
//   final List<File> _selectedImages = [];

//   bool _isLoading = false;
//   String? _errorMessage;

//   Future<void> _pickImage() async {
//     try {
//       final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//       if (image != null) {
//         setState(() {
//           _selectedImages.add(File(image.path));
//           _selectedVideo = null;
//           _disposeVideo();
//           _errorMessage = null;
//         });
//       }
//     } catch (e) {
//       setState(() => _errorMessage = "Couldn't load image. Please try again.");
//     }
//   }

//   Future<void> _pickVideo() async {
//     try {
//       final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
//       if (video != null) {
//         setState(() {
//           _isLoading = true;
//           _errorMessage = null;
//         });

//         final videoFile = File(video.path);
//         final controller = VideoPlayerController.file(videoFile);
//         await controller.initialize();

//         if (controller.value.duration.inSeconds > 600) {
//           setState(() {
//             _isLoading = false;
//             _errorMessage = "⏳ Video is too long. Please select a video under 10 minutes.";
//           });
//           controller.dispose();
//           return;
//         }

//         await _handleSelectedVideo(videoFile);
//         setState(() => _isLoading = false);
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Couldn't load video. Please try another file.";
//       });
//     }
//   }

//   Future<void> _handleSelectedVideo(File videoFile) async {
//     try {
//       final controller = VideoPlayerController.file(videoFile);
//       await controller.initialize();

//       if (!mounted) return;

//       _disposeVideo();

//       setState(() {
//         _selectedVideo = videoFile;
//         _selectedImages.clear();
//         _videoController = controller;
//       });

//       _videoController?.play();
//     } catch (e) {
//       setState(() {
//         _errorMessage = "Unsupported video format. Please try another file.";
//         _isLoading = false;
//       });
//     }
//   }

//   void _disposeVideo() {
//     _videoController?.dispose();
//     _videoController = null;
//   }

//   void _removeVideo() {
//     _disposeVideo();
//     setState(() {
//       _selectedVideo = null;
//       _errorMessage = null;
//     });
//   }

//   void _removeImage(int index) {
//     setState(() => _selectedImages.removeAt(index));
//   }

//   Future<void> _submitPost() async {
//     if (_captionController.text.isEmpty &&
//         _selectedVideo == null &&
//         _selectedImages.isEmpty) {
//       setState(() => _errorMessage = "⚠️ Please add text, image, or video to post.");
//       return;
//     }

//     Navigator.pop(context, {
//       'text': _captionController.text,
//       'video': _selectedVideo,
//       'images': _selectedImages,
//     });
//   }

//   @override
//   void dispose() {
//     _disposeVideo();
//     _captionController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white, // Full solid background
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('Create Post', style: TextStyle(color: Colors.black)),
//         actions: [
//           TextButton(
//             onPressed: _submitPost,
//             child: const Text(
//               'Post',
//               style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     children: [
//                       // User avatar + text field
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const CircleAvatar(
//                             radius: 24,
//                             backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=5"),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: TextField(
//                               controller: _captionController,
//                               decoration: const InputDecoration(
//                                 hintText: "✍️ Write something to share with others...",
//                                 border: InputBorder.none,
//                               ),
//                               maxLines: null,
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 10),

//                       // Instructions
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[200],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: const Text(
//                           "💡 Tip: You can add multiple images or one video (max 10 minutes). Text-only posts are allowed.",
//                           style: TextStyle(fontSize: 14, color: Colors.black87),
//                         ),
//                       ),

//                       if (_errorMessage != null) ...[
//                         const SizedBox(height: 10),
//                         Text(
//                           _errorMessage!,
//                           style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
//                         ),
//                       ],

//                       const SizedBox(height: 10),

//                       // Video Preview
//                       if (_selectedVideo != null)
//                         Column(
//                           children: [
//                             AspectRatio(
//                               aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
//                               child: _videoController != null
//                                   ? Stack(
//                                       children: [
//                                         VideoPlayer(_videoController!),
//                                         Positioned(
//                                           bottom: 10,
//                                           left: 10,
//                                           child: IconButton(
//                                             icon: Icon(
//                                               _videoController!.value.isPlaying
//                                                   ? Icons.pause_circle
//                                                   : Icons.play_circle,
//                                               color: Colors.white,
//                                               size: 40,
//                                             ),
//                                             onPressed: () {
//                                               setState(() {
//                                                 _videoController!.value.isPlaying
//                                                     ? _videoController!.pause()
//                                                     : _videoController!.play();
//                                               });
//                                             },
//                                           ),
//                                         ),
//                                       ],
//                                     )
//                                   : const Center(child: CircularProgressIndicator()),
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.delete, color: Colors.red),
//                               onPressed: _removeVideo,
//                             ),
//                           ],
//                         ),

//                       // Images Preview
//                       if (_selectedImages.isNotEmpty)
//                         GridView.builder(
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 3,
//                             crossAxisSpacing: 4,
//                             mainAxisSpacing: 4,
//                           ),
//                           itemCount: _selectedImages.length,
//                           itemBuilder: (context, index) {
//                             return Stack(
//                               fit: StackFit.expand,
//                               children: [
//                                 Image.file(_selectedImages[index], fit: BoxFit.cover),
//                                 Positioned(
//                                   top: 4,
//                                   right: 4,
//                                   child: Container(
//                                     color: Colors.black54,
//                                     child: IconButton(
//                                       icon: const Icon(Icons.close, color: Colors.white, size: 20),
//                                       onPressed: () => _removeImage(index),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             );
//                           },
//                         ),
//                     ],
//                   ),
//                 ),
//               ),

//               // Buttons
//               Container(
//                 padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   border: Border(top: BorderSide(color: Colors.grey.shade300)),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.black,
//                         foregroundColor: Colors.white,
//                         minimumSize: const Size(140, 45),
//                       ),
//                       icon: const Icon(Icons.photo),
//                       label: const Text('Add Image'),
//                       onPressed: _pickImage,
//                     ),
//                     ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.black,
//                         foregroundColor: Colors.white,
//                         minimumSize: const Size(140, 45),
//                       ),
//                       icon: const Icon(Icons.videocam),
//                       label: const Text('Add Video'),
//                       onPressed: _pickVideo,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           if (_isLoading) const Center(child: CircularProgressIndicator()),
//         ],
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();

  File? _selectedVideo;
  VideoPlayerController? _videoController;
  final List<File> _selectedImages = [];

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
          _selectedVideo = null;
          _disposeVideo();
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = "Couldn't load image. Please try again.");
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        final videoFile = File(video.path);
        final controller = VideoPlayerController.file(videoFile);
        await controller.initialize();

        if (controller.value.duration.inSeconds > 600) {
          setState(() {
            _isLoading = false;
            _errorMessage = "⏳ Video is too long. Please select a video under 10 minutes.";
          });
          controller.dispose();
          return;
        }

        await _handleSelectedVideo(videoFile);
        setState(() => _isLoading = false);
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
    _videoController?.dispose();
    _videoController = null;
  }

  void _removeVideo() {
    _disposeVideo();
    setState(() {
      _selectedVideo = null;
      _errorMessage = null;
    });
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submitPost() async {
    if (_captionController.text.isEmpty &&
        _selectedVideo == null &&
        _selectedImages.isEmpty) {
      setState(() => _errorMessage = "⚠️ Please add text, image, or video to post.");
      return;
    }

    Navigator.pop(context, {
      'text': _captionController.text,
      'video': _selectedVideo,
      'images': _selectedImages,
    });
  }

  @override
  void dispose() {
    _disposeVideo();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow the screen to resize when keyboard appears
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Post', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: _submitPost,
            child: const Text(
              'Post',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        // Allows tapping outside to dismiss keyboard
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            kToolbarHeight -
                            100, // Account for app bar and bottom buttons
                      ),
                      child: Column(
                        children: [
                          // User avatar + text field
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=5"),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _captionController,
                                  decoration: const InputDecoration(
                                    hintText: "✍️ Write something to share with others...",
                                    border: InputBorder.none,
                                  ),
                                  maxLines: null,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Instructions
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "💡 Tip: You can add multiple images or one video (max 10 minutes). Text-only posts are allowed.",
                              style: TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],

                          const SizedBox(height: 10),

                          // Video Preview
                          if (_selectedVideo != null)
                            Column(
                              children: [
                                AspectRatio(
                                  aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
                                  child: _videoController != null
                                      ? Stack(
                                          children: [
                                            VideoPlayer(_videoController!),
                                            Positioned(
                                              bottom: 10,
                                              left: 10,
                                              child: IconButton(
                                                icon: Icon(
                                                  _videoController!.value.isPlaying
                                                      ? Icons.pause_circle
                                                      : Icons.play_circle,
                                                  color: Colors.white,
                                                  size: 40,
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
                                          ],
                                        )
                                      : const Center(child: CircularProgressIndicator()),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: _removeVideo,
                                ),
                              ],
                            ),

                          // Images Preview
                          if (_selectedImages.isNotEmpty)
                            GridView.builder(
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
                                      child: Container(
                                        color: Colors.black54,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                          onPressed: () => _removeImage(index),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Buttons
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(140, 45),
                        ),
                        icon: const Icon(Icons.photo),
                        label: const Text('Add Image'),
                        onPressed: _pickImage,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(140, 45),
                        ),
                        icon: const Icon(Icons.videocam),
                        label: const Text('Add Video'),
                        onPressed: _pickVideo,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}