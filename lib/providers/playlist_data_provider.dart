import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:my_project_name/models/iptv_channel.dart';
import 'package:my_project_name/models/iptv_playlist.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/services/playlist_service.dart';
import 'package:my_project_name/services/api_service.dart';

class PlaylistDataProvider extends ChangeNotifier {
  List<IPTVPlaylist> _playlists = [];
  List<IPTVChannel> _allChannels = [];
  List<IPTVChannel> _favoriteChannels = [];
  Map<String, List<IPTVChannel>> _channelsByType = {};

  bool _isLoading = true;
  String _loadingMessage = 'Initializing...';
  String? _errorMessage;

  // Getters
  List<IPTVPlaylist> get playlists => _playlists;
  List<IPTVChannel> get allChannels => _allChannels;
  List<IPTVChannel> get favoriteChannels => _favoriteChannels;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  String? get errorMessage => _errorMessage;

  // Get channels by content type (cached)
  List<IPTVChannel> getChannelsByType(String contentType) {
    return _channelsByType[contentType] ?? [];
  }

  // Initialize and load all data
  Future<void> initializeData() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Clear API cache to ensure fresh data
      await Api.clearCache();

      // Load playlists from database first
      _loadingMessage = 'Loading playlists...';
      notifyListeners();

      _playlists = await DatabaseService.getPlaylists();
      debugPrint('Loaded ${_playlists.length} playlists');

      // Load favorite channels
      _loadingMessage = 'Loading favorites...';
      notifyListeners();

      _favoriteChannels = await DatabaseService.getFavorites();
      debugPrint('Loaded ${_favoriteChannels.length} favorites');

      // Initialize channels list
      _allChannels = [];

      // Load channels from each playlist with timeout
      if (_playlists.isNotEmpty) {
        for (final playlist in _playlists) {
          _loadingMessage = 'Loading channels from ${playlist.name}...';
          notifyListeners();

          try {
            debugPrint('Loading channels from playlist: ${playlist.name} (${playlist.url})');
            // Add timeout to prevent hanging
            List<IPTVChannel> playlistChannels = [];
            try {
              playlistChannels = await Future.any([
                PlaylistService.getChannelsFromPlaylist(playlist),
                Future.delayed(const Duration(seconds: 30))
                    .then((_) => throw TimeoutException('Timeout loading channels')),
              ]);
              debugPrint('Loaded ${playlistChannels.length} channels from ${playlist.name}');
            } on TimeoutException catch (e) {
              debugPrint('Timeout loading channels from ${playlist.name}: $e');
              continue;
            }

            _allChannels.addAll(playlistChannels);
          } catch (e) {
            debugPrint('Error loading channels from playlist ${playlist.name}: $e');
            // Continue with next playlist instead of failing completely
            continue;
          }
        }
      } else {
        debugPrint('No playlists found in database');
      }

      // Categorize channels by type
      _loadingMessage = 'Organizing content...';
      notifyListeners();

      _channelsByType = {
        'movie': [],
        'tv_show': [],
        'live': [],
        'unknown': [],
      };

      for (final channel in _allChannels) {
        final contentType = channel.contentType ?? 'unknown';
        _channelsByType.putIfAbsent(contentType, () => []);
        _channelsByType[contentType]!.add(channel);
      }

      debugPrint('Finished organizing channels:');
      debugPrint('- Movies: ${_channelsByType['movie']?.length ?? 0}');
      debugPrint('- TV Shows: ${_channelsByType['tv_show']?.length ?? 0}');
      debugPrint('- Live: ${_channelsByType['live']?.length ?? 0}');
      debugPrint('- Unknown: ${_channelsByType['unknown']?.length ?? 0}');

    } catch (e) {
      _errorMessage = 'Error loading data: $e';
      debugPrint('Error initializing data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh specific data parts
  Future<void> refreshPlaylists() async {
    try {
      _playlists = await DatabaseService.getPlaylists();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing playlists: $e');
    }
  }

  Future<void> refreshFavorites() async {
    try {
      _favoriteChannels = await DatabaseService.getFavorites();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing favorites: $e');
    }
  }

  // Add a new playlist and load its channels
  Future<Map<String, dynamic>> addPlaylist(String name, String url) async {
    try {
      debugPrint('Adding playlist: $name, URL: $url');
      
      // Use the existing method from PlaylistService
      final result = await PlaylistService.addPlaylist(name, url);
      debugPrint('Playlist add result: ${result['success']}');

      if (result['success']) {
        debugPrint('Playlist added successfully, refreshing data...');
        
        // Clear API cache
        await Api.clearCache();
        
        // Full reload of all data
        await initializeData();

        return result;
      }
      
      return result;
    } catch (e) {
      debugPrint('Error adding playlist: $e');
      return {'success': false, 'errorMessage': 'Error adding playlist: $e'};
    }
  }

  // Check if a channel is in favorites
  Future<bool> isFavorite(String url) async {
    return DatabaseService.isFavorite(url);
  }

  // Toggle favorite status for a channel
  Future<bool> toggleFavorite(IPTVChannel channel) async {
    try {
      // Check if it's already a favorite
      bool isFav = await DatabaseService.isFavorite(channel.url);

      if (isFav) {
        // Find the favorite channel ID
        IPTVChannel? favChannel = _favoriteChannels.firstWhere(
          (c) => c.url == channel.url,
          orElse: () => channel,
        );

        // Remove from favorites
        await DatabaseService.removeFavorite(favChannel.id!);
        _favoriteChannels.removeWhere((c) => c.url == channel.url);
      } else {
        // Add to favorites
        final addedChannel = await DatabaseService.addFavorite(channel);
        _favoriteChannels.add(addedChannel);
      }

      notifyListeners();
      return !isFav;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }
}