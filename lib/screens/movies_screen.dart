import 'package:flutter/material.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/screens/detail_screen.dart';
import 'package:my_project_name/services/api_service.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/widgets/content_carousel.dart';
import 'package:my_project_name/widgets/content_grid.dart';
import 'package:my_project_name/widgets/featured_content.dart';
import 'package:my_project_name/screens/search_screen.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  List<Movie> _featured = [];
  List<Movie> _popular = [];
  List<Movie> _trending = [];
  List<Movie> _favorites = [];
  bool _isLoading = true;
  bool _hasPlaylists = false;
  String _viewType = 'carousel'; // 'carousel' or 'grid'

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
        // Load all relevant content types for movies
        final popular = await Api.getPopular();
        final trending = await Api.getTrending();
        final topRated = await Api.getTopRated();

        if (mounted) {
          setState(() {
            _popular =
                Movie.fromJsonList(
                  popular,
                ).where((m) => m.mediaType == 'movie').toList();

            _trending =
                Movie.fromJsonList(
                  trending,
                ).where((m) => m.mediaType == 'movie').toList();

            _favorites =
                Movie.fromJsonList(
                  topRated,
                ).where((m) => m.mediaType == 'movie').toList();

            // Pick featured content with good images
            _featured =
                _popular
                    .where(
                      (movie) =>
                          movie.backdropPath != null &&
                          movie.backdropPath!.isNotEmpty,
                    )
                    .take(5)
                    .toList();

            if (_featured.isEmpty && _popular.isNotEmpty) {
              _featured = [_popular.first];
            }

            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToDetailsScreen(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(movie: movie)),
    );
  }

  void _toggleViewType() {
    setState(() {
      _viewType = _viewType == 'carousel' ? 'grid' : 'carousel';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size(MediaQuery.of(context).size.width, 50.0),
        child: _buildAppBar(),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasPlaylists
              ? _buildContentList()
              : _buildNoPlaylistsView(),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent.withOpacity(
        (_scrollOffset / 350).clamp(0, 1).toDouble(),
      ),
      elevation: 0,
      title: const Text(
        'Movies',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _viewType == 'carousel' ? Icons.grid_view : Icons.view_carousel,
          ),
          onPressed: _toggleViewType,
          tooltip: _viewType == 'carousel' ? 'Grid View' : 'Carousel View',
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoPlaylistsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.playlist_add,
            size: 80,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 20),
          const Text(
            'No Playlists Added',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add an IPTV playlist to start watching movies',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // Navigate to the settings tab to add a playlist
              // This will be handled by the parent NavigationScreen
              if (context.mounted) {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const MoviesScreen()));
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('Add Playlist'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    if (_viewType == 'carousel') {
      return _buildCarouselView();
    } else {
      return _buildGridView();
    }
  }

  Widget _buildCarouselView() {
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
            title: 'Trending Movies',
            contentList: _trending,
            onTap: _navigateToDetailsScreen,
          ),

        if (_popular.isNotEmpty)
          ContentCarousel(
            title: 'Popular Movies',
            contentList: _popular,
            onTap: _navigateToDetailsScreen,
          ),

        const SizedBox(height: 20.0),
      ],
    );
  }

  Widget _buildGridView() {
    List<Movie> allMovies = [];

    // Combine all movies, but keep favorites first
    allMovies.addAll(_favorites);

    // Add movies from other lists if not already in allMovies
    for (var movie in [..._trending, ..._popular]) {
      if (!allMovies.any((m) => m.id == movie.id)) {
        allMovies.add(movie);
      }
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Text(
              'All Movies',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: ContentGrid(
            contentList: allMovies,
            onTap: _navigateToDetailsScreen,
          ),
        ),
      ],
    );
  }
}
