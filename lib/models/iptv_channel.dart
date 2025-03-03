class IPTVChannel {
  int? id;
  final String name;
  final String url;
  final String group;
  final String? logo;

  IPTVChannel({
    this.id,
    required this.name,
    required this.url,
    required this.group,
    this.logo,
  });

  factory IPTVChannel.fromMap(Map<String, dynamic> map) {
    return IPTVChannel(
      id: map['id'],
      name: map['name'],
      url: map['url'],
      group: map['group_name'],
      logo: map['logo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'group_name': group,
      'logo': logo,
    };
  }

  @override
  String toString() {
    return 'IPTVChannel(id: $id, name: $name, url: $url, group: $group, logo: $logo)';
  }

  static List<IPTVChannel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => IPTVChannel.fromMap(json)).toList();
  }

  String get fullPosterPath =>
      logo != null && logo!.isNotEmpty
          ? logo!
          : 'https://via.placeholder.com/500x750?text=${Uri.encodeComponent(name)}';

  String get fullBackdropPath =>
      logo != null && logo!.isNotEmpty
          ? logo!
          : 'https://via.placeholder.com/1280x720?text=${Uri.encodeComponent(name)}';
}
