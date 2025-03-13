import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/screens/navigation_screen.dart';
import 'package:my_project_name/screens/onboarding/onboarding_screen.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Initialize the database
  await DatabaseService.database;
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final isOnboardingComplete =
        await PreferencesService().isOnboardingComplete();

    setState(() {
      _showOnboarding = !isOnboardingComplete;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPTV Streamer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home:
          _isLoading
              ? const _SplashScreen()
              : _showOnboarding
              ? const OnboardingScreen()
              : const NavigationScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.live_tv_rounded,
                size: 60,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'StreamView',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
