import 'package:flutter/material.dart';
import 'package:my_project_name/models/iptv_channel.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/services/playlist_service.dart';
import 'package:my_project_name/widgets/content_carousel.dart';
import 'package:my_project_name/widgets/featured_content.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({Key? key}) : super(key: key);

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  List<IPTVChannel> _channels = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
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

      // Filter channels that are movies using contentType
      final movieChannels = await PlaylistService.getChannelsByContentType(
        allChannels,
        'movie',
      );

      setState(() {
        _channels = movieChannels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading movies: $e';
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
        child: Text('No movies found. Add playlists to see content.'),
      );
    }

    // Convert channels to Movie objects for the UI components
    final movies =
        _channels.map((channel) {
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
    for (final channel in _channels) {
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
        onRefresh: _loadMovies,
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
