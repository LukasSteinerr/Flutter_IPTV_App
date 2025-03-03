import 'package:flutter/material.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/iptv_playlist.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/services/playlist_service.dart';
import 'package:my_project_name/services/api_service.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  List<IPTVPlaylist> _playlists = [];
  bool _isLoading = true;
  bool _isAddingPlaylist = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final playlists = await DatabaseService.getPlaylists();
      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading playlists: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addPlaylist() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();

    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both a name and URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAddingPlaylist = true;
    });

    try {
      final result = await PlaylistService.addPlaylist(name, url);

      if (result['success']) {
        // Clear form fields
        _nameController.clear();
        _urlController.clear();

        // Clear API cache to refresh content
        await Api.clearCache();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Playlist added with ${result['channels'].length} channels',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reload playlists
        await _loadPlaylists();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['errorMessage']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding playlist: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAddingPlaylist = false;
      });
    }
  }

  Future<void> _deletePlaylist(int id) async {
    try {
      final success = await DatabaseService.deletePlaylist(id);

      if (success) {
        // Clear API cache to refresh content
        await Api.clearCache();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playlist deleted'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload playlists
        await _loadPlaylists();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting playlist'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.netflixBlack,
        title: const Text('Manage Playlists'),
        actions: [IconButton(icon: const Icon(Icons.cast), onPressed: () {})],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.netflixRed),
              )
              : Column(
                children: [
                  // Form to add a new playlist
                  _buildAddPlaylistForm(),

                  const Divider(color: AppColors.netflixLightGrey),

                  // List of existing playlists
                  Expanded(
                    child:
                        _playlists.isEmpty
                            ? const Center(
                              child: Text(
                                'No playlists added yet',
                                style: TextStyle(
                                  color: AppColors.netflixLightGrey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                            : ListView.builder(
                              itemCount: _playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = _playlists[index];
                                return _buildPlaylistItem(playlist);
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildAddPlaylistForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Playlist',
            style: TextStyle(
              color: AppColors.netflixWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Playlist Name',
              labelStyle: TextStyle(color: AppColors.netflixLightGrey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.netflixLightGrey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.netflixRed),
              ),
            ),
            style: const TextStyle(color: AppColors.netflixWhite),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Playlist URL (M3U or Xtream)',
              labelStyle: TextStyle(color: AppColors.netflixLightGrey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.netflixLightGrey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.netflixRed),
              ),
            ),
            style: const TextStyle(color: AppColors.netflixWhite),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAddingPlaylist ? null : _addPlaylist,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.netflixRed,
                disabledBackgroundColor: AppColors.netflixRed.withOpacity(0.5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child:
                  _isAddingPlaylist
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text('Add Playlist'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(IPTVPlaylist playlist) {
    return ListTile(
      title: Text(
        playlist.name,
        style: const TextStyle(
          color: AppColors.netflixWhite,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        'Channels: ${playlist.numChannels} · ${playlist.type == PlaylistType.m3u ? 'M3U' : 'Xtream'}',
        style: const TextStyle(color: AppColors.netflixLightGrey),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: AppColors.netflixRed),
        onPressed: () => _showDeleteConfirmation(playlist),
      ),
      onTap: () {
        // Show playlist URL in a modal bottom sheet
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.netflixDarkGrey,
          builder:
              (context) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: const TextStyle(
                        color: AppColors.netflixWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'URL:',
                      style: TextStyle(
                        color: AppColors.netflixRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      playlist.url,
                      style: const TextStyle(color: AppColors.netflixWhite),
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  void _showDeleteConfirmation(IPTVPlaylist playlist) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.netflixDarkGrey,
            title: const Text(
              'Delete Playlist',
              style: TextStyle(color: AppColors.netflixWhite),
            ),
            content: Text(
              'Are you sure you want to delete "${playlist.name}"?',
              style: const TextStyle(color: AppColors.netflixLightGrey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.netflixLightGrey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (playlist.id != null) {
                    _deletePlaylist(playlist.id!);
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.netflixRed),
                ),
              ),
            ],
          ),
    );
  }
}
