import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/movie.dart';

class ContentCarousel extends StatelessWidget {
  final String title;
  final List<Movie> contentList;
  final Function(Movie) onTap;
  final bool isOriginals;

  const ContentCarousel({
    super..key,
    required this.title,
    required this.contentList,
    required this.onTap,
    this.isOriginals = false,
  })

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        SizedBox(
          height: isOriginals ? 400 : 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            scrollDirection: Axis.horizontal,
            itemCount: contentList.length,
            itemBuilder: (context, index) {
              final movie = contentList[index];
              return GestureDetector(
                onTap: () => onTap(movie),
                child: Container(
                  width: isOriginals ? 200 : 140,
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: CachedNetworkImage(
                            imageUrl: isOriginals 
                                ? movie.fullPosterPath 
                                : movie.fullBackdropPath,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.netflixDarkGrey,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.netflixRed,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.netflixDarkGrey,
                              child: const Icon(
                                Icons.error,
                                color: AppColors.netflixRed,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!isOriginals)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            movie.title,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}