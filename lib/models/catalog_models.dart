class Catalog {
  final List<Collection> collections;
  Catalog({required this.collections});

  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog(
    collections: (json['collections'] as List)
        .map((c) => Collection.fromJson(c))
        .toList(),
  );
}

class Collection {
  final String id;
  final String title;
  final List<Track> tracks;
  Collection({required this.id, required this.title, required this.tracks});

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    id: json['id'],
    title: json['title'],
    tracks: (json['tracks'] as List).map((t) => Track.fromJson(t)).toList(),
  );
}

class Track {
  final String id;
  final String title;
  final String reference;
  final List<Version> versions;
  Track({
    required this.id,
    required this.title,
    required this.reference,
    required this.versions,
  });

  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'],
    title: json['title'],
    reference: json['reference'],
    versions: (json['versions'] as List)
        .map((v) => Version.fromJson(v))
        .toList(),
  );
}

class Version {
  final String id;
  final String url;
  Version({required this.id, required this.url});

  factory Version.fromJson(Map<String, dynamic> json) =>
      Version(id: json['id'], url: json['url']);
}
