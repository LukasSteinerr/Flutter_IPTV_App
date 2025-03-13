import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_project_name/models/iptv_channel.dart';
import 'package:my_project_name/models/iptv_playlist.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/services/playlist_service.dart';

class Api {
  // Placeholder image URLs for missing thumbnails
  static const String defaultPosterUrl =
      'https://via.placeholder.com/500x750?text=No+Poster';
  static const String defaultBackdropUrl =
      'https://via.placeholder.com/1280x720?text=No+Image';

  // Cache of loaded channels to avoid repeated parsing
  static final final Map<int, List<IPTVChannel>> _channelCache = {};

  static Future<void> clearCache() async {
    _channelCache.clear();
  }

  // Get trending content (maps to channels from all playlists)
  static Future<List<dynamic>> getTrending() async {
    try {
      List<IPTVChannel> allChannels = [];
      final playlists = await DatabaseService.getPlaylists();

      for (var playlist in playlists) {
        if (_channelCache.containsKey(playlist.id)) {
          allChannels.addAll(_channelCache[playlist.id]!);
        } else {
          final channels = await PlaylistService.getChannelsFromPlaylist(
            playlist,
          );
          if (playlist.id != null) {
            _channelCache[playlist.id!] = channels;
          }
          allChannels.addAll(channels);
        }
      }

      // Convert to a format compatible with Movie model
      return allChannels
          .map(
            (channel) => {
              'id': channel.id,
              'title': channel.name,
              'overview': 'Channel from group: ${channel.group}',
              'poster_path': channel.logo,
              'backdrop_path': channel.logo,
              'vote_average': null,
              'release_date': null,
              'genre_ids': [channel.group],
              'media_type': _determineMediaType(channel),
              'url': channel.url,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading all channels: $e');
      return [];
    }
  }

  // Determine media type based on group/category
  static String _determineMediaType(IPTVChannel channel) {
    final group = channel.group.toLowerCase();
    if (group.contains('movie')) return 'movie';
    if (group.contains('serie') ||
        group.contains('show') ||
        group.contains('tv')) {
      return 'tv';
    }
    }
    return 'live'; // Default to live
  }

  // Get now playing - maps to live TV channels
  static Future<List<dynamic>> getNowPlaying() async {
    try {
      List<IPTVChannel> allChannels = [];
      final playlists = await DatabaseService.getPlaylists();

      for (var playlist in playlists) {
        List<IPTVChannel> channels;
        if (_channelCache.containsKey(playlist.id)) {
          channels = _channelCache[playlist.id]!;
        } else {
          channels = await PlaylistService.getChannelsFromPlaylist(playlist);
          if (playlist.id != null) {
            _channelCache[playlist.id!] = channels;
          }
        }

        // Filter for likely live TV channels
        final liveChannels =
            channels.where((channel) {
              final group = channel.group.toLowerCase();
              return !group.contains('movie') &&
                  !group.contains('serie') &&
                  !group.contains('show');
            }).toList();

        allChannels.addAll(liveChannels);
      }

      return allChannels
          .map(
            (channel) => {
              'id': channel.id,
              'title': channel.name,
              'overview': 'Live channel from group: ${channel.group}',
              'poster_path': channel.logo,
              'backdrop_path': channel.logo,
              'media_type': 'live',
              'url': channel.url,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading live channels: $e');
      return [];
    }
  }

  // Get popular - maps to movie channels
  static Future<List<dynamic>> getPopular() async {
    try {
      List<IPTVChannel> movieChannels = [];
      final playlists = await DatabaseService.getPlaylists();

      for (var playlist in playlists) {
        List<IPTVChannel> channels;
        if (_channelCache.containsKey(playlist.id)) {
          channels = _channelCache[playlist.id]!;
        } else {
          channels = await PlaylistService.getChannelsFromPlaylist(playlist);
          if (playlist.id != null) {
            _channelCache[playlist.id!] = channels;
          }
        }

        // Filter for movie channels
        final movies =
            channels.where((channel) {
              final group = channel.group.toLowerCase();
              return group.contains('movie');
            }).toList();

        movieChannels.addAll(movies);
      }

      return movieChannels
          .map(
            (channel) => {
              'id': channel.id,
              'title': channel.name,
              'overview': 'Movie from group: ${channel.group}',
              'poster_path': channel.logo,
              'backdrop_path': channel.logo,
              'media_type': 'movie',
              'url': channel.url,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading movies: $e');
      return [];
    }
  }

  // Get top rated - maps to favorite channels
  static Future<List<dynamic>> getTopRated() async {
    try {
      final favorites = await DatabaseService.getFavorites();

      return favorites
          .map(
            (channel) => {
              'id': channel.id,
              'title': channel.name,
              'overview': 'Favorite from group: ${channel.group}',
              'poster_path': channel.logo,
              'backdrop_path': channel.logo,
              'media_type': _determineMediaType(channel),
              'url': channel.url,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      return [];
    }
  }

  // Get upcoming - placeholder for recently added channels
  static Future<List<dynamic>> getUpcoming() async {
    try {
      List<IPTVChannel> allChannels = [];
      final playlists = await DatabaseService.getPlaylists();

      for (var playlist in playlists) {
        if (_channelCache.containsKey(playlist.id)) {
          allChannels.addAll(_channelCache[playlist.id]!);
        } else {
          final channels = await PlaylistService.getChannelsFromPlaylist(
            playlist,
          );
          if (playlist.id != null) {
            _channelCache[playlist.id!] = channels;
          }
          allChannels.addAll(channels);
        }
      }

      // Sort to get "recently added" feeling - in a real app this would track actual additions
      allChannels.sort((a, b) => a.name.compareTo(b.name));
      final recentlyAdded = allChannels.take(20).toList();

      return recentlyAdded
          .map(
            (channel) => {
              'id': channel.id,
              'title': channel.name,
              'overview': 'Channel from group: ${channel.group}',
              'poster_path': channel.logo,
              'backdrop_path': channel.logo,
              'release_date': DateTime.now().toString().substring(0, 10),
              'media_type': _determineMediaType(channel),
              'url': channel.url,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading upcoming: $e');
      return [];
    }
  }

  // Get TV shows - maps to TV series channels
  static Future<List<dynamic>> getPopularTv() async {
    try {
      List<IPTVChannel> seriesChannels = [];
      final playlists = await DatabaseService.getPlaylists();

      for (var playlist in playlists) {
        List<IPTVChannel> channels;
        if (_channelCache.containsKey(playlist.id)) {
          channels = _channelCache[playlist.id]!;
        } else {
          channels = await PlaylistService.getChannelsFromPlaylist(playlist);
          if (playlist.id != null) {
            _channelCache[playlist.id!] = channels;
          }
        }

        // Filter for TV series channels
        final series =
            channels.where((channel) {
              final group = channel.group.toLowerCase();
              return group.contains('serie') ||
                  group.contains('show') ||
                  (group.contains('tv') && !group.contains('live'));
            }).toList();

        seriesChannels.addAll(series);
      }

      return seriesChannels
          .map(
            (channel) => {
              'id': channel.id,
              'name': channel.name,
              'overview': 'TV Series from group: ${channel.group}',
              'poster_path': channel.logo,
              'backdrop_path': channel.logo,
              'media_type': 'tv',
              'url': channel.url,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading TV shows: $e');
      return [];
    }
  }

  // Search across all channels
  static Future<List<dynamic>> search(String query) async {
    try {
      final lowercaseQuery = query.toLowerCase();
      List<IPTVChannel> allChannels = [];
      final playlists = await DatabaseService.getPlaylists();

      for (var playlist in playlists) {
        if (_channelCache.containsKey(playlist.id)) {
          allChannels.addAll(_channelCache[playlist.id]!);
        } else {
          final channels = await PlaylistService.getChannelsFromPlaylist(
            playlist,
          );
          if (playlist.id != null) {
            _channelCache[playlist.id!] = channels;
          }
          allChannels.addAll(channels);
        }
      }

      // Filter by name or group
      final results =
          allChannels
              .where(
                (channel) =>
                    channel.name.toLowerCase().contains(lowercaseQuery) ||
                    channel.group.toLowerCase().contains(lowercaseQuery),
              )
              .toList();

      return results
          .map(
            (channel) => {
              'id': channel.id,
              'title': channel.name,
              'overview': 'Channel from group: ${channel.group}',
              'poster_path': channel.logo,
              'backdrop_path': channel.logo,
              'media_type': _determineMediaType(channel),
              'url': channel.url,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error searching: $e');
      return [];
    }
  }

  // Get details for a specific channel
  static Future<Map<String, dynamic>> getChannelDetails(
    IPTVChannel channel,
  ) async {
    final isFavorite = await DatabaseService.isFavorite(channel.url);

    return {
      'id': channel.id,
      'title': channel.name,
      'overview': 'Channel from group: ${channel.group}',
      'poster_path': channel.logo,
      'backdrop_path': channel.logo,
      'media_type': _determineMediaType(channel),
      'url': channel.url,
      'is_favorite': isFavorite,
    };
  }

  // Get movie details (adapts to work with our IPTV content)
  static Future<Map<String, dynamic>> getMovieDetails(int id) async {
    // Find the channel with this ID
    List<IPTVChannel> allChannels = [];
    final playlists = await DatabaseService.getPlaylists();

    for (var playlist in playlists) {
      if (_channelCache.containsKey(playlist.id)) {
        allChannels.addAll(_channelCache[playlist.id]!);
      } else {
        final channels = await PlaylistService.getChannelsFromPlaylist(
          playlist,
        );
        if (playlist.id != null) {
          _channelCache[playlist.id!] = channels;
        }
        allChannels.addAll(channels);
      }
    }

    final channel = allChannels.firstWhere(
      (c) => c.id == id,
      orElse:
          () => IPTVChannel(
            id: id,
            name: 'Unknown Channel',
            url: '',
            group: 'Unknown',
          ),
    );

    return await getChannelDetails(channel);
  }

  // Get TV show details (adapts to work with our IPTV content)
  static Future<Map<String, dynamic>> getTvDetails(int id) async {
    return getMovieDetails(id); // Reuse the same method
  }
}
