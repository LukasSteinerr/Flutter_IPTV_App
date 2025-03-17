import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/movie.dart';

class FeaturedContent extends StatelessWidget {
  final Movie featuredContent;
  final Function() onPlayPress;
  final Function() onInfoPress;

  const FeaturedContent({
    super.key,
    required this.featuredContent,
    required this.onPlayPress,
    required this.onInfoPress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 500.0,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: CachedNetworkImageProvider(
                featuredContent.fullBackdropPath,
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: 500.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black,
                Colors.transparent,
                Colors.transparent,
                Colors.black,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.2, 0.8, 1],
            ),
          ),
        ),
        Positioned(
          bottom: 110.0,
          child: SizedBox(
            width: 250.0,
            child: Image.network(
              featuredContent.fullPosterPath,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          bottom: 40.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlayButton(onTap: onPlayPress),
              const SizedBox(width: 16.0),
              _InfoButton(onTap: onInfoPress),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final Function() onTap;

  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.netflixWhite,
        foregroundColor: AppColors.netflixBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow, size: 30.0),
          SizedBox(width: 4.0),
          Text(
            'Play',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _InfoButton extends StatelessWidget {
  final Function() onTap;

  const _InfoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.netflixDarkGrey.withOpacity(0.7),
        foregroundColor: AppColors.netflixWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 24.0),
          SizedBox(width: 4.0),
          Text(
            'More Info',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
