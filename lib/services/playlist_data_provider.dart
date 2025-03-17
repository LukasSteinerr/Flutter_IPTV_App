import 'package:flutter/foundation.dart';
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
      notifyListeners();
      
      // Load playlists from database
      _loadingMessage = 'Loading playlists...';
      notifyListeners();
      
      _playlists = await DatabaseService.getPlaylists();
      
      // Load favorite channels
      _loadingMessage = 'Loading favorites...';
      notifyListeners();
      
      _favoriteChannels = await DatabaseService.getFavorites();
      
      // Load channels from each playlist
      _allChannels = [];
      
      if (_playlists.isNotEmpty) {
        for (final playlist in _playlists) {
          _loadingMessage = 'Loading channels from ${playlist.name}...';
          notifyListeners();
          
          try {
            final channels = await PlaylistService.getChannelsFromPlaylist(playlist);
            _allChannels.addAll(channels);
          } catch (e) {
            print('Error loading channels from playlist ${playlist.name}: $e');
          }
        }
      }
      
      // Categorize channels by type
      _loadingMessage = 'Organizing content...';
      notifyListeners();
      
      _channelsByType = {};
      _channelsByType['movie'] = [];
      _channelsByType['tv_show'] = [];
      _channelsByType['live'] = [];
      
      for (final channel in _allChannels) {
        final contentType = channel.contentType ?? 'unknown';
        if (!_channelsByType.containsKey(contentType)) {
          _channelsByType[contentType] = [];
        }
        _channelsByType[contentType]!.add(channel);
      }
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error loading data: $e';
      print('Error initializing data: $e');
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
      print('Error refreshing playlists: $e');
    }
  }
  
  Future<void> refreshFavorites() async {
    try {
      _favoriteChannels = await DatabaseService.getFavorites();
      notifyListeners();
    } catch (e) {
      print('Error refreshing favorites: $e');
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
      print('Error adding playlist: $e');
      return {
        'success': false,
        'errorMessage': 'Error adding playlist: $e',
      };
    }
  }
  
  // Check if a channel is in favorites
  Future<bool> toggleFavorite(IPTVChannel channel) async {
    try {
      // Check if it's already a favorite
      bool isFav = await DatabaseService.isFavorite(channel.url);
      
      if (isFav) {
        // Find the favorite channel ID
        IPTVChannel? favChannel = _favoriteChannels
            .firstWhere((c) => c.url == channel.url, orElse: () => channel);
            
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
      print('Error toggling favorite: $e');
      return false;
    }
  }
}