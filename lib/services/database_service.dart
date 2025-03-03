import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:my_project_name/models/iptv_channel.dart';
import 'package:my_project_name/models/iptv_playlist.dart';

class DatabaseService {
  static const String dbName = 'iptv_app.db';
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create playlists table
        await db.execute('''
          CREATE TABLE playlists(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            url TEXT,
            numChannels INTEGER,
            type TEXT
          )
        ''');

        // Create favorites table
        await db.execute('''
          CREATE TABLE favorites(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            url TEXT,
            group_name TEXT,
            logo TEXT
          )
        ''');
      },
    );
  }

  // Playlist methods
  static Future<List<IPTVPlaylist>> getPlaylists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('playlists');
    return List.generate(maps.length, (i) => IPTVPlaylist.fromMap(maps[i]));
  }

  static Future<IPTVPlaylist> addPlaylist(IPTVPlaylist playlist) async {
    final db = await database;
    
    // Check if a playlist with the same URL already exists
    final List<Map<String, dynamic>> existingPlaylists = await db.query(
      'playlists',
      where: 'url = ?',
      whereArgs: [playlist.url],
    );
    
    if (existingPlaylists.isNotEmpty) {
      // Update existing playlist
      final existingPlaylist = IPTVPlaylist.fromMap(existingPlaylists.first);
      final updatedPlaylist = IPTVPlaylist(
        id: existingPlaylist.id,
        name: playlist.name,
        url: playlist.url,
        numChannels: playlist.numChannels,
        type: playlist.type,
      );
      
      await db.update(
        'playlists',
        updatedPlaylist.toMap(),
        where: 'id = ?',
        whereArgs: [existingPlaylist.id],
      );
      
      return updatedPlaylist;
    } else {
      // Insert new playlist
      final id = await db.insert('playlists', playlist.toMap());
      return IPTVPlaylist(
        id: id,
        name: playlist.name,
        url: playlist.url,
        numChannels: playlist.numChannels,
        type: playlist.type,
      );
    }
  }

  static Future<bool> deletePlaylist(int id) async {
    final db = await database;
    final deletedCount = await db.delete(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
    );
    return deletedCount > 0;
  }

  // Favorites methods
  static Future<List<IPTVChannel>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    
    return List.generate(maps.length, (i) {
      return IPTVChannel(
        id: maps[i]['id'],
        name: maps[i]['name'],
        url: maps[i]['url'],
        group: maps[i]['group_name'],
        logo: maps[i]['logo'],
      );
    });
  }

  static Future<IPTVChannel> addFavorite(IPTVChannel channel) async {
    final db = await database;
    
    // Check if the channel is already a favorite
    final List<Map<String, dynamic>> existingChannels = await db.query(
      'favorites',
      where: 'url = ?',
      whereArgs: [channel.url],
    );
    
    if (existingChannels.isNotEmpty) {
      // Already a favorite, just return it
      return IPTVChannel(
        id: existingChannels.first['id'],
        name: existingChannels.first['name'],
        url: existingChannels.first['url'],
        group: existingChannels.first['group_name'],
        logo: existingChannels.first['logo'],
      );
    } else {
      // Add as new favorite
      final map = {
        'name': channel.name,
        'url': channel.url,
        'group_name': channel.group,
        'logo': channel.logo,
      };
      
      final id = await db.insert('favorites', map);
      return IPTVChannel(
        id: id,
        name: channel.name,
        url: channel.url,
        group: channel.group,
        logo: channel.logo,
      );
    }
  }

  static Future<bool> removeFavorite(int id) async {
    final db = await database;
    final deletedCount = await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
    return deletedCount > 0;
  }

  // Check if a channel URL is in favorites
  static Future<bool> isFavorite(String url) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'favorites',
      where: 'url = ?',
      whereArgs: [url],
    );
    return result.isNotEmpty;
  }
}
