import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_project_name/models/iptv_channel.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/services/playlist_data_provider.dart';
import 'package:my_project_name/widgets/content_carousel.dart';

class LiveTVScreen extends StatelessWidget {
  const LiveTVScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<PlaylistDataProvider>(context);
    final channels = dataProvider.getChannelsByType('live');

    if (dataProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dataProvider.errorMessage != null) {
      return Center(child: Text(dataProvider.errorMessage!));
    }

    if (channels.isEmpty) {
      return const Center(
        child: Text('No live channels found. Add playlists to see content.'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await dataProvider.initializeData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Simple refresh - just reload the data
          await dataProvider.initializeData();
        },
        child: ListView(
          children: [
            // Display each category
            ...channelsByCategory.entries.map((entry) {
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
