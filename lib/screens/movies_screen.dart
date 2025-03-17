import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_project_name/models/iptv_channel.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/services/playlist_data_provider.dart';
import 'package:my_project_name/widgets/content_carousel.dart';
import 'package:my_project_name/widgets/featured_content.dart';

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<PlaylistDataProvider>(context);
    final channels = dataProvider.getChannelsByType('movie');

    if (dataProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dataProvider.errorMessage != null) {
      return Center(child: Text(dataProvider.errorMessage!));
    }

    if (channels.isEmpty) {
      return const Center(
        child: Text('No movies found. Add playlists to see content.'),
      );
    }

    // Convert channels to Movie objects for the UI components
    final movies =
        channels.map((channel) {
          return Movie(
            id: channel.id ?? 0,
            title: channel.name,
            mediaType: 'movie',
            posterPath: channel.logo,
            backdropPath: channel.logo,
            url: channel.url,
          );
        }).toList();

    // Group movies by category
    final Map<String, List<Movie>> moviesByCategory = {};
    for (final channel in channels) {
      final category = channel.group;
      if (!moviesByCategory.containsKey(category)) {
        moviesByCategory[category] = [];
      }
      moviesByCategory[category]!.add(
        Movie(
          id: channel.id ?? 0,
          title: channel.name,
          mediaType: 'movie',
          posterPath: channel.logo,
          backdropPath: channel.logo,
          url: channel.url,
        ),
      );
    }

    // Featured movie (first movie or random)
    final featuredMovie = movies.isNotEmpty ? movies.first : null;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Simple refresh - just reload the data
          await dataProvider.initializeData();
        },
        child: ListView(
          children: [
            if (featuredMovie != null)
              FeaturedContent(
                featuredContent: featuredMovie,
                onPlayPress: () {
                  // Navigate to player or detail screen
                  Navigator.pushNamed(
                    context,
                    '/detail',
                    arguments: featuredMovie,
                  );
                },
                onInfoPress: () {
                  // Show more info
                  Navigator.pushNamed(
                    context,
                    '/detail',
                    arguments: featuredMovie,
                  );
                },
              ),
            // Display each category
            ...moviesByCategory.entries.map((entry) {
              return ContentCarousel(
                title: entry.key,
                contentList: entry.value,
                onTap: (movie) {
                  // Navigate to detail screen
                  Navigator.pushNamed(context, '/detail', arguments: movie);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
