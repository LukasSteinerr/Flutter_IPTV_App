import 'package:flutter/material.dart';
import 'package:my_project_name/screens/movies_screen.dart';
import 'package:my_project_name/screens/tv_shows_screen.dart';
import 'package:my_project_name/screens/live_tv_screen.dart';
import 'package:my_project_name/screens/settings_screen.dart';

class NavigationScreen extends StatefulWidget {
  final int initialIndex;

  const NavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const MoviesScreen(),
    const TvShowsScreen(),
    const LiveTvScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = ['Movies', 'TV Shows', 'Live TV', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.movie_outlined),
              activeIcon: const Icon(Icons.movie),
              label: _titles[0],
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.tv_outlined),
              activeIcon: const Icon(Icons.tv),
              label: _titles[1],
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.live_tv_outlined),
              activeIcon: const Icon(Icons.live_tv),
              label: _titles[2],
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: _titles[3],
            ),
          ],
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}
