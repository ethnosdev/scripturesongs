import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scripturesongs/services/service_locator.dart';
import 'package:scripturesongs/services/api_service.dart';
import 'package:scripturesongs/services/audio_manager.dart';
import 'package:scripturesongs/services/user_settings.dart';
import 'package:scripturesongs/models/song.dart';
import 'package:share_plus/share_plus.dart';

class HomeManager {
  final ApiService _apiService = locator<ApiService>();
  final AudioManager _audioManager = locator<AudioManager>();
  final UserSettings _userSettings = locator<UserSettings>();

  // Use a map to hold songs per collection
  final ValueNotifier<Map<String, List<Song>>> songs =
      ValueNotifier<Map<String, List<Song>>>({});

  // Current collection being viewed
  final ValueNotifier<String> currentCollection = ValueNotifier<String>(
    'philippians',
  );

  final ValueNotifier<ProgressBarState> progressNotifier =
      ValueNotifier<ProgressBarState>(
        ProgressBarState(
          current: Duration.zero,
          buffered: Duration.zero,
          total: Duration.zero,
        ),
      );

  // Notifier for batch download progress (0.0 to 1.0)
  final ValueNotifier<double?> downloadProgress = ValueNotifier(null);
  final ValueNotifier<String> downloadStatus = ValueNotifier('');

  // Favorites (in-memory for now)
  final List<Song> _favorites = []; // Local list
  final ValueNotifier<List<Song>> favoritesNotifier = ValueNotifier<List<Song>>(
    [],
  );

  HomeManager() {
    _audioManager.progressNotifier.addListener(() {
      progressNotifier.value = _audioManager.progressNotifier.value;
    });

    // Load initial collection
    loadSongs(currentCollection.value);
  }

  // Load songs for a given collection
  Future<void> loadSongs(String collection) async {
    List<Song> songList = [];

    if (collection == 'favorites') {
      // Load favorites from local list
      songList = List.from(_favorites); // Create a copy
    } else {
      songList = await _apiService.fetchSongsForCollection(collection);
    }

    // Update the songs map
    songs.value = {
      ...songs.value, // Keep existing collections
      collection: songList,
    };

    _audioManager.setQueue(songList);
    _updateFavorites(); // Ensure favorites UI is up-to-date
  }

  // Helper method to update the favorites notifier
  void _updateFavorites() {
    favoritesNotifier.value = List.from(_favorites);
  }

  // Add/Remove from favorites (simple toggle)
  void toggleFavorite(Song song) {
    if (_favorites.contains(song)) {
      _favorites.remove(song);
    } else {
      _favorites.add(song);
    }
    _updateFavorites();
  }

  bool isFavorite(Song song) {
    return _favorites.contains(song);
  }

  Future<bool> _requestPermission() async {
    if (Platform.isIOS) return true;
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 33) return true;
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return false;
  }

  /// Gets the local file for a song. Does not check if it exists.
  Future<File> _getLocalFile(Song song) async {
    final directory = await getApplicationDocumentsDirectory();
    // Sanitize filename
    final cleanTitle = song.title.replaceAll(RegExp(r'[^\w\s\.-]'), '');
    final fileName = '${song.id}_$cleanTitle.mp3';
    return File('${directory.path}/$fileName');
  }

  Future<bool> isSongDownloaded(Song song) async {
    final file = await _getLocalFile(song);
    return file.exists();
  }

  /// Returns the local path if downloaded, else null.
  Future<String?> getLocalPathIfAvailable(Song song) async {
    final file = await _getLocalFile(song);
    if (await file.exists()) return file.path;
    return null;
  }

  /// Downloads a single song to the app's document directory (for playback).
  /// This is distinct from the "Export to Downloads folder" feature if you want
  /// internal playback storage to be separate, but here we can use the same logic
  /// or specifically target AppDocuments for reliability.
  Future<String> downloadSongForPlayback(Song song) async {
    try {
      final file = await _getLocalFile(song);
      if (await file.exists()) return file.path;

      final response = await get(Uri.parse(song.url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  /// The method used by the UI "Download" menu option (exports to public folder)
  Future<String> downloadSongToPublic(Song song) async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) throw Exception('Permission denied.');

    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists())
        directory = await getExternalStorageDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) throw Exception('Could not determine save path');

    final cleanTitle = song.title.replaceAll(RegExp(r'[^\w\s\.-]'), '');
    final fileName = '$cleanTitle.mp3';
    final savePath = '${directory.path}/$fileName';
    final file = File(savePath);

    if (await file.exists()) return 'Song already exists!';

    final response = await get(Uri.parse(song.url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      return 'Saved to ${Platform.isAndroid ? "Downloads" : "Files app"}';
    } else {
      throw Exception('Failed to download');
    }
  }

  Future<void> downloadAllSongs(List<Song> songList) async {
    int total = songList.length;
    downloadProgress.value = 0.0;
    for (int i = 0; i < total; i++) {
      final song = songList[i];
      downloadStatus.value = 'Downloading ${i + 1}/$total: ${song.title}';

      if (!await isSongDownloaded(song)) {
        await downloadSongForPlayback(song);
      }

      downloadProgress.value = (i + 1) / total;
    }
    downloadProgress.value = null; // Done
    downloadStatus.value = '';
  }

  Future<bool> hasAskedCollection(String collection) {
    return _userSettings.hasAskedToDownloadCollection(collection);
  }

  Future<void> setAskedCollection(String collection, bool value) {
    return _userSettings.setAskedToDownloadCollection(collection, value);
  }

  Future<void> shareSong(Song song) async {
    await SharePlus.instance.share(
      ShareParams(
        text: '${song.title} (${song.reference})\n\n${song.url}',
        subject: 'Scripture Songs: ${song.title}',
      ),
    );
  }
}
