import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'post_card.dart';

class SearchModal extends StatelessWidget {
  final BuildContext context;
  final TextEditingController searchController;
  final String searchQuery;
  final List<Map<String, dynamic>> filteredPosts;
  final List<Map<String, dynamic>> posts;
  final Map<int, VideoPlayerController?> videoControllers;
  final Map<int, GlobalKey> videoKeys;
  final int? currentlyPlayingIndex;
  final Map<int, bool> userPausedVideos;
  final String? currentUserId;
  final Map<String, bool> likedPosts;
  final Map<String, bool> savedPosts;
  final Map<String, bool> followingUsers;
  final Function(String) onLike;
  final Function(String) onSave;
  final Function(String) onGift;
  final Function(String) onFollow;
  final Map<String, int> giftCounts;
  final Map<String, bool> hasGifted;
  final Map<String, int> commentCounts;
  final Map<String, int> shareCounts;
  final Map<String, int> likeCounts; // Add this parameter
  final VoidCallback onClose;
  final Function(String) onUpdateSearchQuery;

  const SearchModal({
    required this.context,
    required this.searchController,
    required this.searchQuery,
    required this.filteredPosts,
    required this.posts,
    required this.videoControllers,
    required this.videoKeys,
    required this.currentlyPlayingIndex,
    required this.userPausedVideos,
    required this.currentUserId,
    required this.likedPosts,
    required this.savedPosts,
    required this.followingUsers,
    required this.onLike,
    required this.onSave,
    required this.onGift,
    required this.onFollow,
    required this.giftCounts,
    required this.hasGifted,
    required this.commentCounts,
    required this.shareCounts,
    required this.likeCounts, // Add this parameter
    required this.onClose,
    required this.onUpdateSearchQuery,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Search posts...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.black),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: onClose,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black),
              ),
            ),
            onChanged: onUpdateSearchQuery,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: searchQuery.isEmpty
                ? const Center(
                    child: Text(
                      'Search for posts or users',
                      style: TextStyle(color: Colors.black),
                    ),
                  )
                : filteredPosts.isEmpty
                    ? const Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = filteredPosts[index];
                          final originalIndex = posts.indexWhere((p) => p['key'] == post['key']);
                          if (originalIndex == -1) return const SizedBox.shrink();

                          final isFollowing = followingUsers[post['userId']] ?? false;

                          return Column(
                            children: [
                              PostCard(
                                post: post,
                                videoController: videoControllers[originalIndex],
                                videoKey: videoKeys[originalIndex],
                                isPlaying: originalIndex == currentlyPlayingIndex,
                                isUserPaused: userPausedVideos[originalIndex] ?? false,
                                onUserPause: (bool paused) {
                                  userPausedVideos[originalIndex] = paused;
                                  if (paused) {
                                    videoControllers[originalIndex]?.pause();
                                  }
                                },
                                currentUserId: currentUserId,
                                isLiked: likedPosts[post['key']] ?? false,
                                isSaved: savedPosts[post['key']] ?? false,
                                isFollowing: isFollowing,
                                onLike: onLike,
                                onSave: onSave,
                                onGift: onGift,
                                onFollow: onFollow,
                                giftCount: giftCounts[post['key']] ?? 0,
                                hasGifted: hasGifted[post['key']] ?? false,
                                commentCount: commentCounts[post['key']] ?? 0,
                                shareCount: shareCounts[post['key']] ?? 0,
                                likeCount: likeCounts[post['key']] ?? 0, // Add this line
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1, color: Colors.grey),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}