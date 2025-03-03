import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_project_name/constants/app_theme.dart';
import 'package:my_project_name/models/movie.dart';
import 'package:my_project_name/screens/detail_screen.dart';
import 'package:my_project_name/services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final results = await Api.search(query);
      setState(() {
        _searchResults = Movie.fromJsonList(results);
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error searching: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.netflixBlack,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          cursorColor: AppColors.netflixRed,
          style: const TextStyle(color: AppColors.netflixWhite),
          decoration: InputDecoration(
            hintText: 'Search for channels, movies, or shows',
            hintStyle: TextStyle(color: AppColors.netflixLightGrey),
            border: InputBorder.none,
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.netflixLightGrey,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _hasSearched = false;
                        });
                      },
                    )
                    : null,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              _performSearch(value);
            } else {
              setState(() {
                _searchResults = [];
                _hasSearched = false;
              });
            }
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.netflixRed),
      );
    }

    if (_hasSearched && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 100,
              color: AppColors.netflixLightGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "${_searchController.text}"',
              style: const TextStyle(
                color: AppColors.netflixLightGrey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try searching with a different term',
              style: TextStyle(color: AppColors.netflixLightGrey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'Search for channels by name or category',
          style: TextStyle(color: AppColors.netflixLightGrey, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final movie = _searchResults[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailScreen(movie: movie)),
            );
          },
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: movie.fullPosterPath,
                    fit: BoxFit.cover,
                    errorWidget:
                        (context, url, error) => Container(
                          color: AppColors.netflixDarkGrey,
                          child: const Icon(
                            Icons.error,
                            color: AppColors.netflixRed,
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
