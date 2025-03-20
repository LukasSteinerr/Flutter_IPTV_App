import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:my_project_name/models/iptv_channel.dart';
import 'package:my_project_name/models/iptv_playlist.dart';
import 'package:my_project_name/services/database_service.dart';
import '../utils/xtream_debug.dart';

class PlaylistService {
  static final StreamController<double> _progressController =
      StreamController<double>.broadcast();
  static Stream<double> get progressStream => _progressController.stream;
  
  // Cache for API responses to prevent repeated network calls
  static final Map<String, dynamic> _apiResponseCache = {};
  static final Map<String, List<IPTVChannel>> _channelCache = {};
  static const int _cacheDurationMinutes = 30; // Cache duration
  static final Map<String, DateTime> _cacheTimestamps = {};

  // Parse and fetch channels from an M3U URL
  static Future<List<IPTVChannel>> channelsFromM3uUrl(String url) async {
    try {
      // Check cache first
      final cacheKey = 'M3U:$url';
      if (_channelCache.containsKey(cacheKey)) {
        final timestamp = _cacheTimestamps[cacheKey];
        if (timestamp != null && 
            DateTime.now().difference(timestamp).inMinutes < _cacheDurationMinutes) {
          debugPrint('Using cached M3U data for $url');
          return _channelCache[cacheKey]!;
        }
      }
      
      // Set a timeout for HTTP requests
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final playlistContent = response.body;
        final channels = _parseM3u(playlistContent);
        
        // Cache the result
        _channelCache[cacheKey] = channels;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return channels;
      } else {
        throw Exception('Failed to load playlist: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error parsing M3U playlist: $e');
      return [];
    }
  }

  // Custom M3U parser
  static List<IPTVChannel> _parseM3u(String content) {
    final List<IPTVChannel> channels = [];
    int id = 1;

    // Split content into lines and filter out empty lines
    final lines =
        content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    if (lines.isEmpty) {
      debugPrint('Empty M3U content');
      return [];
    }

    // Try to find #EXTM3U anywhere in the first few lines
    bool foundHeader = false;
    for (int i = 0; i < math.min(5, lines.length); i++) {
      if (lines[i].trim().startsWith('#EXTM3U')) {
        foundHeader = true;
        break;
      }
    }

    if (!foundHeader) {
      debugPrint('Warning: M3U header not found, attempting to parse anyway');
    }

    String title = '';
    String group = 'Uncategorized';
    String? logo;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('#EXTINF:')) {
        // Parse channel info
        title =
            _extractValue(line, 'tvg-name="', '"') ??
            _extractValue(line, 'title="', '"') ??
            '';

        String extractedGroup =
            _extractValue(line, 'group-title="', '"') ??
            _extractValue(line, 'group-name="', '"') ??
            'Uncategorized';
        group = extractedGroup.isEmpty ? 'Uncategorized' : extractedGroup;

        logo =
            _extractValue(line, 'tvg-logo="', '"') ??
            _extractValue(line, 'logo="', '"');

        // If no name found in attributes, try to parse the name at the end of the #EXTINF line
        if (title.isEmpty) {
          final commaIndex = line.lastIndexOf(',');
          if (commaIndex != -1 && commaIndex < line.length - 1) {
            title = line.substring(commaIndex + 1).trim();
          }
        }

        // Check next line for URL
        if (i + 1 < lines.length && !lines[i + 1].startsWith('#')) {
          final url = lines[i + 1].trim();

          // Determine content type based on group name
          final contentType = determineContentType(group);

          if (title.isNotEmpty && url.isNotEmpty) {
            channels.add(
              IPTVChannel(
                id: id++,
                name: title,
                url: url,
                group: group,
                logo: logo,
                contentType: contentType,
              ),
            );
          }

          // Reset values for next iteration
          title = '';
          group = 'Uncategorized';
          logo = null;
        }
      }
    }

    return channels;
  }

  // Helper method to extract attribute values
  static String? _extractValue(
    String source,
    String startPattern,
    String endPattern,
  ) {
    final startIndex = source.indexOf(startPattern);
    if (startIndex != -1) {
      final valueStartIndex = startIndex + startPattern.length;
      final endIndex = source.indexOf(endPattern, valueStartIndex);
      if (endIndex != -1) {
        return source.substring(valueStartIndex, endIndex);
      }
    }
    return null;
  }

  // Extract username and password from Xtream URL
  static Map<String, String?> _extractXtreamCredentials(String url) {
    // Try to parse the URL
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (e) {
      debugPrint('Invalid URL format: $e');
      return {'username': null, 'password': null, 'baseUrl': null};
    }
    
    // Check if credentials are in query parameters (player_api.php URL format)
    if (uri.queryParameters.containsKey('username') && 
        uri.queryParameters.containsKey('password')) {
      return {
        'username': uri.queryParameters['username'],
        'password': uri.queryParameters['password'],
        'baseUrl': '${uri.scheme}://${uri.host}:${uri.port}'
      };
    }
    
    // Check if credentials are in the path (URL format: http://host:port/username/password)
    final pathSegments = uri.pathSegments;
    if (pathSegments.length >= 2 && 
        pathSegments[0].isNotEmpty && 
        pathSegments[1].isNotEmpty) {
      return {
        'username': pathSegments[0],
        'password': pathSegments[1],
        'baseUrl': '${uri.scheme}://${uri.host}:${uri.port}'
      };
    }
    
    // No credentials found
    return {'username': null, 'password': null, 'baseUrl': null};
  }

  // Helper method to make API requests with caching
  static Future<dynamic> _makeXtreamRequest(String url) async {
    // Check cache first
    if (_apiResponseCache.containsKey(url)) {
      final timestamp = _cacheTimestamps[url];
      if (timestamp != null && 
          DateTime.now().difference(timestamp).inMinutes < _cacheDurationMinutes) {
        debugPrint('Using cached response for $url');
        return _apiResponseCache[url];
      }
    }
    
    try {
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
          
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Cache the result
        _apiResponseCache[url] = data;
        _cacheTimestamps[url] = DateTime.now();
        return data;
      } else {
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error making Xtream API request to $url: $e');
      rethrow;
    }
  }

  // Parse and fetch channels from an Xtream API with optimized concurrent requests
  static Future<List<IPTVChannel>> channelsFromXtreamUrl(
    String url,
    String username,
    String password,
  ) async {
    final cacheKey = 'XTREAM:$url';
    if (_channelCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && 
          DateTime.now().difference(timestamp).inMinutes < _cacheDurationMinutes) {
        debugPrint('Using cached Xtream channel data for $url');
        return _channelCache[cacheKey]!;
      }
    }

    try {
      debugPrint('Fetching Xtream playlist with URL: $url');
      
      // Format Xtream API URL properly
      final Uri uri = Uri.parse(url);
      final baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';
      
      debugPrint('Base URL: $baseUrl, Username: $username, Password: [HIDDEN]');

      final channels = <IPTVChannel>[];
      int id = 1;
      
      // Create URLs for all content types
      final liveCategoriesUrl = '$baseUrl/player_api.php?username=$username&password=$password&action=get_live_categories';
      final vodCategoriesUrl = '$baseUrl/player_api.php?username=$username&password=$password&action=get_vod_categories';
      final seriesCategoriesUrl = '$baseUrl/player_api.php?username=$username&password=$password&action=get_series_categories';
      
      // Fetch all category types in parallel
      final results = await Future.wait([
        _makeXtreamRequest(liveCategoriesUrl).catchError((e) {
          debugPrint('Error fetching live categories: $e');
          return <dynamic>[];
        }),
        _makeXtreamRequest(vodCategoriesUrl).catchError((e) {
          debugPrint('Error fetching VOD categories: $e');
          return <dynamic>[];
        }),
        _makeXtreamRequest(seriesCategoriesUrl).catchError((e) {
          debugPrint('Error fetching series categories: $e');
          return <dynamic>[];
        }),
      ]);
      
      final liveCategories = results[0] as List<dynamic>;
      final vodCategories = results[1] as List<dynamic>;
      final seriesCategories = results[2] as List<dynamic>;
      
      debugPrint('Found: ${liveCategories.length} live categories, ${vodCategories.length} VOD categories, ${seriesCategories.length} series categories');
      
      // Process each content type concurrently
      await Future.wait([
        // Process Live TV
        _processLiveCategories(baseUrl, username, password, liveCategories, channels, id),
        
        // Process VOD Movies 
        _processVodCategories(baseUrl, username, password, vodCategories, channels, id + 10000),
        
        // Process Series
        _processSeriesCategories(baseUrl, username, password, seriesCategories, channels, id + 20000),
      ]);

      // Cache the results
      _channelCache[cacheKey] = channels;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      debugPrint('Total Xtream channels/content loaded: ${channels.length}');
      debugPrint('Live TV: ${channels.where((c) => c.contentType == 'live').length}');
      debugPrint('Movies: ${channels.where((c) => c.contentType == 'movie').length}');
      debugPrint('TV Shows: ${channels.where((c) => c.contentType == 'tv_show').length}');
      
      return channels;
    } catch (e) {
      debugPrint('Error fetching Xtream playlist: $e');
      return [];
    }
  }
  
  // Helper method to process Live TV categories and streams
  static Future<void> _processLiveCategories(
    String baseUrl, 
    String username, 
    String password,
    List<dynamic> categories,
    List<IPTVChannel> channels,
    int startId
  ) async {
    int id = startId;
    
    // For Live TV, process each category in parallel
    final futures = <Future>[];
    for (final category in categories) {
      final categoryId = category['category_id'];
      final categoryName = category['category_name'];
      
      final streamsUrl = '$baseUrl/player_api.php?username=$username&password=$password&action=get_live_streams&category_id=$categoryId';
      
      futures.add(
        _makeXtreamRequest(streamsUrl).then((streams) {
          final categoryStreams = streams as List<dynamic>;
          for (final stream in categoryStreams) {
            final streamName = stream['name'];
            final streamId = stream['stream_id'];
            final streamIcon = stream['stream_icon'];
            final streamUrl = '$baseUrl/live/$username/$password/$streamId.ts';
            
            channels.add(
              IPTVChannel(
                id: id++,
                name: streamName,
                url: streamUrl,
                group: categoryName,
                logo: streamIcon,
                contentType: 'live',
              ),
            );
          }
        }).catchError((e) {
          debugPrint('Error processing live TV category $categoryName: $e');
        })
      );
    }
    
    await Future.wait(futures);
  }
  
  // Helper method to process VOD categories and streams
  static Future<void> _processVodCategories(
    String baseUrl, 
    String username, 
    String password,
    List<dynamic> categories,
    List<IPTVChannel> channels,
    int startId
  ) async {
    int id = startId;
    
    // For VOD, process each category in parallel
    final futures = <Future>[];
    for (final category in categories) {
      final categoryId = category['category_id'];
      final categoryName = category['category_name'];
      
      final streamsUrl = '$baseUrl/player_api.php?username=$username&password=$password&action=get_vod_streams&category_id=$categoryId';
      
      futures.add(
        _makeXtreamRequest(streamsUrl).then((streams) {
          final categoryStreams = streams as List<dynamic>;
          for (final stream in categoryStreams) {
            final streamName = stream['name'];
            final streamId = stream['stream_id'];
            final streamIcon = stream['stream_icon'];
            final streamUrl = '$baseUrl/movie/$username/$password/$streamId.mp4';
            
            channels.add(
              IPTVChannel(
                id: id++,
                name: streamName,
                url: streamUrl,
                group: categoryName,
                logo: streamIcon,
                contentType: 'movie',
              ),
            );
          }
        }).catchError((e) {
          debugPrint('Error processing VOD category $categoryName: $e');
        })
      );
    }
    
    await Future.wait(futures);
  }
  
  // Helper method to process Series categories and streams
  static Future<void> _processSeriesCategories(
    String baseUrl, 
    String username, 
    String password,
    List<dynamic> categories,
    List<IPTVChannel> channels,
    int startId
  ) async {
    int id = startId;
    
    // For Series, process each category in parallel
    final futures = <Future>[];
    for (final category in categories) {
      final categoryId = category['category_id'];
      final categoryName = category['category_name'];
      
      final seriesUrl = '$baseUrl/player_api.php?username=$username&password=$password&action=get_series&category_id=$categoryId';
      
      futures.add(
        _makeXtreamRequest(seriesUrl).then((allSeries) {
          final seriesList = allSeries as List<dynamic>;
          for (final series in seriesList) {
            final seriesName = series['name'] ?? 'Unknown Series';
            final seriesId = series['series_id'];
            final seriesIcon = series['cover'] ?? series['poster'] ?? '';
            
            // For efficiency, create a direct playable URL where possible
            // This info URL will be processed on-demand when the series is selected
            final infoUrl = '$baseUrl/player_api.php?username=$username&password=$password&action=get_series_info&series_id=$seriesId';
            
            channels.add(
              IPTVChannel(
                id: id++,
                name: seriesName,
                url: infoUrl,
                group: categoryName,
                logo: seriesIcon,
                contentType: 'tv_show',
              ),
            );
          }
        }).catchError((e) {
          debugPrint('Error processing series category $categoryName: $e');
        })
      );
    }
    
    await Future.wait(futures);
  }

  // Determine if a URL is an Xtream API or M3U URL
  static bool isXtreamUrl(String url) {
    final lowercaseUrl = url.toLowerCase();
    
    // Check for common Xtream indicators
    // 1. Contains player_api.php with username and password params
    if (lowercaseUrl.contains('player_api.php') && 
        lowercaseUrl.contains('username=') && 
        lowercaseUrl.contains('password=')) {
      return true;
    }
    
    // 2. URL matches format: http://host:port/username/password/
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.length >= 2) {
        return true;
      }
    } catch (e) {
      // Ignore parsing errors
    }
    
    return false;
  }

  // Clear all caches
  static void clearCache() {
    _apiResponseCache.clear();
    _channelCache.clear();
    _cacheTimestamps.clear();
    debugPrint('Playlist service cache cleared');
  }

  // Generic method to fetch channels from any kind of URL
  static Future<List<IPTVChannel>> getChannelsFromUrl(String url) async {
    debugPrint('Getting channels from URL: $url');
    
    if (isXtreamUrl(url)) {
      debugPrint('Detected Xtream URL format');
      
      // Extract credentials from the URL
      final credentials = _extractXtreamCredentials(url);
      final username = credentials['username'];
      final password = credentials['password'];
      
      if (username != null && password != null) {
        debugPrint('Extracted credentials - Username: $username, Password: [HIDDEN]');
        return channelsFromXtreamUrl(url, username, password);
      } else {
        debugPrint('Could not extract Xtream credentials from URL');
      }
    } else {
      debugPrint('Detected M3U URL format');
    }

    // Default to M3U parsing if not Xtream or missing credentials
    return channelsFromM3uUrl(url);
  }

  // Add a playlist to database and return channels with improved progress reporting
  static Future<Map<String, dynamic>> addPlaylist(
    String name,
    String url,
  ) async {
    try {
      _progressController.add(0.0); // Start progress
      debugPrint('Adding playlist - Name: $name, URL: $url');

      // Save playlist to database
      _progressController.add(10.0);
      final playlist = IPTVPlaylist(
        name: name,
        url: url,
        numChannels: 0, // We'll update this later
        type: isXtreamUrl(url) ? PlaylistType.xtream : PlaylistType.m3u,
      );

      final savedPlaylist = await DatabaseService.addPlaylist(playlist);
      debugPrint('Playlist saved to database with ID: ${savedPlaylist.id}');

      // Then try to fetch channels with improved progress reporting
      try {
        _progressController.add(20.0);
        
        // Start a timer to update progress periodically during fetch
        // This provides feedback while waiting for the API responses
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
          if (timer.tick < 40) { // Cap at 40 ticks (20 seconds)
            // Progress from 20% to 50% during fetch
            _progressController.add(20.0 + (timer.tick * 0.75));
          } else {
            timer.cancel();
          }
        });
        
        final channels = await getChannelsFromUrl(url);
        debugPrint('Retrieved ${channels.length} channels from URL');
        
        _progressController.add(50.0);  // Channels retrieved

        // Save channels to database with proper progress reporting
        if (channels.isNotEmpty) {
          int totalChannels = channels.length;
          for (int i = 0; i < channels.length; i++) {
            await DatabaseService.addChannel(channels[i], savedPlaylist.id!);
            // Update progress from 50% to 95% based on channel processing
            _progressController.add(50.0 + (45.0 * (i + 1) / totalChannels));
          }

          // Update the playlist with the correct channel count
          final updatedPlaylist = IPTVPlaylist(
            id: savedPlaylist.id,
            name: name,
            url: url,
            numChannels: channels.length,
            type: savedPlaylist.type,
          );

          await DatabaseService.addPlaylist(updatedPlaylist);
          debugPrint('Updated playlist with channel count: ${channels.length}');
        }

        _progressController.add(100.0); // Complete

        return {
          'success': true,
          'playlist': savedPlaylist,
          'channels': channels,
          'message':
              channels.isEmpty ? 'Playlist added but no channels found' : null,
        };
      } catch (channelError) {
        debugPrint('Error fetching channels: $channelError');
        _progressController.add(0.0); // Reset progress on error
        return {
          'success': true,
          'playlist': savedPlaylist,
          'channels': <IPTVChannel>[],
          'message':
              'Playlist added but there was an error loading channels: $channelError',
        };
      }
    } catch (e) {
      debugPrint('Error adding playlist: $e');
      _progressController.add(0.0); // Reset progress on error
      return {'success': false, 'errorMessage': 'Error adding playlist: $e'};
    }
  }

  // Get channels from a saved playlist with caching
  static Future<List<IPTVChannel>> getChannelsFromPlaylist(
    IPTVPlaylist playlist,
  ) async {
    final cacheKey = 'PLAYLIST:${playlist.id}';
    if (_channelCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && 
          DateTime.now().difference(timestamp).inMinutes < _cacheDurationMinutes) {
        debugPrint('Using cached playlist channel data for ${playlist.name}');
        return _channelCache[cacheKey]!;
      }
    }
    
    final channels = await getChannelsFromUrl(playlist.url);
    
    // Cache the result
    _channelCache[cacheKey] = channels;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    return channels;
  }

  // Get channels by content type
  static Future<List<IPTVChannel>> getChannelsByContentType(
    List<IPTVChannel> channels,
    String contentType,
  ) async {
    return channels.where((channel) {
      if (channel.contentType == contentType) {
        return true;
      }
      if (channel.contentType == null &&
          determineContentType(channel.group) == contentType) {
        return true;
      }
      return false;
    }).toList();
  }

  // Helper to determine content type from group name
  static String determineContentType(String group) {
    final groupLower = group.toLowerCase();

    if (groupLower.contains('movie') ||
        groupLower.contains('film') ||
        groupLower.contains('cinema') ||
        groupLower.contains('vod')) {
      return 'movie';
    }

    if (groupLower.contains('series') ||
        groupLower.contains('show') ||
        groupLower.contains('drama') ||
        groupLower.contains('episode')) {
      return 'tv_show';
    }

    if (groupLower.contains('live') ||
        groupLower.contains('tv') ||
        groupLower.contains('channel') ||
        groupLower.contains('news') ||
        groupLower.contains('sport') ||
        groupLower.contains('radio')) {
      return 'live';
    }

    return 'unknown';
  }

  // Inside the method that adds Xtream playlist
  Future<bool> addXtreamPlaylist(
    String name,
    String username,
    String password,
    String url,
  ) async {
    // ...existing code...

    // Add this debugging call before returning success
    final isConnectionValid = await XtreamDebugger.testXtreamConnection(
      username,
      password,
      url,
    );

    if (!isConnectionValid) {
      debugPrint(
        "Playlist added but connection test failed. Check logs for details.",
      );
    }

    return isConnectionValid; // Return the connection test result
  }
}
