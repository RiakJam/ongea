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
  final PageController _fullScreenPageController = PageController();
  List<String> _images = [];
  final Map<int, bool> _imageLoadErrors = {};

  @override
  void initState() {
    super.initState();
    _extractImageUrls();
  }

  void _extractImageUrls() {
    _images = [];
    _imageLoadErrors.clear();
    
    if (widget.post['mediaType'] == 'image' && widget.post['imageUrls'] != null) {
      dynamic imageUrlsData = widget.post['imageUrls'];

      if (imageUrlsData is Map) {
        _images = Map<String, dynamic>.from(imageUrlsData)
            .values
            .whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList();
      } else if (imageUrlsData is List) {
        _images = List<String>.from(imageUrlsData)
            .where((url) => url.isNotEmpty)
            .toList();
      } else if (imageUrlsData is String && imageUrlsData.isNotEmpty) {
        _images = [imageUrlsData];
      }

      for (int i = 0; i < _images.length; i++) {
        _imageLoadErrors[i] = false;
      }
    }
  }

  void _retryImageLoad(int index) {
    setState(() {
      _imageLoadErrors[index] = false;
    });
  }

  Widget _buildErrorWidget(int index, {bool isFullScreen = false}) {
    return GestureDetector(
      onTap: isFullScreen ? null : () => _retryImageLoad(index),
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
            if (!isFullScreen) ...[
              const SizedBox(height: 8),
              const Text(
                'Tap to retry',
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ],
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

  void _showFullScreenImage(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenGallery(
          images: _images,
          initialIndex: initialIndex,
          imageLoadErrors: _imageLoadErrors,
          onRetry: _retryImageLoad,
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
                        return GestureDetector(
                          onTap: () => _showFullScreenImage(index),
                          child: _buildErrorWidget(index),
                        );
                      }

                      return GestureDetector(
                        onTap: () => _showFullScreenImage(index),
                        child: Hero(
                          tag: 'image_$index',
                          child: Image.network(
                            _images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildLoadingWidget();
                            },
                            errorBuilder: (context, error, stackTrace) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _imageLoadErrors[index] = true;
                                  });
                                }
                              });
                              return GestureDetector(
                                onTap: () => _showFullScreenImage(index),
                                child: _buildErrorWidget(index),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_images.length > 1) ...[
                  // Left navigation arrow
                  if (_currentImageIndex > 0)
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios,
                                size: 16, color: Colors.white),
                            padding: EdgeInsets.zero,
                            onPressed: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Right navigation arrow
                  if (_currentImageIndex < _images.length - 1)
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.white),
                            padding: EdgeInsets.zero,
                            onPressed: () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
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
    _fullScreenPageController.dispose();
    super.dispose();
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final Map<int, bool> imageLoadErrors;
  final Function(int) onRetry;

  const _FullScreenGallery({
    required this.images,
    required this.initialIndex,
    required this.imageLoadErrors,
    required this.onRetry,
    Key? key,
  }) : super(key: key);

  @override
  __FullScreenGalleryState createState() => __FullScreenGalleryState();
}

class __FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  Widget _buildErrorWidget(int index) {
    return GestureDetector(
      onTap: _toggleControls,
      onDoubleTap: () => widget.onRetry(index),
      child: Container(
        color: Colors.black,
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
              'Double tap to retry',
              style: TextStyle(color: Colors.blue, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'URL: ${widget.images[index].length > 50 ? widget.images[index].substring(0, 50) + '...' : widget.images[index]}',
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
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: _toggleControls,
            onDoubleTap: () {},
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (_, index) {
                if (widget.imageLoadErrors[index] == true) {
                  return _buildErrorWidget(index);
                }

                return Hero(
                  tag: 'image_$index',
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildLoadingWidget();
                      },
                      errorBuilder: (context, error, stackTrace) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            widget.imageLoadErrors[index] = true;
                          }
                        });
                        return _buildErrorWidget(index);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          
          // App bar with close button and image counter
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.black54,
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  '${_currentIndex + 1}/${widget.images.length}',
                  style: const TextStyle(color: Colors.white),
                ),
                centerTitle: true,
              ),
            ),
          
          // Navigation arrows for full screen
          if (_showControls && widget.images.length > 1)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _currentIndex > 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _currentIndex > 0
                          ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          
          if (_showControls && widget.images.length > 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _currentIndex < widget.images.length - 1 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      onPressed: _currentIndex < widget.images.length - 1
                          ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          
          // Page indicator for full screen
          if (_showControls && widget.images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}