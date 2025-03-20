import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/screens/detail_screen.dart';
import 'package:my_project_name/screens/navigation_screen.dart';
import 'package:my_project_name/screens/splash_screen.dart';
import 'package:my_project_name/screens/settings_screen.dart';
import 'package:my_project_name/services/playlist_data_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PlaylistDataProvider()),
        // Add other providers here if needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPTV Streamer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const InitialScreen(),
      routes: {
        '/navigation': (context) => const NavigationScreen(),
        '/detail': (context) {
          final Movie movie =
              ModalRoute.of(context)!.settings.arguments as Movie;
          return DetailScreen(movie: movie);
        },
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize data and navigate to main screen when done
    _initializeData();
  }

  Future<void> _initializeData() async {
    final dataProvider = Provider.of<PlaylistDataProvider>(
      context,
      listen: false,
    );
    await dataProvider.initializeData();

    if (!mounted) return;

    // Navigate to main screen
    Navigator.of(context).pushReplacementNamed('/navigation');
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<PlaylistDataProvider>(context);

    return SplashScreen(
      isLoading: dataProvider.isLoading,
      loadingMessage: dataProvider.loadingMessage,
    );
  }
}
