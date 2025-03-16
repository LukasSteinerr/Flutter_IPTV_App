import 'package:flutter/material.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/iptv_playlist.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/services/playlist_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<IPTVPlaylist> _playlists = [];
  bool _isLoading = true;
  final TextEditingController _playlistNameController = TextEditingController();
  final TextEditingController _playlistUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  @override
  void dispose() {
    _playlistNameController.dispose();
    _playlistUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final playlists = await DatabaseService.getPlaylists();

      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading playlists: $e')));
      }
    }
  }

  void _showAddPlaylistDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Playlist'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _playlistNameController,
                  decoration: const InputDecoration(
                    labelText: 'Playlist Name',
                    hintText: 'Enter a name for this playlist',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _playlistUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Playlist URL',
                    hintText: 'Enter M3U or Xtream URL',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _playlistNameController.clear();
                  _playlistUrlController.clear();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final name = _playlistNameController.text.trim();
                  final url = _playlistUrlController.text.trim();

                  if (name.isEmpty || url.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter both name and URL'),
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).pop();

                  // Show loading indicator
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Adding playlist... This may take a moment.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  try {
                    // Add the playlist using PlaylistService
                    final result = await PlaylistService.addPlaylist(name, url);

                    _playlistNameController.clear();
                    _playlistUrlController.clear();

                    // Refresh the playlist list
                    _loadPlaylists();

                    if (mounted) {
                      if (result['success']) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message'] ??
                                  'Playlist "${result['playlist'].name}" added successfully',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['errorMessage'] ?? 'Error adding playlist',
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding playlist: $e')),
                      );
                    }
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Future<void> _deletePlaylist(IPTVPlaylist playlist) async {
    try {
      final success = await DatabaseService.deletePlaylist(playlist.id!);
      if (success) {
        _loadPlaylists();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Playlist "${playlist.name}" deleted')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting playlist: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.netflixBlack,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  // Playlists section
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Playlists',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_playlists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No playlists added yet'),
                    )
                  else
                    ..._playlists.map(
                      (playlist) => ListTile(
                        title: Text(playlist.name),
                        subtitle: Text(
                          playlist.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deletePlaylist(playlist),
                        ),
                      ),
                    ),

                  // Add playlist button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _showAddPlaylistDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.netflixRed,
                        foregroundColor: AppColors.netflixWhite,
                      ),
                      child: const Text('Add Playlist'),
                    ),
                  ),

                  const Divider(),

                  // App info section
                  const ListTile(
                    title: Text('App Version'),
                    trailing: Text('1.0.0'),
                  ),

                  // About section
                  const ListTile(
                    title: Text('About'),
                    subtitle: Text('IPTV Streaming App'),
                  ),
                ],
              ),
    );
  }
}
