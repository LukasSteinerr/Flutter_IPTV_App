import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/screens/navigation_screen.dart';
import 'package:my_project_name/services/database_service.dart';

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
    return MaterialApp(
      title: 'IPTV Streamer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const NavigationScreen(),
    );
  }
}
