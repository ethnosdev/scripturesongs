import 'package:flutter/foundation.dart';
import 'package:scripturesongs/models/catalog_models.dart';
import 'package:scripturesongs/services/service_locator.dart';
import 'package:scripturesongs/services/api_service.dart';
import 'package:scripturesongs/services/audio_manager.dart';
import 'package:scripturesongs/services/download_manager.dart';
import 'package:scripturesongs/services/storage_service.dart';
import 'package:scripturesongs/services/user_settings.dart';
import 'package:share_plus/share_plus.dart';

class HomeManager {
  final ApiService _apiService = getIt<ApiService>();
  final AudioManager _audioManager = getIt<AudioManager>();
  final DownloadManager _downloadManager = getIt<DownloadManager>();
  final StorageService _storageService = getIt<StorageService>();
  final UserSettings _userSettings = getIt<UserSettings>();

  // Data
  final ValueNotifier<String> currentCollectionId = ValueNotifier('');
  final ValueNotifier<List<Track>> currentTracks = ValueNotifier([]);
  final ValueNotifier<String> collectionTitle = ValueNotifier(
    'Scripture Songs',
  );

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

  Map<String, TrackStatus> _lastStatuses = {};

  HomeManager() {
    _audioManager.progressNotifier.addListener(() {
      progressNotifier.value = _audioManager.progressNotifier.value;
    });

    _downloadManager.trackStatuses.addListener(_onTrackStatusesChanged);

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

    _lastStatuses = Map.from(_downloadManager.trackStatuses.value);
    await syncPlaylist();
  }

  void _onTrackStatusesChanged() {
    bool needsRebuild = false;
    final currentStatuses = _downloadManager.trackStatuses.value;

    for (var track in currentTracks.value) {
      final oldStatus = _lastStatuses[track.id];
      final newStatus = currentStatuses[track.id];

      if (oldStatus != newStatus) {
        if (newStatus == TrackStatus.downloaded ||
            oldStatus == TrackStatus.downloaded) {
          needsRebuild = true;
        }
      }
    }
    _lastStatuses = Map.from(currentStatuses);

    if (needsRebuild) {
      syncPlaylist();
    }
  }

  Future<void> syncPlaylist() async {
    final List<Track> downloadedTracks = [];
    final List<String> filePaths = [];

    for (var track in currentTracks.value) {
      if (_downloadManager.trackStatuses.value[track.id] ==
          TrackStatus.downloaded) {
        final version = await _downloadManager.getActiveVersion(track);
        final file = await _storageService.getFileForVersion(version.id);

        if (file.existsSync()) {
          downloadedTracks.add(track);
          filePaths.add(file.path);
        }
      }
    }

    await _audioManager.setPlaylist(downloadedTracks, filePaths);
  }

  // --- Playback ---

  Future<void> playTrack(Track track) async {
    final status = _downloadManager.trackStatuses.value[track.id];

    if (status == TrackStatus.notDownloaded) {
      _audioManager.pause();
      await _downloadManager.downloadTrack(track);
      await syncPlaylist();
    }

    if (_downloadManager.trackStatuses.value[track.id] !=
        TrackStatus.downloaded)
      return;

    final index = _audioManager.getIndexForTrackId(track.id);
    if (index != -1) {
      _audioManager.seekToStats(index);
      _audioManager.play();
    }
  }

  Future<void> playNext() async {
    final currentItem = _audioManager.currentSongNotifier.value;

    if (currentItem == null) {
      if (currentTracks.value.isNotEmpty) playTrack(currentTracks.value.first);
      return;
    }

    final currentIndex = currentTracks.value.indexWhere(
      (t) => t.id == currentItem.id,
    );

    if (currentIndex != -1 && currentIndex < currentTracks.value.length - 1) {
      await playTrack(currentTracks.value[currentIndex + 1]);
    }
  }

  Future<void> playPrevious() async {
    final currentItem = _audioManager.currentSongNotifier.value;
    if (currentItem == null) return;

    if (_audioManager.progressNotifier.value.current >
        const Duration(seconds: 3)) {
      _audioManager.seek(Duration.zero);
      return;
    }

    final currentIndex = currentTracks.value.indexWhere(
      (t) => t.id == currentItem.id,
    );
    if (currentIndex > 0) {
      await playTrack(currentTracks.value[currentIndex - 1]);
    } else {
      _audioManager.seek(Duration.zero);
    }
  }

  // --- Favorites ---
  Future<void> _initFavorites() async {
    final savedIds = await _userSettings.getFavoriteSongIds();
    if (savedIds.isNotEmpty) {
      final catalog = await _apiService.getCatalog();
      for (var id in savedIds) {
        for (var collection in catalog.collections) {
          try {
            final track = collection.tracks.firstWhere((t) => t.id == id);
            _favorites.add(track);
            break;
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

  Future<void> shareCurrentTrack() async {
    final currentItem = _audioManager.currentSongNotifier.value;
    if (currentItem == null) return;

    Track? trackToShare;

    // Check current view first for speed
    try {
      trackToShare = currentTracks.value.firstWhere(
        (t) => t.id == currentItem.id,
      );
    } catch (_) {
      // Fallback: search entire catalog
      final catalog = await _apiService.getCatalog();
      for (var collection in catalog.collections) {
        try {
          trackToShare = collection.tracks.firstWhere(
            (t) => t.id == currentItem.id,
          );
          break;
        } catch (_) {}
      }
    }

    if (trackToShare != null) {
      await shareTrack(trackToShare);
    }
  }

  Future<void> shareTrack(Track track) async {
    final version = await _downloadManager.getActiveVersion(track);
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
