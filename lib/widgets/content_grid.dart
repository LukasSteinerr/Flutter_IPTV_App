import 'package:flutter/material.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ContentGrid extends StatelessWidget {
  final List<Movie> contentList;
  final Function(Movie) onTap;
  final int crossAxisCount;
  final double childAspectRatio;

  const ContentGrid({
    super.key,
    required this.contentList,
    required this.onTap,
    this.crossAxisCount = 3,
    this.childAspectRatio = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final movie = contentList[index];
        return _buildMovieCard(context, movie);
      }, childCount: contentList.length),
    );
  }

  Widget _buildMovieCard(BuildContext context, Movie movie) {
    return GestureDetector(
      onTap: () => onTap(movie),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Movie poster
                    CachedNetworkImage(
                      imageUrl: movie.fullPosterPath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder:
                          (context, url) => Container(
                            color: AppColors.cardBackground,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: AppColors.cardBackground,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.primaryColor,
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Text(
                                      movie.title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ),

                    // Media type badge (movie, tv, live)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getBadgeColor(movie.mediaType!),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          _getBadgeText(movie.mediaType!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          ),
          if (movie.voteAverage != null && movie.voteAverage! > 0)
            Text(
              '${(movie.voteAverage! / 2).toStringAsFixed(1)} ★',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.amber),
            ),
        ],
      ),
    );
  }

  Color _getBadgeColor(String mediaType) {
    switch (mediaType.toLowerCase()) {
      case 'movie':
        return Colors.blue;
      case 'tv':
        return Colors.green;
      case 'live':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  String _getBadgeText(String mediaType) {
    switch (mediaType.toLowerCase()) {
      case 'movie':
        return 'MOVIE';
      case 'tv':
        return 'TV';
      case 'live':
        return 'LIVE';
      default:
        return mediaType.toUpperCase();
    }
  }
}
