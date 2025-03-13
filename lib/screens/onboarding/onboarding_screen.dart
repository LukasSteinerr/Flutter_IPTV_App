import 'package:flutter/material.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/screens/onboarding/playlist_setup_screen.dart';
import 'package:my_project_name/services/preferences_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 3;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to StreamView',
      description: 'Your ultimate IPTV streaming companion. Access all your favorite channels, movies, and TV shows in one place.',
      imagePath: 'assets/images/onboarding1.png',
      iconData: Icons.live_tv_rounded,
    ),
    OnboardingPage(
      title: 'Movies, TV Shows & Live TV',
      description: 'Browse through thousands of movies, TV shows, and live TV channels from your IPTV subscription.',
      imagePath: 'assets/images/onboarding2.png',
      iconData: Icons.movie_rounded,
    ),
    OnboardingPage(
      title: 'Easy Setup',
      description: 'Simply add your M3U playlist URL or Xtream Codes login to start streaming your content.',
      imagePath: 'assets/images/onboarding3.png',
      iconData: Icons.playlist_add_check_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < _numPages - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    // Mark onboarding as complete
    await PreferencesService().setOnboardingComplete(true);
    
    // Navigate to playlist setup screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PlaylistSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _pages[index].build(context);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicator
                  Row(
                    children: List.generate(
                      _numPages,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentPage 
                            ? AppColors.primaryColor
                            : AppColors.textSecondary.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  
                  // Next button
                  ElevatedButton(
                    onPressed: _onNextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _currentPage < _numPages - 1 ? 'Next' : 'Get Started',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String? imagePath;
  final IconData iconData;

  OnboardingPage({
    required this.title,
    required this.description,
    this.imagePath,
    required this.iconData,
  });

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image or icon
          if (imagePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Image.asset(
                imagePath!,
                height: 200,
              ),
            )
          else
            Icon(
              iconData,
              size: 120,
              color: AppColors.primaryColor,
            ),
            
          const SizedBox(height: 40),
            
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
            
          const SizedBox(height: 16),
            
          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}