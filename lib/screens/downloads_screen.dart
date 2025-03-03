import 'package:flutter/material.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/screens/detail_screen.dart';
import 'package:my_project_name/services/api_service.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<Movie> _liveChannels = [];
  bool _isLoading = true;
  bool _hasPlaylists = false;

  @override
  void initState() {
    super.initState();
    _loadLiveChannels();
  }

  Future<void> _loadLiveChannels() async {
    try {
      // First check if we have any playlists
      final playlists = await DatabaseService.getPlaylists();
      _hasPlaylists = playlists.isNotEmpty;

      if (_hasPlaylists) {
        final nowPlaying = await Api.getNowPlaying();
        setState(() {
          _liveChannels = Movie.fromJsonList(nowPlaying);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading live channels: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.netflixBlack,
        title: const Text('Live TV'),
        actions: [
          IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadLiveChannels();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.netflixRed),
              )
              : _hasPlaylists
              ? _buildChannelsGrid()
              : _buildNoPlaylistsView(),
    );
  }

  Widget _buildChannelsGrid() {
    if (_liveChannels.isEmpty) {
      return const Center(
        child: Text(
          'No live channels found',
          style: TextStyle(color: AppColors.netflixLightGrey, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 16,
      ),
      itemCount: _liveChannels.length,
      itemBuilder: (context, index) {
        final channel = _liveChannels[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailScreen(movie: channel)),
            );
          },
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: channel.fullPosterPath,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: AppColors.netflixDarkGrey,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.netflixRed,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: AppColors.netflixDarkGrey,
                              child: Center(
                                child: Text(
                                  channel.title.isNotEmpty
                                      ? channel.title[0]
                                      : '?',
                                  style: const TextStyle(
                                    color: AppColors.netflixRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32,
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                channel.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      },
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/playlists');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.netflixRed,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Add Playlist'),
          ),
        ],
      ),
    );
  }
}
