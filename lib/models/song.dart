class Song {
  final String id;
  final String title;
  final String reference;
  final String url;
  final String collection;

  Song({
    required this.id,
    required this.title,
    required this.reference,
    required this.url,
    required this.collection,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
