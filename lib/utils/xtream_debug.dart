import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class XtreamDebugger {
  static Future<bool> testXtreamConnection(
    String username,
    String password,
    String url,
  ) async {
    try {
      final Uri uri = Uri.parse(url);
      final baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';

      final testUrl =
          '$baseUrl/player_api.php?username=$username&password=$password&action=get_live_categories';

      final response = await http.get(Uri.parse(testUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // A valid response should be an array, even if empty
        return data is List;
      }

      return false;
    } catch (e) {
      debugPrint('Xtream connection test failed: $e');
      return false;
    }
  }
}
