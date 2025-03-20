import 'package:flutter/material.dart';
import 'package:my_project_name/widgets/shimmer_loading.dart';

class SplashScreen extends StatelessWidget {
  final bool isLoading;
  final String? loadingMessage;

  const SplashScreen({
    super.key,
    this.isLoading = true,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(
                  Icons.live_tv,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // App Name
            Text(
              'IPTV Streamer',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 48),

            // Loading indicator
            if (isLoading) ...[
              const ShimmerContainer(
                width: 40,
                height: 40,
                borderRadius: 20,
              ),
              const SizedBox(height: 16),
              Text(
                loadingMessage ?? 'Loading your content...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(179),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
