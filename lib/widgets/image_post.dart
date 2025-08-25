import 'package:flutter/material.dart';

class ImagePost extends StatefulWidget {
  final Map<String, dynamic> post;

  const ImagePost({required this.post, Key? key}) : super(key: key);

  @override
  _ImagePostState createState() => _ImagePostState();
}

class _ImagePostState extends State<ImagePost> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  List<String> _images = [];
  final Map<int, bool> _imageLoadErrors = {};

  @override
  void initState() {
    super.initState();
    _extractImageUrls();
  }
  void _extractImageUrls() {
    if (widget.post['mediaType'] == 'image' && widget.post['imageUrls'] != null) {
      dynamic imageUrlsData = widget.post['imageUrls'];

      print("🔎 imageUrlsData type: ${imageUrlsData.runtimeType}");
      print("🔎 imageUrlsData value: $imageUrlsData");

      if (imageUrlsData is Map) {
        // Firebase Map structure: {"0": "url1", "1": "url2"}
        _images = Map<String, dynamic>.from(imageUrlsData)
            .values
            .whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList();
      } else if (imageUrlsData is List) {
        // List structure: ["url1", "url2"]
        _images = List<String>.from(imageUrlsData);
      } else if (imageUrlsData is String) {
        // Single image: "url1"
        _images = [imageUrlsData];
      } else {
        _images = [];
      }

      // Initialize error states
      for (int i = 0; i < _images.length; i++) {
        _imageLoadErrors[i] = false;
      }

      print("🎯 Final images list: $_images");
    } else {
      print("⚠️ No valid image data found");
      _images = [];
    }
  }

  void _retryImageLoad(int index) {
    setState(() {
      _imageLoadErrors[index] = false;
    });
  }

  Widget _buildErrorWidget(int index) {
    return GestureDetector(
      onTap: () => _retryImageLoad(index),
      child: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Failed to load image',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap to retry',
              style: TextStyle(color: Colors.blue, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'URL: ${_images[index].length > 50 ? _images[index].substring(0, 50) + '...' : _images[index]}',
              style: const TextStyle(color: Colors.grey, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return Container(
        color: Colors.grey[200],
        height: 200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No images to display',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                SizedBox(
                  height: constraints.maxWidth * 0.75,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _images.length,
                    onPageChanged: (index) =>
                        setState(() => _currentImageIndex = index),
                    itemBuilder: (_, index) {
                      if (_imageLoadErrors[index] == true) {
                        return _buildErrorWidget(index);
                      }

                      return Image.network(
                        _images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildLoadingWidget();
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print("🚨 Image load failed: ${_images[index]} → $error");
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _imageLoadErrors[index] = true;
                              });
                            }
                          });
                          return _buildErrorWidget(index);
                        },
                      );
                    },
                  ),
                ),
                if (_images.length > 1) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            size: 20, color: Colors.white),
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios,
                            size: 20, color: Colors.white),
                        onPressed: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        if (_images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _images.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? Colors.blue
                      : Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
