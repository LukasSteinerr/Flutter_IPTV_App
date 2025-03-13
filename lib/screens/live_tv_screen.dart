import 'package:flutter/material.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/screens/detail_screen.dart';
import 'package:my_project_name/services/api_service.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/services/epg_service.dart';
import 'package:my_project_name/services/preferences_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _categories = [
    'All',
    'Sports',
    'News',
    'Entertainment',
    'Kids',
  ];
  String _selectedCategory = 'All';
  List<Movie> _liveChannels = [];
  bool _isLoading = true;
  bool _hasPlaylists = false;
  bool _loadingEpg = false;
  bool _hasEpg = false;

  late TabController _tabController;

  final Map<int, EpgChannel?> _channelEpgMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First check if we have any playlists
      final playlists = await DatabaseService.getPlaylists();
      _hasPlaylists = playlists.isNotEmpty;

      if (_hasPlaylists) {
        // Load live TV channels
        final nowPlaying = await Api.getNowPlaying();

        if (mounted) {
          setState(() {
            _liveChannels = Movie.fromJsonList(nowPlaying);
            _isLoading = false;
          });

          // Load EPG data if available
          _loadEpgData();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading live TV content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEpgData() async {
    if (_liveChannels.isEmpty) return;

    setState(() {
      _loadingEpg = true;
    });

    try {
      final epgUrl = await PreferencesService().getEpgUrl();

      if (epgUrl != null && epgUrl.isNotEmpty) {
        await EpgService().fetchEpgData(epgUrl);

        // Match channels with EPG data
        for (var channel in _liveChannels) {
          final epgChannel = EpgService().findChannelByName(channel.title);
          if (epgChannel != null) {
            _channelEpgMap[channel.id] = epgChannel;
          }
        }

        if (mounted) {
          setState(() {
            _hasEpg = true;
            _loadingEpg = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loadingEpg = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading EPG data: $e');
      if (mounted) {
        setState(() {
          _loadingEpg = false;
        });
      }
    }
  }

  List<Movie> _getChannelsByCategory(String category) {
    if (category == 'All') return _liveChannels;

    return _liveChannels.where((channel) {
      final genres = channel.genres;
      if (genres == null || genres.isEmpty) return false;

      return genres.any(
        (genre) => genre.toLowerCase().contains(category.toLowerCase()),
      );
    }).toList();
  }

  void _navigateToDetailsScreen(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live TV'),
        actions: [
          if (_hasPlaylists && _liveChannels.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadContent,
              tooltip: 'Refresh',
            ),
        ],
        bottom:
            _hasPlaylists && _liveChannels.isNotEmpty
                ? TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs:
                      _categories
                          .map((category) => Tab(text: category))
                          .toList(),
                  onTap: (index) {
                    setState(() {
                      _selectedCategory = _categories[index];
                    });
                  },
                )
                : null,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasPlaylists
              ? _liveChannels.isNotEmpty
                  ? _buildChannelList()
                  : _buildNoChannelsView()
              : _buildNoPlaylistsView(),
    );
  }

  Widget _buildChannelList() {
    final filteredChannels = _getChannelsByCategory(_selectedCategory);

    return filteredChannels.isEmpty
        ? Center(
          child: Text(
            'No channels found in category: $_selectedCategory',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        )
        : ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredChannels.length,
          itemBuilder: (context, index) {
            final channel = filteredChannels[index];
            return _buildChannelListItem(channel);
          },
        );
  }

  Widget _buildChannelListItem(Movie channel) {
    // Get EPG data if available
    final epgChannel = _channelEpgMap[channel.id];
    final currentProgram = epgChannel?.currentProgram;
    final nextProgram =
        epgChannel?.upcomingPrograms.isNotEmpty == true
            ? epgChannel!.upcomingPrograms.first
            : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () => _navigateToDetailsScreen(channel),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      // Channel image
                      CachedNetworkImage(
                        imageUrl: channel.fullPosterPath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder:
                            (context, url) => Container(
                              color: AppColors.cardBackground,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: AppColors.cardBackground,
                              child: Center(
                                child: Text(
                                  channel.title.isNotEmpty
                                      ? channel.title[0]
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                      ),

                      // Live badge
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
              ),

              const SizedBox(width: 16),

              // Channel info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (channel.genres?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          channel.genres!.join(' • '),
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Show current program if EPG available
                    if (_hasEpg && currentProgram != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'On Now',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${currentProgram.formattedStartTime} - ${currentProgram.formattedEndTime}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentProgram.title,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          // Show next program if available
                          if (nextProgram != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.textSecondary
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Next',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${nextProgram.formattedStartTime}: ${nextProgram.title}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    else if (_loadingEpg)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Loading program info...'),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No program guide available'),
                      ),
                  ],
                ),
              ),

              // Play button
              IconButton(
                icon: const Icon(Icons.play_circle_filled),
                color: AppColors.primaryColor,
                iconSize: 36,
                onPressed: () => _navigateToDetailsScreen(channel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoChannelsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.live_tv_outlined,
            size: 80,
            color: AppColors.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Live TV Channels Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your playlist doesn\'t contain any live TV channels',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadContent, child: const Text('Reload')),
        ],
      ),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add an IPTV playlist to access live TV channels',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // Navigate to settings tab - will be handled by parent widget
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
}
