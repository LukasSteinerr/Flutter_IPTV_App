import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/screens/detail_screen.dart';
import 'package:my_project_name/screens/navigation_screen.dart';
import 'package:my_project_name/screens/splash_screen.dart';
import 'package:my_project_name/services/database_service.dart';
import 'package:my_project_name/services/playlist_data_provider.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PlaylistDataProvider(),
      child: MaterialApp(
        title: 'IPTV Streamer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const StartupHandler(),
        onGenerateRoute: (settings) {
          // Handle the /detail route
          if (settings.name == '/detail') {
            // Extract the arguments
            final movie = settings.arguments as Movie;
            // Return the detail screen route
            return MaterialPageRoute(
              builder: (context) => DetailScreen(movie: movie),
            );
          }
          // If route not found, return to home
          return MaterialPageRoute(
            builder: (context) => const NavigationScreen(),
          );
        },
      ),
    );
  }
}

class StartupHandler extends StatefulWidget {
  const StartupHandler({super.key});

  @override
  State<StartupHandler> createState() => _StartupHandlerState();
}

class _StartupHandlerState extends State<StartupHandler> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final dataProvider = Provider.of<PlaylistDataProvider>(
      context,
      listen: false,
    );
    await dataProvider.initializeData();

    // Add a small delay to show the splash screen even if data loads quickly
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<PlaylistDataProvider>(context);

    // If we've finished loading, go to the main screen
    if (_initialized && !dataProvider.isLoading) {
      return const NavigationScreen();
    }

    // Otherwise show the splash screen with loading state
    return SplashScreen(
      isLoading: true,
      loadingMessage: dataProvider.loadingMessage,
    );
  }
}
