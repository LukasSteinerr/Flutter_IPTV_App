import 'package:flutter/material.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/services/epg_service.dart';
import 'package:my_project_name/services/preferences_service.dart';
import 'package:my_project_name/screens/navigation_screen.dart';
import 'package:my_project_name/widgets/animated_progress_button.dart';

class EpgSetupScreen extends StatefulWidget {
  const EpgSetupScreen({super.key});

  @override
  State<EpgSetupScreen> createState() => _EpgSetupScreenState();
}

class _EpgSetupScreenState extends State<EpgSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _epgUrlController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;
  final bool _isSkippable = true;

  @override
  void dispose() {
    _epgUrlController.dispose();
    super.dispose();
  }

  Future<void> _testAndSaveEpgUrl() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final epgUrl = _epgUrlController.text.trim();

      // Test if the EPG URL is valid
      await EpgService().fetchEpgData(epgUrl);

      // If we get here, the EPG URL is valid, so save it
      await PreferencesService().setEpgUrl(epgUrl);

      // Complete setup and navigate to main app
      _completeSetup();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to validate EPG URL: $e';
        _isProcessing = false;
      });
    }
  }

  void _skipEpgSetup() async {
    // Complete setup and navigate to main app
    _completeSetup();
  }

  void _completeSetup() async {
    // Mark onboarding as complete
    await PreferencesService().setOnboardingComplete(true);

    // Navigate to main app
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const NavigationScreen(initialIndex: 0),
        ),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electronic Program Guide'),
        actions: [
          if (_isSkippable)
            TextButton(onPressed: _skipEpgSetup, child: const Text('Skip')),
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
                      Icons.calendar_month_rounded,
                      size: 80,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title and description
                Center(
                  child: Text(
                    'Set up your TV Guide (Optional)',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'An Electronic Program Guide (EPG) provides TV schedules for your channels. Add an XMLTV URL to see what\'s on now and coming up next.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 32),

                // EPG URL
                TextFormField(
                  controller: _epgUrlController,
                  decoration: const InputDecoration(
                    labelText: 'EPG URL',
                    hintText: 'http://example.com/epg.xml',
                    prefixIcon: Icon(Icons.link),
                    helperText: 'Enter your XMLTV EPG URL',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null; // EPG is optional
                    }

                    final trimmedValue = value.trim();
                    if (!trimmedValue.startsWith('http')) {
                      return 'URL must start with http:// or https://';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            size: 20,
                            color: AppColors.accentColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Tips',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Your IPTV provider may offer an EPG URL',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• EPG data is usually in XMLTV format',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• You can add or change EPG URL later in Settings',
                        style: TextStyle(color: AppColors.textSecondary),
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
                    onPressed: _testAndSaveEpgUrl,
                    isLoading: _isProcessing,
                    loadingText: 'Validating',
                    defaultText:
                        _epgUrlController.text.isEmpty
                            ? 'Skip for now'
                            : 'Continue',
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
