import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_project_name/models/iptv_channel.dart';
import 'package:my_project_name/models/iptv_playlist.dart';
import 'package:my_project_name/services/database_service.dart';

class PlaylistService {
  // Parse and fetch channels from an M3U URL
  static Future<List<IPTVChannel>> channelsFromM3uUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final playlistContent = response.body;
        return _parseM3u(playlistContent);
      } else {
        throw Exception('Failed to load playlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Error parsing M3U playlist: $e');
      return [];
    }
  }

  // Custom M3U parser
  static List<IPTVChannel> _parseM3u(String content) {
    final List<IPTVChannel> channels = [];
    int id = 1;
    
    // Split content into lines and filter out empty lines
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    // Check if it's a valid M3U file
    if (lines.isEmpty || !lines[0].trim().startsWith('#EXTM3U')) {
      throw Exception('Invalid M3U file format');
    }
    
    String? title;
    String? group;
    String? logo;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.startsWith('#EXTINF:')) {
        // Parse channel info
        title = _extractValue(line, 'tvg-name="', '"') ?? 
                _extractValue(line, 'title="', '"');
                
        group = _extractValue(line, 'group-title="', '"') ?? 
                _extractValue(line, 'group-name="', '"') ?? 
                'Uncategorized';
                
        logo = _extractValue(line, 'tvg-logo="', '"') ?? 
              _extractValue(line, 'logo="', '"');
        
        // If no name found in attributes, try to parse the name at the end of the #EXTINF line
        if (title == null) {
          final commaIndex = line.lastIndexOf(',');
          if (commaIndex != -1 && commaIndex < line.length - 1) {
            title = line.substring(commaIndex + 1).trim();
          }
        }
        
        // Check next line for URL
        if (i + 1 < lines.length && !lines[i + 1].startsWith('#')) {
          final url = lines[i + 1].trim();
          
          channels.add(
            IPTVChannel(
              id: id++,
              name: title ?? 'Unknown Channel ${id}',
              url: url,
              group: group ?? 'Uncategorized',
              logo: logo,
            ),
          );
          
          // Reset values
          title = null;
          group = null;
          logo = null;
        }
      }
    }
    
    return channels;
  }

  // Helper method to extract attribute values
  static String? _extractValue(String source, String startPattern, String endPattern) {
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

  // Parse and fetch channels from an Xtream API
  static Future<List<IPTVChannel>> channelsFromXtreamUrl(
    String url,
    String username,
    String password,
  ) async {
    try {
      // Format Xtream API URL properly
      final Uri uri = Uri.parse(url);
      final baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';

      // Get available categories
      final categoriesUrl =
          '$baseUrl/player_api.php?username=$username&password=$password&action=get_live_categories';

      final categoriesResponse = await http.get(Uri.parse(categoriesUrl));

      if (categoriesResponse.statusCode != 200) {
        throw Exception('Failed to load Xtream categories');
      }

      final categories = json.decode(categoriesResponse.body);
      final channels = <IPTVChannel>[];
      int id = 1;

      // Iterate through each category to get its streams
      for (final category in categories) {
        final categoryId = category['category_id'];
        final categoryName = category['category_name'];

        final streamsUrl =
            '$baseUrl/player_api.php?username=$username&password=$password&action=get_live_streams&category_id=$categoryId';

        final streamsResponse = await http.get(Uri.parse(streamsUrl));

        if (streamsResponse.statusCode == 200) {
          final streams = json.decode(streamsResponse.body);

          for (final stream in streams) {
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
              ),
            );
          }
        }
      }

      return channels;
    } catch (e) {
      print('Error fetching Xtream playlist: $e');
      return [];
    }
  }

  // Determine if a URL is an Xtream API or M3U URL
  static bool isXtreamUrl(String url) {
    final lowercaseUrl = url.toLowerCase();
    return lowercaseUrl.contains('username=') &&
        lowercaseUrl.contains('password=');
  }

  // Generic method to fetch channels from any kind of URL
  static Future<List<IPTVChannel>> getChannelsFromUrl(String url) async {
    if (isXtreamUrl(url)) {
      // Extract username and password from URL
      final uri = Uri.parse(url);
      final username = uri.queryParameters['username'];
      final password = uri.queryParameters['password'];

      if (username != null && password != null) {
        return channelsFromXtreamUrl(url, username, password);
      }
    }

    // Default to M3U parsing if not Xtream or missing credentials
    return channelsFromM3uUrl(url);
  }

  // Add a playlist to database and return channels
  static Future<Map<String, dynamic>> addPlaylist(
    String name,
    String url,
  ) async {
    try {
      final channels = await getChannelsFromUrl(url);

      if (channels.isEmpty) {
        return {
          'success': false,
          'errorMessage': 'No channels found in the playlist',
        };
      }

      final playlist = IPTVPlaylist(
        name: name,
        url: url,
        numChannels: channels.length,
        type: isXtreamUrl(url) ? PlaylistType.xtream : PlaylistType.m3u,
      );

      final savedPlaylist = await DatabaseService.addPlaylist(playlist);

      return {'success': true, 'playlist': savedPlaylist, 'channels': channels};
    } catch (e) {
      return {'success': false, 'errorMessage': 'Error adding playlist: $e'};
    }
  }

  // Get channels from a saved playlist
  static Future<List<IPTVChannel>> getChannelsFromPlaylist(
    IPTVPlaylist playlist,
  ) async {
    return getChannelsFromUrl(playlist.url);
  }
}
