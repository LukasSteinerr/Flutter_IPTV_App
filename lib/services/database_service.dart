import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    // Initialize FFI only for desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final path = join(await getDatabasesPath(), dbName);
    return await openDatabase(
      path,
      version: 4,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS playlists(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            url TEXT,
            numChannels INTEGER,
            type TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS favorites(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            url TEXT,
            group_name TEXT,
            logo TEXT,
            content_type TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS channels(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            url TEXT,
            group_name TEXT,
            logo TEXT,
            content_type TEXT,
            playlist_id INTEGER,
            FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 4) {
          await db.execute('DROP TABLE IF EXISTS channels');
          await db.execute('''
            CREATE TABLE channels(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              url TEXT,
              group_name TEXT,
              logo TEXT,
              content_type TEXT,
              playlist_id INTEGER,
              FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE
            )
          ''');
        }
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
    final List<Map<String, dynamic>> existing = await db.query(
      'playlists',
      where: 'url = ?',
      whereArgs: [playlist.url],
    );

    if (existing.isNotEmpty) {
      final existingPlaylist = IPTVPlaylist.fromMap(existing.first);
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
      final id = await db.insert('playlists', playlist.toMap());
      return playlist.copyWith(id: id);
    }
  }

  static Future<bool> deletePlaylist(int id) async {
    final db = await database;
    final deleted = await db.delete(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
    );
    return deleted > 0;
  }

  // Favorite methods
  static Future<List<IPTVChannel>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return List.generate(maps.length, (i) => IPTVChannel.fromMap(maps[i]));
  }

  static Future<IPTVChannel> addFavorite(IPTVChannel channel) async {
    final db = await database;
    final List<Map<String, dynamic>> existing = await db.query(
      'favorites',
      where: 'url = ?',
      whereArgs: [channel.url],
    );

    if (existing.isNotEmpty) {
      return IPTVChannel.fromMap(existing.first);
    } else {
      final map = channel.toMap();
      // No need to convert 'group' to 'group_name' anymore
      final id = await db.insert('favorites', map);
      return channel.copyWith(id: id);
    }
  }

  static Future<bool> removeFavorite(int id) async {
    final db = await database;
    final deleted = await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
    return deleted > 0;
  }

  static Future<bool> isFavorite(String url) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'url = ?',
      whereArgs: [url],
    );
    return result.isNotEmpty;
  }

  // Channel methods
  static Future<void> addChannel(IPTVChannel channel, int playlistId) async {
    final db = await database;
    final map = channel.toMap();
    // No need to convert 'group' to 'group_name' anymore since toMap does it correctly
    map['playlist_id'] = playlistId;
    await db.insert(
      'channels',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
