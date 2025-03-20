import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/services/playlist_data_provider.dart';
import 'package:my_project_name/widgets/content_carousel.dart';
import 'package:my_project_name/widgets/featured_content.dart';
import 'package:my_project_name/widgets/shimmer_loading.dart';

class ShowsScreen extends StatelessWidget {
  const ShowsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<PlaylistDataProvider>(context);
    final channels = dataProvider.getChannelsByType('tv_show');

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
              onPressed: () => _refreshTvShows(context, true),
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
            const Text('No TV shows found. Add playlists to see content.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              child: const Text('Add Playlist'),
            ),
            if (dataProvider.playlists.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _refreshTvShows(context, true),
                child: const Text('Refresh TV Shows'),
              ),
            ],
          ],
        ),
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

    // Featured show - select one with a logo if available
    Movie? featuredShow;
    if (shows.isNotEmpty) {
      // Try to find a show with a logo for better display
      featuredShow = shows.firstWhere(
        (s) => s.posterPath != null && s.posterPath!.isNotEmpty,
        orElse: () => shows.first,
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refreshTvShows(context, false),
        child: CustomScrollView(
          slivers: [
            // App bar with refresh option
            SliverAppBar(
              floating: true,
              title: const Text('TV Shows'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _refreshTvShows(context, true),
                  tooltip: 'Refresh TV show content',
                ),
              ],
            ),
            
            // Featured content at the top
            if (featuredShow != null)
              SliverToBoxAdapter(
                child: FeaturedContent(
                  featuredContent: featuredShow,
                  onPlayPress: () {
                    Navigator.pushNamed(
                      context,
                      '/detail',
                      arguments: featuredShow,
                    );
                  },
                  onInfoPress: () {
                    Navigator.pushNamed(
                      context,
                      '/detail',
                      arguments: featuredShow,
                    );
                  },
                ),
              ),
              
            // TV show categories
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = showsByCategory.entries.elementAt(index);
                  return ContentCarousel(
                    title: entry.key,
                    contentList: entry.value,
                    onTap: (show) {
                      Navigator.pushNamed(context, '/detail', arguments: show);
                    },
                  );
                },
                childCount: showsByCategory.length,
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
  Future<void> _refreshTvShows(BuildContext context, bool showSnackbar) async {
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
            const Text('Refreshing TV shows...'),
          ],
        ),
        duration: const Duration(seconds: 1),
        behavior: showSnackbar ? SnackBarBehavior.fixed : SnackBarBehavior.floating,
      ),
    );
    
    try {
      // Use our smart refresh focused on TV show content type
      await dataProvider.smartRefresh(contentType: 'tv_show');
      
      if (showSnackbar) {
        // Show success message if explicitly refreshing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TV shows refreshed successfully'),
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
