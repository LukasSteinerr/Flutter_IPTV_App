import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/movie.dart';

class FeaturedContent extends StatelessWidget {
  final Movie featuredContent;
  final Function() onPlayPress;
  final Function() onInfoPress;

  const FeaturedContent({
    super.key,
    required this.featuredContent,
    required this.onPlayPress,
    required this.onInfoPress,
  });

  @override
  Widget build(BuildContext context) {
    // Use Container with decoration instead of Stack with Positioned.fill for the gradient overlay
    return Container(
      height: 500,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(featuredContent.fullBackdropPath),
          fit: BoxFit.cover,
        ),
      ),
      foregroundDecoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(0),
            Colors.black.withAlpha(0),
            Colors.black.withAlpha(204), // 0.8 opacity
            Colors.black.withAlpha(255), // 1.0 opacity
          ],
          stops: const [0.0, 0.2, 0.7, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              featuredContent.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12.0),
            // If available, show rating and year
            if (featuredContent.voteAverage != null ||
                featuredContent.releaseDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    if (featuredContent.voteAverage != null) ...[
                      Icon(Icons.star, color: Colors.amber, size: 16.0),
                      const SizedBox(width: 4.0),
                      Text(
                        featuredContent.voteAverage!.toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                    ],
                    if (featuredContent.releaseDate != null)
                      Text(
                        featuredContent.releaseDate!.substring(0, 4),
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            // Placeholder for genres
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Wrap(
                spacing: 8.0,
                children: [
                  for (String genre
                      in featuredContent.genres?.take(3).toList() ?? [])
                    Chip(
                      label: Text(
                        genre,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppColors.netflixDarkGrey,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ),
            // Button row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Play Button
                Expanded(
                  child: FilledButton(
                    onPressed: onPlayPress,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.netflixRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 24.0),
                        SizedBox(width: 4.0),
                        Text('Play'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                // More Info Button
                Expanded(
                  child: FilledButton(
                    onPressed: onInfoPress,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.netflixDarkGrey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 24.0),
                        SizedBox(width: 4.0),
                        Text('More Info'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
