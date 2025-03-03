import 'package:flutter/material.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/screens/home_screen.dart';
import 'package:my_project_name/screens/coming_soon_screen.dart';
import 'package:my_project_name/screens/downloads_screen.dart';
import 'package:my_project_name/screens/search_screen.dart';
import 'package:my_project_name/screens/playlists_screen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({Key? key}) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const ComingSoonScreen(),
    const PlaylistsScreen(),
    const DownloadsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.netflixBlack,
        selectedItemColor: AppColors.netflixWhite,
        unselectedItemColor: AppColors.netflixLightGrey,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play),
            label: 'Playlists',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Live TV'),
        ],
      ),
    );
  }
}
