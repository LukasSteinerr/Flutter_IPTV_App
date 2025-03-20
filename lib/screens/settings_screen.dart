import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/iptv_playlist.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/services/playlist_service.dart';
import 'package:my_project_name/services/playlist_data_provider.dart';
import 'package:my_project_name/widgets/shimmer_loading.dart';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<IPTVPlaylist> _playlists = [];
  bool _isLoading = true;
  bool _isXtream = false; // Track playlist type
  final TextEditingController _playlistNameController = TextEditingController();
  final TextEditingController _playlistUrlController = TextEditingController();
  // Additional controllers for Xtream
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isAddingPlaylist = false;
  double _loadingProgress = 0.0;
  StreamSubscription<double>? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _playlistNameController.dispose();
    _playlistUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
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
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Playlist type toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('M3U'),
                          Switch(
                            value: _isXtream,
                            onChanged: (value) {
                              setState(() {
                                _isXtream = value;
                              });
                            },
                            activeColor: AppColors.netflixRed,
                          ),
                          const Text('Xtream'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Playlist name field
                      TextField(
                        controller: _playlistNameController,
                        decoration: const InputDecoration(
                          labelText: 'Playlist Name',
                          hintText: 'Enter a name for this playlist',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // URL field
                      TextField(
                        controller: _playlistUrlController,
                        decoration: InputDecoration(
                          labelText: _isXtream ? 'Server URL' : 'M3U URL',
                          hintText:
                              _isXtream
                                  ? 'Enter server URL (e.g., http://example.com:port)'
                                  : 'Enter M3U playlist URL',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      // Xtream-specific fields
                      if (_isXtream) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            hintText: 'Enter Xtream username',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter Xtream password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _clearFields();
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = _playlistNameController.text.trim();
                  final url = _playlistUrlController.text.trim();

                  if (name.isEmpty ||
                      url.isEmpty ||
                      (_isXtream &&
                          (_usernameController.text.isEmpty ||
                              _passwordController.text.isEmpty))) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all required fields'),
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).pop();

                  // Construct the final URL
                  String finalUrl;
                  if (_isXtream) {
                    // Format: http://host:port/username/password
                    // Ensure the URL doesn't end with a slash
                    String baseUrl = url;
                    if (baseUrl.endsWith('/')) {
                      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
                    }
                    
                    final username = _usernameController.text.trim();
                    final password = _passwordController.text.trim();
                    
                    // This is the preferred format for Xtream URLs in our updated service
                    finalUrl = '$baseUrl/$username/$password';
                    debugPrint('Created Xtream URL: $finalUrl');
                  } else {
                    finalUrl = url;
                  }

                  await _addPlaylist(name, finalUrl);
                  _clearFields();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.netflixRed,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _clearFields() {
    _playlistNameController.clear();
    _playlistUrlController.clear();
    _usernameController.clear();
    _passwordController.clear();
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

  Future<void> _addPlaylist(String name, String url) async {
    try {
      setState(() {
        _isAddingPlaylist = true;
        _loadingProgress = 0;
      });

      // Subscribe to progress updates
      _progressSubscription = PlaylistService.progressStream.listen((progress) {
        if (mounted) {
          setState(() {
            _loadingProgress = progress;
          });
        }
      });

      // Store context before the async gap
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      debugPrint('Adding playlist - Name: $name, URL: $url');

      final dataProvider = Provider.of<PlaylistDataProvider>(
        context,
        listen: false,
      );

      debugPrint('Calling PlaylistDataProvider.addPlaylist');
      final result = await dataProvider.addPlaylist(name, url);
      debugPrint('Add playlist result: $result');

      if (!mounted) return;

      setState(() {
        _isAddingPlaylist = false;
      });
      _progressSubscription?.cancel();
      _progressSubscription = null;

      if (mounted) {
        if (result['success']) {
          await _loadPlaylists();
          if (!mounted) return;

          debugPrint('Playlist added successfully, reloading playlists...');
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    'Playlist "${result['playlist'].name}" added successfully',
              ),
            ),
          );
        } else {
          debugPrint('Failed to add playlist: ${result['errorMessage']}');
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(result['errorMessage'] ?? 'Error adding playlist'),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error adding playlist: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isAddingPlaylist = false;
      });
      _progressSubscription?.cancel();
      _progressSubscription = null;

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding playlist: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: AppColors.netflixBlack,
          ),
          body:
              _isLoading
                  ? const Center(
                    child: ShimmerContainer(
                      width: 50,
                      height: 50,
                      borderRadius: 25,
                    ),
                  )
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
        ),
        if (_isAddingPlaylist)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: _loadingProgress / 100,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.netflixRed,
                      ),
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading playlist... ${_loadingProgress.toInt()}%',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
