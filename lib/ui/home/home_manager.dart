import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:scripturesongs/models/catalog_models.dart';
import 'package:scripturesongs/services/service_locator.dart';
import 'package:scripturesongs/services/api_service.dart';
import 'package:scripturesongs/services/audio_manager.dart';
import 'package:scripturesongs/services/storage_service.dart';
import 'package:scripturesongs/services/user_settings.dart';
import 'package:share_plus/share_plus.dart';

enum TrackStatus { notDownloaded, downloading, downloaded }

class HomeManager {
  final ApiService _apiService = getIt<ApiService>();
  final AudioManager _audioManager = getIt<AudioManager>();
  final StorageService _storageService = getIt<StorageService>();
  final UserSettings _userSettings = getIt<UserSettings>();

  // Data
  final ValueNotifier<String> currentCollectionId = ValueNotifier('');
  final ValueNotifier<List<Track>> currentTracks = ValueNotifier([]);
  final ValueNotifier<String> collectionTitle = ValueNotifier(
    'Scripture Songs',
  );

  // Track State
  final ValueNotifier<Map<String, TrackStatus>> trackStatuses = ValueNotifier(
    {},
  );
  final ValueNotifier<Map<String, double>> trackProgresses = ValueNotifier({});

  // Favorites
  final List<Track> _favorites = [];
  final ValueNotifier<List<Track>> favoritesNotifier = ValueNotifier([]);

  // Audio Progress
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
    loadCollection('philippians'); // Default startup collection
  }

  // --- Core Logic ---

  Future<void> loadCollection(String collectionId) async {
    _audioManager.stop();
    currentCollectionId.value = collectionId;

    if (collectionId == 'favorites') {
      currentTracks.value = List.from(_favorites);
      collectionTitle.value = 'Favorites';
    } else {
      final collection = await _apiService.getCollection(collectionId);
      if (collection != null) {
        currentTracks.value = collection.tracks;
        collectionTitle.value = collection.title;
      } else {
        currentTracks.value = [];
      }
    }

    await refreshTrackStatuses();
  }

  /// Checks the file system for every track to see if its active version is downloaded
  Future<void> refreshTrackStatuses() async {
    final Map<String, TrackStatus> newStatuses = Map.from(trackStatuses.value);

    for (var track in currentTracks.value) {
      // If it's currently downloading, don't overwrite its status
      if (newStatuses[track.id] == TrackStatus.downloading) {
        continue;
      }

      final activeVersion = await getActiveVersion(track);
      final isDownloaded = await _storageService.isDownloaded(activeVersion.id);
      newStatuses[track.id] = isDownloaded
          ? TrackStatus.downloaded
          : TrackStatus.notDownloaded;
    }

    trackStatuses.value = newStatuses;
    await _buildPlayerPlaylist();
  }

  /// Compiles all downloaded tracks into the just_audio playlist
  Future<void> _buildPlayerPlaylist() async {
    final List<Track> downloadedTracks = [];
    final List<String> filePaths = [];

    for (var track in currentTracks.value) {
      if (trackStatuses.value[track.id] == TrackStatus.downloaded) {
        final version = await getActiveVersion(track);
        final file = await _storageService.getFileForVersion(version.id);

        // Extra safety check: only add it if the file actually exists on disk
        if (file.existsSync()) {
          downloadedTracks.add(track);
          filePaths.add(file.path);
        }
      }
    }

    await _audioManager.setPlaylist(downloadedTracks, filePaths);
  }

  // --- Playback & Downloads ---

  Future<void> playTrack(Track track) async {
    final status = trackStatuses.value[track.id];

    // Pause current audio if we need to download the new one
    if (status == TrackStatus.notDownloaded) {
      _audioManager.pause();
      await downloadTrack(track);
    }

    if (trackStatuses.value[track.id] == TrackStatus.downloading) return;

    final index = _audioManager.getIndexForTrackId(track.id);
    if (index != -1) {
      _audioManager.seekToStats(index);
      _audioManager.play();
    }
  }

  Future<void> playNext() async {
    final currentItem = _audioManager.currentSongNotifier.value;

    // If nothing is playing, play the first track
    if (currentItem == null) {
      if (currentTracks.value.isNotEmpty) playTrack(currentTracks.value.first);
      return;
    }

    // Find where we are in the full album list
    final currentIndex = currentTracks.value.indexWhere(
      (t) => t.id == currentItem.id,
    );

    // If there is a next track, play it (this automatically triggers the download if needed!)
    if (currentIndex != -1 && currentIndex < currentTracks.value.length - 1) {
      await playTrack(currentTracks.value[currentIndex + 1]);
    }
  }

  Future<void> playPrevious() async {
    final currentItem = _audioManager.currentSongNotifier.value;
    if (currentItem == null) return;

    // Standard music player behavior: If we are more than 3 seconds into a song,
    // the previous button should just restart the current song.
    if (_audioManager.progressNotifier.value.current >
        const Duration(seconds: 3)) {
      _audioManager.seek(Duration.zero);
      return;
    }

    // Otherwise, go to the actual previous track
    final currentIndex = currentTracks.value.indexWhere(
      (t) => t.id == currentItem.id,
    );
    if (currentIndex > 0) {
      await playTrack(currentTracks.value[currentIndex - 1]);
    } else {
      _audioManager.seek(Duration.zero);
    }
  }

  Future<void> downloadTrack(Track track) async {
    final version = await getActiveVersion(track);

    // Update UI to downloading
    trackStatuses.value = {
      ...trackStatuses.value,
      track.id: TrackStatus.downloading,
    };
    trackProgresses.value = {...trackProgresses.value, track.id: 0.0};

    try {
      final file = await _storageService.getFileForVersion(version.id);
      final request = Request('GET', Uri.parse(version.url));
      final response = await Client().send(request);

      if (response.statusCode == 200) {
        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;

        final fileSink = file.openWrite();
        await for (var chunk in response.stream) {
          fileSink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            trackProgresses.value = {
              ...trackProgresses.value,
              track.id: receivedBytes / totalBytes,
            };
          }
        }
        await fileSink.close();
      } else {
        throw Exception('HTTP Failed');
      }
    } catch (e) {
      print('Download error: $e');
      // Revert status on failure
      trackStatuses.value = {
        ...trackStatuses.value,
        track.id: TrackStatus.notDownloaded,
      };
      return;
    }

    // SUCCESS FIX: Explicitly mark as downloaded and rebuild playlist!
    final updatedStatuses = Map<String, TrackStatus>.from(trackStatuses.value);
    updatedStatuses[track.id] = TrackStatus.downloaded;
    trackStatuses.value = updatedStatuses;

    await _buildPlayerPlaylist();
  }

  Future<void> deleteTrack(Track track) async {
    final version = await getActiveVersion(track);
    await _storageService.deleteFile(version.id);
    await refreshTrackStatuses();
  }

  Future<void> downloadAll() async {
    // Only download tracks that are not already downloaded
    for (var track in currentTracks.value) {
      if (trackStatuses.value[track.id] == TrackStatus.notDownloaded) {
        await downloadTrack(track);
      }
    }
  }

  Future<void> deleteAll() async {
    for (var track in currentTracks.value) {
      if (trackStatuses.value[track.id] == TrackStatus.downloaded) {
        await deleteTrack(track);
      }
    }
  }

  // --- Helpers ---

  Future<Version> getActiveVersion(Track track) async {
    final prefId = await _userSettings.getPreferredVersion(track.id);
    if (prefId != null) {
      try {
        return track.versions.firstWhere((v) => v.id == prefId);
      } catch (_) {}
    }
    // Default to the first version in the JSON array
    return track.versions.first;
  }

  // --- Favorites ---
  Future<void> _initFavorites() async {
    final savedIds = await _userSettings.getFavoriteSongIds();
    if (savedIds.isNotEmpty) {
      final catalog = await _apiService.getCatalog();
      for (var id in savedIds) {
        // Find track in entire catalog
        for (var collection in catalog.collections) {
          try {
            final track = collection.tracks.firstWhere((t) => t.id == id);
            _favorites.add(track);
            break; // Found it, move to next savedId
          } catch (_) {}
        }
      }
      favoritesNotifier.value = List.from(_favorites);
    }
  }

  void toggleFavorite(Track track) {
    if (_favorites.contains(track)) {
      _favorites.remove(track);
    } else {
      _favorites.add(track);
    }
    favoritesNotifier.value = List.from(_favorites);
    _userSettings.setFavoriteSongIds(_favorites.map((t) => t.id).toList());
  }

  bool isFavorite(Track track) => _favorites.contains(track);

  // --- Sharing ---
  Future<void> shareTrack(Track track) async {
    final version = await getActiveVersion(track);
    final file = await _storageService.getFileForVersion(version.id);

    if (file.existsSync()) {
      final params = ShareParams(
        text: '${track.title} (${track.reference})',
        files: [XFile(file.path, mimeType: 'audio/mpeg')],
      );
      await SharePlus.instance.share(params);
    } else {
      final params = ShareParams(
        uri: Uri.tryParse(version.url),
        text: '${track.title} (${track.reference})',
      );
      await SharePlus.instance.share(params);
    }
  }
}
