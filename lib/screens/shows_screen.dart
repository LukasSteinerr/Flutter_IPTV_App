import 'package:flutter/material.dart';
import 'package:my_project_name/models/iptv_channel.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/services/playlist_service.dart';
import 'package:my_project_name/widgets/content_carousel.dart';
import 'package:my_project_name/widgets/featured_content.dart';

class ShowsScreen extends StatefulWidget {
  const ShowsScreen({Key? key}) : super(key: key);

  @override
  State<ShowsScreen> createState() => _ShowsScreenState();
}

class _ShowsScreenState extends State<ShowsScreen> {
  List<IPTVChannel> _channels = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadShows();
  }

  Future<void> _loadShows() async {
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

      // Filter channels that are TV shows using contentType
      final showChannels = await PlaylistService.getChannelsByContentType(
        allChannels,
        'tv_show',
      );

      setState(() {
        _channels = showChannels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading TV shows: $e';
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
        child: Text('No TV shows found. Add playlists to see content.'),
      );
    }

    // Convert channels to Movie objects for the UI components
    final shows =
        _channels.map((channel) {
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
    for (final channel in _channels) {
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
        onRefresh: _loadShows,
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
