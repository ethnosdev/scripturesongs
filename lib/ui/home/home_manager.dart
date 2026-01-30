import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scripturesongs/services/service_locator.dart';
import 'package:scripturesongs/services/api_service.dart';
import 'package:scripturesongs/services/audio_manager.dart';
import 'package:scripturesongs/services/user_settings.dart';
import 'package:scripturesongs/models/song.dart';
import 'package:share_plus/share_plus.dart';

enum CollectionStatus { loading, downloaded, notDownloaded, downloading }

class HomeManager {
  final ApiService _apiService = locator<ApiService>();
  final AudioManager _audioManager = locator<AudioManager>();
  final UserSettings _userSettings = locator<UserSettings>();

  // Data
  final ValueNotifier<Map<String, List<Song>>> songs = ValueNotifier({});
  final ValueNotifier<String> currentCollection = ValueNotifier('philippians');

  // UI State
  final ValueNotifier<CollectionStatus> collectionStatus = ValueNotifier(
    CollectionStatus.loading,
  );
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  final ValueNotifier<String> downloadMessage = ValueNotifier('');

  // Favorites
  final List<Song> _favorites = [];
  final ValueNotifier<List<Song>> favoritesNotifier = ValueNotifier([]);
  final ValueNotifier<ProgressBarState> progressNotifier = ValueNotifier(
    ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
    ),
  );

  HomeManager() {
    _audioManager.progressNotifier.addListener(() {
      progressNotifier.value = _audioManager.progressNotifier.value;
    });
    _initFavorites();
    loadCollection(currentCollection.value);
  }

  // --- Logic ---

  Future<void> loadCollection(String collection) async {
    collectionStatus.value = CollectionStatus.loading;
    _audioManager.stop(); // Stop previous album

    List<Song> songList = [];
    if (collection == 'favorites') {
      songList = List.from(_favorites);
    } else {
      songList = await _apiService.fetchSongsForCollection(collection);
    }

    songs.value = {...songs.value, collection: songList};
    currentCollection.value = collection;

    if (songList.isEmpty) {
      collectionStatus.value = CollectionStatus.downloaded; // Empty state
      return;
    }

    // Check if ALL songs are downloaded
    final allDownloaded = await _areAllSongsDownloaded(songList);

    if (allDownloaded) {
      await _initializePlayerWithCollection(songList);
      collectionStatus.value = CollectionStatus.downloaded;
    } else {
      collectionStatus.value = CollectionStatus.notDownloaded;
    }
  }

  Future<void> downloadCurrentCollection() async {
    final collection = currentCollection.value;
    final songList = songs.value[collection] ?? [];
    if (songList.isEmpty) return;

    collectionStatus.value = CollectionStatus.downloading;
    downloadProgress.value = 0.0;

    try {
      final docDir = await getApplicationDocumentsDirectory();

      for (int i = 0; i < songList.length; i++) {
        final song = songList[i];
        downloadMessage.value =
            'Downloading ${i + 1}/${songList.length}: ${song.title}';

        final file = await _getLocalFile(song, docDir);
        if (!file.existsSync()) {
          final request = Request('GET', Uri.parse(song.url));
          final response = await Client().send(request);
          if (response.statusCode == 200) {
            await response.stream.pipe(file.openWrite());
          } else {
            throw Exception('Failed to download ${song.title}');
          }
        }
        downloadProgress.value = (i + 1) / songList.length;
      }

      // Done downloading, initialize player
      await _initializePlayerWithCollection(songList);
      collectionStatus.value = CollectionStatus.downloaded;
    } catch (e) {
      collectionStatus.value = CollectionStatus.notDownloaded;
      downloadMessage.value = 'Error: $e';
    }
  }

  Future<void> _initializePlayerWithCollection(List<Song> songList) async {
    final docDir = await getApplicationDocumentsDirectory();
    final paths = <String>[];

    for (var song in songList) {
      final file = await _getLocalFile(song, docDir);
      paths.add(file.path);
    }

    await _audioManager.setPlaylist(songList, paths);
  }

  // --- Helpers ---

  Future<bool> _areAllSongsDownloaded(List<Song> list) async {
    final docDir = await getApplicationDocumentsDirectory();
    for (var song in list) {
      final file = await _getLocalFile(song, docDir);
      if (!file.existsSync()) return false;
    }
    return true;
  }

  Future<File> _getLocalFile(Song song, Directory dir) async {
    final cleanTitle = song.title.replaceAll(RegExp(r'[^\w\s\.-]'), '');
    return File('${dir.path}/${song.id}_$cleanTitle.mp3');
  }

  // --- Favorites Logic (Kept mostly same) ---
  Future<void> _initFavorites() async {
    final savedIds = await _userSettings.getFavoriteSongIds();
    if (savedIds.isNotEmpty) {
      final savedSongs = await _apiService.getSongsByIds(savedIds);
      _favorites.addAll(savedSongs);
      favoritesNotifier.value = List.from(_favorites);
    }
  }

  void toggleFavorite(Song song) {
    if (_favorites.contains(song)) {
      _favorites.remove(song);
    } else {
      _favorites.add(song);
    }
    favoritesNotifier.value = List.from(_favorites);
    _userSettings.setFavoriteSongIds(_favorites.map((s) => s.id).toList());
  }

  bool isFavorite(Song song) => _favorites.contains(song);

  // Single share
  Future<void> shareSong(Song song) async {
    // 1. Get the local cached file
    final docDir = await getApplicationDocumentsDirectory();
    final file = await _getLocalFile(song, docDir);

    // 2. Check if the file actually exists (is downloaded)
    if (file.existsSync()) {
      // 3. Share the FILE (Binary data)
      // On iOS: User sees "Save to Files", "Messages", "AirDrop", etc.
      // On Android: User sees "Bluetooth", "Drive", "WhatsApp", etc.
      final params = ShareParams(
        text: '${song.title} (${song.reference})',
        files: [XFile(file.path, mimeType: 'audio/mpeg')],
      );

      await SharePlus.instance.share(params);
    } else {
      // 4. Fallback: If not downloaded, just share the LINK
      final params = ShareParams(
        uri: Uri.tryParse(song.url),
        text: '${song.title} (${song.reference})',
      );
      await SharePlus.instance.share(params);
    }
  }
}
