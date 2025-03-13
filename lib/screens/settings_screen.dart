import 'package:flutter/material.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/iptv_playlist.dart';
import 'package:my_project_name/screens/onboarding/playlist_setup_screen.dart';
import 'package:my_project_name/services/api_service.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/services/preferences_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<IPTVPlaylist> _playlists = [];
  bool _isLoading = true;
  String? _epgUrl;
  String? _appVersion;
  final TextEditingController _epgUrlController = TextEditingController();
  bool _isUpdatingEpg = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _epgUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load playlists
      final playlists = await DatabaseService.getPlaylists();

      // Load EPG URL
      final epgUrl = await PreferencesService().getEpgUrl();

      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();

      setState(() {
        _playlists = playlists;
        _epgUrl = epgUrl;
        _epgUrlController.text = epgUrl ?? '';
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation(IPTVPlaylist playlist) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Playlist'),
            content: Text(
              'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deletePlaylist(playlist.id!);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorColor,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
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
            backgroundColor: AppColors.successColor,
          ),
        );

        // Reload playlists
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting playlist'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _editEpgUrl() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update EPG URL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _epgUrlController,
                decoration: const InputDecoration(
                  labelText: 'EPG URL',
                  hintText: 'http://example.com/epg.xml',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter the URL of your XMLTV Electronic Program Guide',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed:
                  _isUpdatingEpg
                      ? null
                      : () {
                        _saveEpgUrl();
                        Navigator.pop(context);
                      },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveEpgUrl() async {
    setState(() {
      _isUpdatingEpg = true;
    });

    try {
      final newUrl = _epgUrlController.text.trim();
      await PreferencesService().setEpgUrl(newUrl);

      setState(() {
        _epgUrl = newUrl;
        _isUpdatingEpg = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('EPG URL updated'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isUpdatingEpg = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating EPG URL: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Playlists section
                    _buildSection(
                      title: 'Playlists',
                      icon: Icons.playlist_play,
                      children: [
                        ..._playlists.map(
                          (playlist) => _buildPlaylistItem(playlist),
                        ),

                        // Add new playlist button
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          title: const Text('Add new playlist'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PlaylistSetupScreen(),
                              ),
                            ).then((_) => _loadData());
                          },
                        ),
                      ],
                    ),

                    const Divider(),

                    // EPG section
                    _buildSection(
                      title: 'Electronic Program Guide',
                      icon: Icons.calendar_month,
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.link,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          title: const Text('EPG URL'),
                          subtitle: Text(
                            _epgUrl?.isNotEmpty == true
                                ? _epgUrl!
                                : 'No EPG URL set',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.edit),
                          onTap: _editEpgUrl,
                        ),
                      ],
                    ),

                    const Divider(),

                    // Playback section
                    _buildSection(
                      title: 'Playback',
                      icon: Icons.settings,
                      children: [
                        SwitchListTile(
                          title: const Text('Hardware Acceleration'),
                          subtitle: const Text(
                            'Use hardware acceleration for video playback when available',
                          ),
                          value: true, // This would be a preference value
                          onChanged: (value) {
                            // Save preference
                          },
                        ),
                      ],
                    ),

                    const Divider(),

                    // About section
                    _buildSection(
                      title: 'About',
                      icon: Icons.info_outline,
                      children: [
                        ListTile(
                          title: const Text('Version'),
                          subtitle: Text(_appVersion ?? 'Unknown'),
                        ),
                        ListTile(
                          title: const Text('Share App'),
                          leading: const Icon(Icons.share),
                          onTap: () {
                            Share.share('Check out this IPTV app!');
                          },
                        ),
                        ListTile(
                          title: const Text('Rate App'),
                          leading: const Icon(Icons.star_outline),
                          onTap: () {
                            launchUrl(
                              Uri.parse(
                                'market://details?id=com.yourcompany.appname',
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('Terms of Use'),
                          leading: const Icon(Icons.description_outlined),
                          onTap: () {
                            // Show terms dialog or navigate to terms screen
                          },
                        ),
                        ListTile(
                          title: const Text('Privacy Policy'),
                          leading: const Icon(Icons.privacy_tip_outlined),
                          onTap: () {
                            // Show privacy dialog or navigate to privacy screen
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildPlaylistItem(IPTVPlaylist playlist) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.playlist_play, color: AppColors.primaryColor),
      ),
      title: Text(playlist.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type: ${playlist.type == PlaylistType.m3u ? 'M3U' : 'Xtream'}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Channels: ${playlist.numChannels}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        color: AppColors.errorColor,
        onPressed: () => _showDeleteConfirmation(playlist),
      ),
      onTap: () {
        // Show playlist details/edit dialog
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(playlist.name),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      const Text(
                        'URL:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(playlist.url, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 16),
                      Text(
                        'Type: ${playlist.type == PlaylistType.m3u ? 'M3U' : 'Xtream Codes'}',
                      ),
                      const SizedBox(height: 4),
                      Text('Channels: ${playlist.numChannels}'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      },
    );
  }
}
