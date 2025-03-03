class Movie {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final String? releaseDate;
  final List<String>? genres;
  final String mediaType;
  final String? url; // IPTV stream URL

  Movie({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.releaseDate,
    this.genres,
    required this.mediaType,
    this.url,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? 'Unknown Title',
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: json['vote_average']?.toDouble(),
      releaseDate: json['release_date'] ?? json['first_air_date'],
      genres: json['genre_ids'] != null ? (json['genre_ids'] as List).map((id) => id.toString()).toList() : null,
      mediaType: json['media_type'] ?? (json['name'] != null ? 'tv' : 'movie'),
      url: json['url'], // Add support for IPTV stream URL
    );
  }

  static List<Movie> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Movie.fromJson(json)).toList();
  }

  String get fullPosterPath {
    if (posterPath == null || posterPath!.isEmpty) {
      return 'https://via.placeholder.com/500x750?text=${Uri.encodeComponent(title)}';
    }

    // If it's already a full URL (from IPTV logo)
    if (posterPath!.startsWith('http')) {
      return posterPath!;
    }

    // Otherwise, assume it's a TMDB path
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  String get fullBackdropPath {
    if (backdropPath == null || backdropPath!.isEmpty) {
      return 'https://via.placeholder.com/1280x720?text=${Uri.encodeComponent(title)}';
    }

    // If it's already a full URL (from IPTV logo)
    if (backdropPath!.startsWith('http')) {
      return backdropPath!;
    }

    // Otherwise, assume it's a TMDB path
    return 'https://image.tmdb.org/t/p/original$backdropPath';
  }
}
