import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/services/playlist_data_provider.dart';
import 'package:my_project_name/widgets/content_carousel.dart';
import 'package:my_project_name/widgets/shimmer_loading.dart';
import 'package:my_project_name/constants/app_theme.dart';

class LiveTVScreen extends StatelessWidget {
  const LiveTVScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<PlaylistDataProvider>(context);
    final channels = dataProvider.getChannelsByType('live');

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
              onPressed: () => _refreshLiveTV(context, true),
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
            const Text('No live channels found. Add playlists to see content.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              child: const Text('Add Playlist'),
            ),
            if (dataProvider.playlists.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _refreshLiveTV(context, true),
                child: const Text('Refresh Live TV'),
              ),
            ],
          ],
        ),
      );
    }

    // Group channels by category
    final Map<String, List<Movie>> channelsByCategory = {};
    for (final channel in channels) {
      final category = channel.group;
      if (!channelsByCategory.containsKey(category)) {
        channelsByCategory[category] = [];
      }
      channelsByCategory[category]!.add(
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live TV'),
        backgroundColor: AppColors.netflixBlack,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshLiveTV(context, true),
            tooltip: 'Refresh Live TV channels',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshLiveTV(context, false),
        child: channelsByCategory.isEmpty
            ? const Center(
                child: Text('No channels available in your playlists'),
              )
            : ListView.builder(
                itemCount: channelsByCategory.length,
                itemBuilder: (context, index) {
                  final entry = channelsByCategory.entries.elementAt(index);
                  return ContentCarousel(
                    title: entry.key,
                    contentList: entry.value,
                    onTap: (movie) {
                      // Navigate directly to detail screen for playback
                      Navigator.pushNamed(context, '/detail', arguments: movie);
                    },
                  );
                },
              ),
      ),
    );
  }

  // Smart refresh function that uses our optimized services
  Future<void> _refreshLiveTV(BuildContext context, bool showSnackbar) async {
    final dataProvider =
        Provider.of<PlaylistDataProvider>(context, listen: false);

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
            const Text('Refreshing live channels...'),
          ],
        ),
        duration: const Duration(seconds: 1),
        behavior: showSnackbar ? SnackBarBehavior.fixed : SnackBarBehavior.floating,
      ),
    );

    try {
      // Use our smart refresh focused on live TV content type
      await dataProvider.smartRefresh(contentType: 'live');

      if (showSnackbar) {
        // Show success message if explicitly refreshing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live TV channels refreshed successfully'),
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
