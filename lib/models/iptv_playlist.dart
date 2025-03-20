enum PlaylistType { m3u, xtream }

class IPTVPlaylist {
  int? id;
  final String name;
  final String url;
  final int numChannels;
  final PlaylistType type;

  IPTVPlaylist({
    this.id,
    required this.name,
    required this.url,
    this.numChannels = 0,
    required this.type,
  });

  factory IPTVPlaylist.fromMap(Map<String, dynamic> map) {
    return IPTVPlaylist(
      id: map['id'],
      name: map['name'],
      url: map['url'],
      numChannels: map['numChannels'] ?? 0,
      type: PlaylistType.values.firstWhere(
        (t) => t.toString() == map['type'],
        orElse: () => PlaylistType.m3u,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'numChannels': numChannels,
      'type': type.toString(),
    };
  }

  IPTVPlaylist copyWith({
    int? id,
    String? name,
    String? url,
    int? numChannels,
    PlaylistType? type,
  }) {
    return IPTVPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      numChannels: numChannels ?? this.numChannels,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'IPTVPlaylist(id: $id, name: $name, url: $url, numChannels: $numChannels, type: $type)';
  }
}
