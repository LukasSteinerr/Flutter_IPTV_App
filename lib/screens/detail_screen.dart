import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/models/iptv_channel.dart';
import 'package:my_project_name/services/api_service.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class DetailScreen extends StatefulWidget {
  final Movie movie;

  const DetailScreen({super..key, required this.movie}

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
      _similarContent =
          Movie.fromJsonList(
            trending,
          ).where((m) => m.id != widget.movie.id).take(10).toList();

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

      setState(() {
        _isPlayingVideo = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error playing video: $e');
      WakelockPlus.disable();

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
    if (widget.movie.url == null) return;

    try {
      if (_isFavorite) {
        // Find the favorite to delete
        final favorites = await DatabaseService.getFavorites();
        final favorite = favorites.firstWhere(
          (f) => f.url == widget.movie.url,
          orElse:
              () => IPTVChannel(
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
          group:
              widget.movie.genres?.isNotEmpty == true
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
        backgroundColor:
            _isPlayingVideo ? AppColors.netflixBlack : Colors.transparent,
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
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.netflixRed),
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
                icon: const Icon(Icons.stop),
                color: AppColors.netflixRed,
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
        SizedBox
          height: 250,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: widget.movie.fullBackdropPath,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => Container(
                  color: AppColors.netflixDarkGrey,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.netflixRed,
                    ),
                  ),
                ),
            errorWidget:
                (context, url, error) => Container(
                  color: AppColors.netflixDarkGrey,
                  child: const Icon(Icons.error, color: AppColors.netflixRed),
                ),
          ),
        ),
        Container(
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 20,
          right: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 100,
                  height: 150,
                  child: CachedNetworkImage(
                    imageUrl: widget.movie.fullPosterPath,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: AppColors.netflixDarkGrey,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.netflixRed,
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: AppColors.netflixDarkGrey,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: AppColors.netflixRed,
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.movie.title,
                      style: const TextStyle(
                        fontSize: 24,
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
                            itemBuilder:
                                (context, _) =>
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
          ),
        ),
      ],
    );
  }

  Widget _buildGenres() {
    List<dynamic> genres = [];

    // Use the genres from the movie if available
    if (widget.movie.genres != null && widget.movie.genres!.isNotEmpty) {
      return Wrap(
        spacing: 8,
        children:
            widget.movie.genres!.map((genre) {
              return Chip(
                backgroundColor: AppColors.netflixDarkGrey,
                label: Text(
                  genre,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.netflixWhite,
                  ),
                ),
              );
            }).toList(),
      );
    }

    // Otherwise try to get genres from details
    if (_movieDetails != null && _movieDetails!.containsKey('genres')) {
      genres = _movieDetails!['genres'];
    }

    return Wrap(
      spacing: 8,
      children:
          genres.map<Widget>((genre) {
            return Chip(
              backgroundColor: AppColors.netflixDarkGrey,
              label: Text(
                genre['name'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.netflixWhite,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            _isFavorite ? Icons.check : Icons.add,
            'My List',
            onPressed: _toggleFavorite,
          ),
          _buildPlayButton(),
          _buildActionButton(Icons.thumb_up_outlined, 'Rate'),
          _buildActionButton(Icons.share, 'Share'),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return ElevatedButton(
      onPressed: _playVideo,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.netflixWhite,
        foregroundColor: AppColors.netflixBlack,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Row(
        children: [Icon(Icons.play_arrow), SizedBox(width: 4), Text('Play')],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label, {
    VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        IconButton(icon: Icon(icon), onPressed: onPressed ?? () {}),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildOverview() {
    String overview = widget.movie.overview ?? 'No overview available';

    // For IPTV channels, add more context
    if (widget.movie.url != null && widget.movie.overview == null) {
      overview =
          'Stream from ${widget.movie.genres?.join(', ') ?? widget.movie.mediaType}';
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(overview, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCast() {
    List<dynamic> cast = [];
    if (_movieDetails != null &&
        _movieDetails!.containsKey('credits') &&
        _movieDetails!['credits'].containsKey('cast')) {
      cast = _movieDetails!['credits']['cast'];
    }

    if (cast.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Cast',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: cast.length > 10 ? 10 : cast.length,
            itemBuilder: (context, index) {
              final person = cast[index];
              String imageUrl =
                  'https://via.placeholder.com/185x278?text=No+Image';

              final profilePath = person['profile_path'];
              if (profilePath != null && profilePath.toString().isNotEmpty) {
                if (profilePath.toString().startsWith('http')) {
                  imageUrl = profilePath;
                } else {
                  imageUrl = 'https://image.tmdb.org/t/p/w185$profilePath';
                }
              }

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: CachedNetworkImageProvider(imageUrl),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        person['name'] ?? '',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'More Like This',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _similarContent.length,
          itemBuilder: (context, index) {
            final movie = _similarContent[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailScreen(movie: movie)),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: movie.fullPosterPath,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: AppColors.netflixDarkGrey,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.netflixRed,
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: AppColors.netflixDarkGrey,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: AppColors.netflixRed,
                        ),
                      ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
