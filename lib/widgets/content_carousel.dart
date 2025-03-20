import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/widgets/shimmer_loading.dart';

class ContentCarousel extends StatelessWidget {
  final String title;
  final List<Movie> contentList;
  final Function(Movie) onTap;
  final bool isOriginals;

  const ContentCarousel({
    super.key,
    required this.title,
    required this.contentList,
    required this.onTap,
    this.isOriginals = false,
  });

  @override
  Widget build(BuildContext context) {
    if (contentList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: isOriginals ? 300 : 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            itemCount: contentList.length,
            itemBuilder: (BuildContext context, int index) {
              final Movie content = contentList[index];
              return GestureDetector(
                onTap: () => onTap(content),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  width: isOriginals ? 200 : 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 2/3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedNetworkImage(
                              imageUrl: content.fullPosterPath,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => ShimmerPosterImage(
                                width: isOriginals ? 200 : 140,
                                height: isOriginals ? 300 : 210,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[800],
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: Colors.white,
                                    size: 30.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!isOriginals)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            content.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
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
