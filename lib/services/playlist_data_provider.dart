import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:my_project_name/models/iptv_channel.dart';
import 'package:my_project_name/models/iptv_playlist.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/services/playlist_service.dart';

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

      // Load playlists from database first
      _loadingMessage = 'Loading playlists...';
      notifyListeners();

      _playlists = await DatabaseService.getPlaylists();

      // Load favorite channels
      _loadingMessage = 'Loading favorites...';
      notifyListeners();

      _favoriteChannels = await DatabaseService.getFavorites();

      // Initialize channels list
      _allChannels = [];

      // Load channels from each playlist with parallel processing
      if (_playlists.isNotEmpty) {
        _loadingMessage = 'Loading all channels...';
        notifyListeners();
        
        final futures = <Future<List<IPTVChannel>>>[];
        
        for (final playlist in _playlists) {
          futures.add(
            PlaylistService.getChannelsFromPlaylist(playlist)
                .timeout(const Duration(seconds: 30))
                .catchError((e) {
                  debugPrint('Error loading channels from ${playlist.name}: $e');
                  return <IPTVChannel>[];
                })
          );
        }
        
        // Process all playlists in parallel
        final results = await Future.wait(futures);
        
        // Combine all channels
        for (final channels in results) {
          _allChannels.addAll(channels);
        }
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
      
      // Log channel counts for debugging
      debugPrint('Total channels loaded: ${_allChannels.length}');
      debugPrint('Movies: ${_channelsByType['movie']?.length ?? 0}');
      debugPrint('TV Shows: ${_channelsByType['tv_show']?.length ?? 0}');
      debugPrint('Live TV: ${_channelsByType['live']?.length ?? 0}');
      debugPrint('Unknown: ${_channelsByType['unknown']?.length ?? 0}');
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
  
  // Smart refresh method for refreshing specific content types or playlists
  Future<void> smartRefresh({
    String? contentType,
    int? playlistId,
    bool clearCache = false,
  }) async {
    try {
      // Set temporary loading state for UI feedback
      final wasLoading = _isLoading;
      _isLoading = true;
      _loadingMessage = 'Refreshing content...';
      notifyListeners();
      
      // Clear cache if requested
      if (clearCache) {
        PlaylistService.clearCache();
      }
      
      if (playlistId != null) {
        // Refresh specific playlist
        final playlist = _playlists.firstWhere(
          (p) => p.id == playlistId,
          orElse: () => throw Exception('Playlist not found'),
        );
        
        _loadingMessage = 'Refreshing ${playlist.name}...';
        notifyListeners();
        
        // Get fresh channels
        final freshChannels = await PlaylistService.getChannelsFromPlaylist(playlist);
        
        // Remove old channels from this playlist
        _allChannels.removeWhere((c) => 
          c.id != null && 
          c.id! >= 10000000 && 
          c.id! < 20000000 && 
          (c.id! % 10000000) == playlistId
        );
        
        // Add new channels with modified IDs to track which playlist they belong to
        // This adds an ID scheme where playlist ID is encoded into channel ID
        final updatedChannels = freshChannels.map((c) => 
          IPTVChannel(
            id: 10000000 + (playlistId * 1000) + (c.id ?? 0),
            name: c.name,
            url: c.url,
            group: c.group,
            logo: c.logo,
            contentType: c.contentType,
          )
        ).toList();
        
        _allChannels.addAll(updatedChannels);
      } else if (contentType != null) {
        // Refresh specific content type
        _loadingMessage = 'Refreshing ${_getReadableContentType(contentType)}...';
        notifyListeners();
        
        // Reload all playlists but only update the specified content type
        for (final playlist in _playlists) {
          final allChannels = await PlaylistService.getChannelsFromPlaylist(playlist);
          final typeChannels = allChannels.where((c) => 
            c.contentType == contentType || 
            (c.contentType == null && PlaylistService.determineContentType(c.group) == contentType)
          ).toList();
          
          // Remove old channels of this type
          _allChannels.removeWhere((c) => c.contentType == contentType);
          _channelsByType[contentType] = [];
          
          // Add fresh channels
          _allChannels.addAll(typeChannels);
          _channelsByType[contentType] = typeChannels;
        }
      } else {
        // Full refresh, reload everything
        await initializeData();
        return; // initializeData handles all the refreshing and notification
      }
      
      // Re-categorize channels
      _recategorizeChannels();
      
      // Restore previous loading state
      _isLoading = wasLoading;
      notifyListeners();
    } catch (e) {
      debugPrint('Error in smart refresh: $e');
      _errorMessage = 'Error refreshing content: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Helper method to recategorize all channels
  void _recategorizeChannels() {
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
    
    // Log channel counts for debugging
    debugPrint('Recategorized - Total channels: ${_allChannels.length}');
    debugPrint('Movies: ${_channelsByType['movie']?.length ?? 0}');
    debugPrint('TV Shows: ${_channelsByType['tv_show']?.length ?? 0}');
    debugPrint('Live TV: ${_channelsByType['live']?.length ?? 0}');
    debugPrint('Unknown: ${_channelsByType['unknown']?.length ?? 0}');
  }
  
  String _getReadableContentType(String type) {
    switch (type) {
      case 'movie': return 'Movies';
      case 'tv_show': return 'TV Shows';
      case 'live': return 'Live TV';
      default: return 'Content';
    }
  }

  // Add a new playlist and load its channels
  Future<Map<String, dynamic>> addPlaylist(String name, String url) async {
    try {
      // Use the existing method
      final result = await PlaylistService.addPlaylist(name, url);

      if (result['success']) {
        // Refresh playlists
        await refreshPlaylists();

        // Add new channels to our collection
        if (result['channels'] != null && result['channels'].isNotEmpty) {
          final newChannels = result['channels'] as List<IPTVChannel>;
          _allChannels.addAll(newChannels);

          // Update categorized channels
          for (final channel in newChannels) {
            final contentType = channel.contentType ?? 'unknown';
            if (!_channelsByType.containsKey(contentType)) {
              _channelsByType[contentType] = [];
            }
            _channelsByType[contentType]!.add(channel);
          }

          notifyListeners();
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error adding playlist: $e');
      return {'success': false, 'errorMessage': 'Error adding playlist: $e'};
    }
  }

  // Check if a channel is in favorites
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
