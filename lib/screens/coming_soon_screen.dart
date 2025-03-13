import 'package:flutter/material.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/screens/detail_screen.dart';
import 'package:my_project_name/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ComingSoonScreen extends StatefulWidget {
  const ComingSoonScreen({super..key}

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen> {
  List<Movie> _allChannels = [];
  Map<String, List<Movie>> _categorizedChannels = {};
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final trending = await Api.getTrending();
      final allChannels = Movie.fromJsonList(trending);

      // Group channels by their genres (categories)
      final categorizedChannels = <String, List<Movie>>{};

      for (final channel in allChannels) {
        if (channel.genres != null && channel.genres!.isNotEmpty) {
          for (final genre in channel.genres!) {
            if (!categorizedChannels.containsKey(genre)) {
              categorizedChannels[genre] = [];
            }
            categorizedChannels[genre]!.add(channel);
          }
        } else {
          // For channels without genres, use media type as category
          final category = channel.mediaType.toUpperCase();
          if (!categorizedChannels.containsKey(category)) {
            categorizedChannels[category] = [];
          }
          categorizedChannels[category]!.add(channel);
        }
      }

      // Sort categories by number of channels (descending)
      final categories =
          categorizedChannels.keys.toList()..sort(
            (a, b) => categorizedChannels[b]!.length.compareTo(
              categorizedChannels[a]!.length,
            ),
          );

      setState(() {
        _allChannels = allChannels;
        _categorizedChannels = categorizedChannels;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.netflixBlack,
        title: const Text('Categories'),
        actions: [IconButton(icon: const Icon(Icons.cast), onPressed: () {})],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.netflixRed),
              )
              : _buildCategoriesList(),
    );
  }

  Widget _buildCategoriesList() {
    if (_categories.isEmpty) {
      return const Center(
        child: Text(
          'No categories available',
          style: TextStyle(color: AppColors.netflixLightGrey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final channels = _categorizedChannels[category] ?? [];
        return _CategoryItem(
          category: category,
          channelCount: channels.length,
          previewChannels: channels.take(3).toList(),
          onTap: () => _showCategoryChannels(category, channels),
        );
      },
    );
  }

  void _showCategoryChannels(String category, List<Movie> channels) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.netflixBlack,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (_, scrollController) {
              return Column(
                children: [
                  AppBar(
                    title: Text(category),
                    backgroundColor: AppColors.netflixBlack,
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: channels.length,
                      itemBuilder: (context, index) {
                        final movie = channels[index];
                        return GestureDetector(
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(movie: movie),
                                ),
                              ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: movie.fullPosterPath,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => Container(
                                          color: AppColors.netflixDarkGrey,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.netflixRed,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                    errorWidget:
                                        (context, url, error) => Container(
                                          color: AppColors.netflixDarkGrey,
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: AppColors.netflixRed,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                movie.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String category;
  final int channelCount;
  final List<Movie> previewChannels;
  final VoidCallback onTap;

  const _CategoryItem({
    super..key,
    required this.category,
    required this.channelCount,
    required this.previewChannels,
    required this.onTap,
  })

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '$channelCount channel${channelCount != 1 ? 's' : ''}',
                    style: const TextStyle(color: AppColors.netflixLightGrey),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.netflixLightGrey,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Preview of channels
            SizedBox(
              height: 150,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                scrollDirection: Axis.horizontal,
                itemCount: previewChannels.length,
                itemBuilder: (context, index) {
                  final channel = previewChannels[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: SizedBox(
                        width: 100,
                        child: CachedNetworkImage(
                          imageUrl: channel.fullPosterPath,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: AppColors.netflixDarkGrey,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.netflixRed,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: AppColors.netflixDarkGrey,
                                child: Center(
                                  child: Text(
                                    channel.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.netflixRed,
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            const Divider(color: AppColors.netflixDarkGrey, thickness: 1.5),
          ],
        ),
      ),
    );
  }
}
