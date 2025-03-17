import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_project_name/models/iptv_channel.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/services/playlist_data_provider.dart';
import 'package:my_project_name/widgets/content_carousel.dart';
import 'package:my_project_name/widgets/featured_content.dart';

class ShowsScreen extends StatelessWidget {
  const ShowsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<PlaylistDataProvider>(context);
    final channels = dataProvider.getChannelsByType('tv_show');
    
    if (dataProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (dataProvider.errorMessage != null) {
      return Center(child: Text(dataProvider.errorMessage!));
    }
    
    if (channels.isEmpty) {
      return const Center(
        child: Text('No TV shows found. Add playlists to see content.'),
      );
    }
    
    // Convert channels to Movie objects for the UI components
    final shows = channels.map((channel) {
      return Movie(
        id: channel.id ?? 0,
        title: channel.name,
        mediaType: 'tv',
        posterPath: channel.logo,
        backdropPath: channel.logo,
        url: channel.url,
      );
    }).toList();
    
    // Group shows by category
    final Map<String, List<Movie>> showsByCategory = {};
    for (final channel in channels) {
      final category = channel.group;
      if (!showsByCategory.containsKey(category)) {
        showsByCategory[category] = [];
      }
      showsByCategory[category]!.add(
        Movie(
          id: channel.id ?? 0,
          title: channel.name,
          mediaType: 'tv',
          posterPath: channel.logo,
          backdropPath: channel.logo,
          url: channel.url,
        ),
      );
    }
    
    // Featured show (first show or random)
    final featuredShow = shows.isNotEmpty ? shows.first : null;
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Simple refresh - just reload the data
          await dataProvider.initializeData();
        },
        child: ListView(
          children: [
            if (featuredShow != null)
              FeaturedContent(
                featuredContent: featuredShow,
                onPlayPress: () {
                  // Navigate to player or detail screen
                  Navigator.pushNamed(
                    context,
                    '/detail',
                    arguments: featuredShow,
                  );
                },
                onInfoPress: () {
                  // Show more info
                  Navigator.pushNamed(
                    context,
                    '/detail',
                    arguments: featuredShow,
                  );
                },
              ),
            // Display each category
            ...showsByCategory.entries.map((entry) {
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
