import 'package:flutter/material.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/screens/onboarding/epg_setup_screen.dart';
import 'package:my_project_name/services/playlist_service.dart';
import 'package:my_project_name/services/preferences_service.dart';
import 'package:my_project_name/widgets/animated_progress_button.dart';

class PlaylistSetupScreen extends StatefulWidget {
  const PlaylistSetupScreen({super.key});

  @override
  State<PlaylistSetupScreen> createState() => _PlaylistSetupScreenState();
}

class _PlaylistSetupScreenState extends State<PlaylistSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _isAdvancedOptions = false;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _addPlaylist() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await PlaylistService.addPlaylist(
        _nameController.text.trim(),
        _urlController.text.trim(),
      );

      if (result['success']) {
        // Mark that user has added a playlist
        await PreferencesService().setHasActivePlaylist(true);

        // Navigate to EPG setup screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EpgSetupScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['errorMessage'] ?? 'Failed to add playlist';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  void _skipPlaylistSetup() async {
    // User can skip for now, but app will still show the empty state
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const EpgSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Playlist'),
        actions: [
          TextButton(onPressed: _skipPlaylistSetup, child: const Text('Skip')),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Illustration or icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.playlist_add_rounded,
                      size: 80,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title and description
                Text(
                  'Add your first playlist',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'To start streaming, add an M3U playlist URL or Xtream Codes login from your IPTV provider.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 32),

                // Playlist name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Playlist Name',
                    hintText: 'My IPTV Channels',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name for your playlist';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Playlist URL
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Playlist URL or Xtream Login',
                    hintText: 'http://example.com/playlist.m3u',
                    prefixIcon: Icon(Icons.link),
                    helperText: 'Enter M3U URL or Xtream Codes URL',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a valid playlist URL';
                    }

                    final trimmedValue = value.trim();
                    if (!trimmedValue.startsWith('http')) {
                      return 'URL must start with http:// or https://';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // Toggle advanced options
                InkWell(
                  onTap: () {
                    setState(() {
                      _isAdvancedOptions = !_isAdvancedOptions;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          _isAdvancedOptions
                              ? Icons.arrow_drop_down
                              : Icons.arrow_right,
                          color: AppColors.textSecondary,
                        ),
                        const Text('Advanced options'),
                      ],
                    ),
                  ),
                ),

                // Advanced options fields
                if (_isAdvancedOptions)
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'For Xtream Codes, you can also enter:',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'http://domain.com:port/username/password',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'or',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'http://domain.com:port/player_api.php?username=xxx&password=xxx',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Error message
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.errorColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.errorColor),
                    ),
                  ),

                if (_errorMessage != null) const SizedBox(height: 16),

                // Add button
                SizedBox(
                  width: double.infinity,
                  child: AnimatedProgressButton(
                    onPressed: _addPlaylist,
                    isLoading: _isProcessing,
                    loadingText: 'Processing',
                    defaultText: 'Add Playlist',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
