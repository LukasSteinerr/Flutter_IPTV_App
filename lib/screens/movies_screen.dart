import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/services/playlist_data_provider.dart';
import 'package:my_project_name/widgets/content_carousel.dart';
import 'package:my_project_name/widgets/featured_content.dart';
import 'package:my_project_name/widgets/shimmer_loading.dart';

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<PlaylistDataProvider>(context);
    final channels = dataProvider.getChannelsByType('movie');

    if (dataProvider.isLoading) {
      return const ShimmerGrid(
        itemCount: 12,
        crossAxisCount: 3,
        itemWidth: 120,
        itemHeight: 180,
        spacing: 10,
      );
    }

    if (dataProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(dataProvider.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _refreshMovies(context, true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No movies found. Add playlists to see content.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              child: const Text('Add Playlist'),
            ),
            if (dataProvider.playlists.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _refreshMovies(context, true),
                child: const Text('Refresh Movies'),
              ),
            ],
          ],
        ),
      );
    }

    // Convert channels to Movie objects for the UI components
    final movies = channels.map((channel) {
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

    // Featured movie - select a movie with a logo if available
    Movie? featuredMovie;
    if (movies.isNotEmpty) {
      // Try to find a movie with a logo for better display
      featuredMovie = movies.firstWhere(
        (m) => m.posterPath != null && m.posterPath!.isNotEmpty,
        orElse: () => movies.first,
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refreshMovies(context, false),
        child: CustomScrollView(
          slivers: [
            // App bar with refresh option
            SliverAppBar(
              floating: true,
              title: const Text('Movies'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _refreshMovies(context, true),
                  tooltip: 'Refresh movie content',
                ),
              ],
            ),
            
            // Featured content at the top
            if (featuredMovie != null)
              SliverToBoxAdapter(
                child: FeaturedContent(
                  featuredContent: featuredMovie,
                  onPlayPress: () {
                    Navigator.pushNamed(
                      context,
                      '/detail',
                      arguments: featuredMovie,
                    );
                  },
                  onInfoPress: () {
                    Navigator.pushNamed(
                      context,
                      '/detail',
                      arguments: featuredMovie,
                    );
                  },
                ),
              ),
              
            // Movie categories
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = moviesByCategory.entries.elementAt(index);
                  return ContentCarousel(
                    title: entry.key,
                    contentList: entry.value,
                    onTap: (movie) {
                      Navigator.pushNamed(context, '/detail', arguments: movie);
                    },
                  );
                },
                childCount: moviesByCategory.length,
              ),
            ),
            
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }
  
  // Smart refresh function that uses our optimized services
  Future<void> _refreshMovies(BuildContext context, bool showSnackbar) async {
    final dataProvider = Provider.of<PlaylistDataProvider>(context, listen: false);
    
    // Show loading indicator for longer refreshes
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            const Text('Refreshing movies...'),
          ],
        ),
        duration: const Duration(seconds: 1),
        behavior: showSnackbar ? SnackBarBehavior.fixed : SnackBarBehavior.floating,
      ),
    );
    
    try {
      // Use our smart refresh focused on movies content type
      await dataProvider.smartRefresh(contentType: 'movie');
      
      if (showSnackbar) {
        // Show success message if explicitly refreshing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movies refreshed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
