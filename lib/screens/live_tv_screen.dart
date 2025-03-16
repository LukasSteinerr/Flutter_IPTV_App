import 'package:flutter/material.dart';
import 'package:my_project_name/models/iptv_channel.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/services/playlist_service.dart';
import 'package:my_project_name/widgets/content_carousel.dart';

class LiveTVScreen extends StatefulWidget {
  const LiveTVScreen({Key? key}) : super(key: key);

  @override
  State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  List<IPTVChannel> _channels = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadLiveChannels();
  }

  Future<void> _loadLiveChannels() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Get all playlists and their channels
      final playlists = await DatabaseService.getPlaylists();
      final allChannels = <IPTVChannel>[];

      for (final playlist in playlists) {
        final channels = await PlaylistService.getChannelsFromPlaylist(
          playlist,
        );
        allChannels.addAll(channels);
      }

      // Filter channels that are live TV using contentType
      final liveChannels = await PlaylistService.getChannelsByContentType(
        allChannels,
        'live',
      );

      setState(() {
        _channels = liveChannels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading live channels: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    if (_channels.isEmpty) {
      return const Center(
        child: Text('No live channels found. Add playlists to see content.'),
      );
    }

    // Group channels by category
    final Map<String, List<Movie>> channelsByCategory = {};
    for (final channel in _channels) {
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
            onPressed: _loadLiveChannels,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLiveChannels,
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
