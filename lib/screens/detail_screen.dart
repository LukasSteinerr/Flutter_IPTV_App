import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/models/iptv_channel.dart';
import 'package:my_project_name/services/api_service.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/widgets/shimmer_loading.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class DetailScreen extends StatefulWidget {
  final Movie movie;

  const DetailScreen({super.key, required this.movie});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Map<String, dynamic>? _movieDetails;
  bool _isLoading = true;
  List<Movie> _similarContent = [];
  bool _isPlayingVideo = false;
  bool _isFavorite = false;

  // Video player controllers
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    try {
      if (widget.movie.mediaType == 'movie') {
        _movieDetails = await Api.getMovieDetails(widget.movie.id);
      } else {
        _movieDetails = await Api.getTvDetails(widget.movie.id);
      }

      // Check if this channel is a favorite
      if (widget.movie.url != null) {
        _isFavorite = await DatabaseService.isFavorite(widget.movie.url!);
      }

      // Load similar content
      final trending = await Api.getTrending();
      _similarContent = Movie.fromJsonList(trending)
          .where((m) => m.id != widget.movie.id)
          .take(10)
          .toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading content details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playVideo() async {
    if (!mounted) return;
    
    if (widget.movie.url == null || widget.movie.url!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No stream URL available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Keep screen on during video playback
      await WakelockPlus.enable();

      setState(() {
        _isLoading = true;
      });

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.movie.url!),
      );

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error playing video: $errorMessage',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      );

      if (!mounted) return;
      
      setState(() {
        _isPlayingVideo = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error playing video: $e');
      WakelockPlus.disable();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopVideo() {
    _videoPlayerController?.pause();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    _videoPlayerController = null;
    _chewieController = null;

    WakelockPlus.disable();

    setState(() {
      _isPlayingVideo = false;
    });
  }

  Future<void> _toggleFavorite() async {
    if (!mounted) return;
    if (widget.movie.url == null) return;

    try {
      if (_isFavorite) {
        // Find the favorite to delete
        final favorites = await DatabaseService.getFavorites();
        final favorite = favorites.firstWhere(
          (f) => f.url == widget.movie.url,
          orElse: () => IPTVChannel(
            name: widget.movie.title,
            url: widget.movie.url!,
            group: 'Unknown',
          ),
        );

        if (favorite.id != null) {
          await DatabaseService.removeFavorite(favorite.id!);
        }
      } else {
        // Add to favorites
        final channel = IPTVChannel(
          name: widget.movie.title,
          url: widget.movie.url!,
          group: widget.movie.genres?.isNotEmpty == true
              ? widget.movie.genres!.first
              : widget.movie.mediaType,
          logo: widget.movie.posterPath,
        );

        await DatabaseService.addFavorite(channel);
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });

      // Clear API cache to refresh content
      await Api.clearCache();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: !_isPlayingVideo,
      appBar: AppBar(
        backgroundColor: _isPlayingVideo 
            ? AppColors.netflixBlack 
            : Colors.transparent,
        elevation: _isPlayingVideo ? 4 : 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.netflixWhite),
          onPressed: () {
            if (_isPlayingVideo) {
              _stopVideo();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [IconButton(icon: const Icon(Icons.cast), onPressed: () {})],
      ),
      body: _isLoading
          ? const Center(
              child: ShimmerContainer(
                width: 50,
                height: 50,
                borderRadius: 25,
              ),
            )
          : _isPlayingVideo
              ? _buildVideoPlayer()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildActions(),
                      _buildOverview(),
                      if (_movieDetails?['credits'] != null &&
                          _movieDetails!['credits']['cast'] != null)
                        _buildCast(),
                      _buildSimilarContent(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_chewieController == null) {
      return const Center(
        child: Text(
          'Error initializing video player',
          style: TextStyle(color: AppColors.netflixWhite),
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: Center(child: Chewie(controller: _chewieController!))),
        Container(
          color: AppColors.netflixBlack,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.movie.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _stopVideo,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        // Background image with gradient overlay
        SizedBox(
          height: 300,
          width: double.infinity,
          child: ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(0),
                  Colors.black.withAlpha(230),
                ],
              ).createShader(rect);
            },
            blendMode: BlendMode.darken,
            child: CachedNetworkImage(
              imageUrl: widget.movie.fullBackdropPath,
              fit: BoxFit.cover,
              placeholder: (context, url) => const ShimmerContainer(
                width: double.infinity,
                height: 300,
                borderRadius: 0,
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.netflixDarkGrey,
                child: const Icon(
                  Icons.error,
                  color: AppColors.netflixRed,
                ),
              ),
            ),
          ),
        ),

        // Content overlay
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.movie.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.netflixWhite,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.movie.releaseDate != null)
                    Text(
                      widget.movie.releaseDate!.substring(0, 4),
                      style: const TextStyle(
                        color: AppColors.netflixLightGrey,
                      ),
                    ),
                  if (widget.movie.releaseDate != null)
                    const SizedBox(width: 12),
                  if (widget.movie.voteAverage != null)
                    RatingBar.builder(
                      initialRating: (widget.movie.voteAverage ?? 0) / 2,
                      minRating: 0,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 18,
                      ignoreGestures: true,
                      unratedColor: AppColors.netflixDarkGrey,
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) {},
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildGenres(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenres() {
    List<dynamic> genres = [];
    if (_movieDetails != null) {
      genres = _movieDetails!['genres'] ?? [];
    }

    return Wrap(
      spacing: 8,
      children: genres
          .map((genre) => Chip(
                label: Text(genre['name']),
                backgroundColor: AppColors.netflixDarkGrey,
                labelStyle: const TextStyle(color: AppColors.netflixWhite),
              ))
          .toList(),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.play_arrow,
            label: 'Play',
            onPressed: _playVideo,
            isPrimary: true,
          ),
          _buildActionButton(
            icon: _isFavorite ? Icons.check : Icons.add,
            label: _isFavorite ? 'Added' : 'My List',
            onPressed: _toggleFavorite,
          ),
          _buildActionButton(
            icon: Icons.thumb_up_outlined,
            label: 'Rate',
            onPressed: () {},
          ),
          _buildActionButton(
            icon: Icons.share,
            label: 'Share',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isPrimary ? AppColors.netflixRed : AppColors.netflixDarkGrey,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon, color: AppColors.netflixWhite),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.netflixWhite,
              ),
        ),
      ],
    );
  }

  Widget _buildOverview() {
    String overview = '';
    if (_movieDetails != null) {
      overview = _movieDetails!['overview'] ?? 'No overview available.';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.netflixWhite,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            overview,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.netflixWhite,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCast() {
    List<dynamic> cast = _movieDetails!['credits']['cast'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Cast',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.netflixWhite,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: cast.length,
            itemBuilder: (context, index) {
              final actor = cast[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.netflixDarkGrey,
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.netflixWhite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        actor['name'],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.netflixWhite,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarContent() {
    if (_similarContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'More Like This',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.netflixWhite,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _similarContent.length,
            itemBuilder: (context, index) {
              final movie = _similarContent[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(movie: movie),
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: CachedNetworkImage(
                            imageUrl: movie.fullPosterPath,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const ShimmerContainer(
                                    width: 120, height: 180),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.netflixDarkGrey,
                              child: const Icon(
                                Icons.error,
                                color: AppColors.netflixRed,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.netflixWhite,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
