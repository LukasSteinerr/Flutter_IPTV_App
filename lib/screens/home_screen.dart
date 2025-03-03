import 'package:flutter/material.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/services/api_service.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/widgets/content_carousel.dart';
import 'package:my_project_name/widgets/featured_content.dart';
import 'package:my_project_name/screens/detail_screen.dart';
import 'package:my_project_name/screens/playlists_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  List<Movie> _trending = [];
  List<Movie> _featured = [];
  List<Movie> _favorites = []; // Changed from netflixOriginals to favorites
  List<Movie> _popular = [];
  List<Movie> _liveChannels = []; // Changed from upcoming to liveChannels
  List<Movie> _tvShows = [];
  bool _isLoading = true;
  bool _hasPlaylists = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
    _loadContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      // First check if we have any playlists
      final playlists = await DatabaseService.getPlaylists();
      _hasPlaylists = playlists.isNotEmpty;

      if (_hasPlaylists) {
        // Load all content types from API service
        final trending = await Api.getTrending();
        final popular = await Api.getPopular();
        final topRated = await Api.getTopRated();
        final nowPlaying = await Api.getNowPlaying();
        final tvShows = await Api.getPopularTv();

        setState(() {
          _trending = Movie.fromJsonList(trending);
          _favorites = Movie.fromJsonList(topRated);
          _popular = Movie.fromJsonList(popular);
          _liveChannels = Movie.fromJsonList(nowPlaying);
          _tvShows = Movie.fromJsonList(tvShows);

          // Pick some featured content with good images
          _featured =
              _trending
                  .where(
                    (movie) =>
                        movie.backdropPath != null &&
                        movie.backdropPath!.isNotEmpty,
                  )
                  .take(5)
                  .toList();

          if (_featured.isEmpty && _trending.isNotEmpty) {
            _featured = [_trending.first];
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading content: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToDetailsScreen(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size(screenSize.width, 50.0),
        child: _buildAppBar(),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.netflixRed),
              )
              : _hasPlaylists
              ? _buildContentList()
              : _buildNoPlaylistsView(),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(
        (_scrollOffset / 350).clamp(0, 1).toDouble(),
      ),
      elevation: 0,
      title: const Text(
        'IPTV Streamer',
        style: TextStyle(
          color: AppColors.netflixRed,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.playlist_add),
          tooltip: 'Manage Playlists',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlaylistsScreen()),
            );
          },
        ),
        IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
      ],
    );
  }

  Widget _buildNoPlaylistsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.playlist_add, size: 80, color: AppColors.netflixRed),
          const SizedBox(height: 20),
          const Text(
            'No Playlists Added',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add an IPTV playlist to start watching',
            style: TextStyle(fontSize: 16, color: AppColors.netflixLightGrey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlaylistsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.netflixRed,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('Add Playlist'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    return ListView(
      controller: _scrollController,
      children: [
        if (_featured.isNotEmpty)
          FeaturedContent(
            featuredContent: _featured.first,
            onPlayPress: () {
              if (_featured.isNotEmpty) {
                _navigateToDetailsScreen(_featured.first);
              }
            },
            onInfoPress: () {
              if (_featured.isNotEmpty) {
                _navigateToDetailsScreen(_featured.first);
              }
            },
          ),

        if (_favorites.isNotEmpty)
          ContentCarousel(
            title: 'My Favorites',
            contentList: _favorites,
            isOriginals: true,
            onTap: _navigateToDetailsScreen,
          ),

        if (_trending.isNotEmpty)
          ContentCarousel(
            title: 'All Channels',
            contentList: _trending,
            onTap: _navigateToDetailsScreen,
          ),

        if (_liveChannels.isNotEmpty)
          ContentCarousel(
            title: 'Live TV',
            contentList: _liveChannels,
            onTap: _navigateToDetailsScreen,
          ),

        if (_popular.isNotEmpty)
          ContentCarousel(
            title: 'Movies',
            contentList: _popular,
            onTap: _navigateToDetailsScreen,
          ),

        if (_tvShows.isNotEmpty)
          ContentCarousel(
            title: 'TV Shows',
            contentList: _tvShows,
            onTap: _navigateToDetailsScreen,
          ),

        const SizedBox(height: 20.0),
      ],
    );
  }
}
