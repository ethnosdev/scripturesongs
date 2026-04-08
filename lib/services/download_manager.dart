import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:scripturesongs/models/catalog_models.dart';
import 'package:scripturesongs/services/api_service.dart';
import 'package:scripturesongs/services/service_locator.dart';
import 'package:scripturesongs/services/storage_service.dart';
import 'package:scripturesongs/services/user_settings.dart';

enum TrackStatus { notDownloaded, downloading, downloaded }

class DownloadManager {
  final ApiService _apiService = getIt<ApiService>();
  final StorageService _storageService = getIt<StorageService>();
  final UserSettings _userSettings = getIt<UserSettings>();

  final ValueNotifier<Map<String, TrackStatus>> trackStatuses = ValueNotifier(
    {},
  );
  final ValueNotifier<Map<String, double>> trackProgresses = ValueNotifier({});

  /// Scans file system to set initial download statuses for all tracks globally
  Future<void> init() async {
    final catalog = await _apiService.getCatalog();
    final Map<String, TrackStatus> statuses = {};
    for (var collection in catalog.collections) {
      for (var track in collection.tracks) {
        final version = await getActiveVersion(track);
        final isDownloaded = await _storageService.isDownloaded(version.id);
        statuses[track.id] = isDownloaded
            ? TrackStatus.downloaded
            : TrackStatus.notDownloaded;
      }
    }
    trackStatuses.value = statuses;
  }

  Future<Version> getActiveVersion(Track track) async {
    final prefId = await _userSettings.getPreferredVersion(track.id);
    if (prefId != null) {
      try {
        return track.versions.firstWhere((v) => v.id == prefId);
      } catch (_) {}
    }
    return track.versions.first;
  }

  Future<void> downloadTrack(Track track) async {
    if (trackStatuses.value[track.id] == TrackStatus.downloading) return;

    final version = await getActiveVersion(track);

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
      log('Download error: $e');
      trackStatuses.value = {
        ...trackStatuses.value,
        track.id: TrackStatus.notDownloaded,
      };
      return;
    }

    final updatedStatuses = Map<String, TrackStatus>.from(trackStatuses.value);
    updatedStatuses[track.id] = TrackStatus.downloaded;
    trackStatuses.value = updatedStatuses;
  }

  Future<void> deleteTrack(Track track) async {
    final version = await getActiveVersion(track);
    await _storageService.deleteFile(version.id);

    final updatedStatuses = Map<String, TrackStatus>.from(trackStatuses.value);
    updatedStatuses[track.id] = TrackStatus.notDownloaded;
    trackStatuses.value = updatedStatuses;
  }

  Future<void> downloadCollection(Collection collection) async {
    for (var track in collection.tracks) {
      if (trackStatuses.value[track.id] == TrackStatus.notDownloaded) {
        await downloadTrack(track);
      }
    }
  }

  Future<void> deleteCollection(Collection collection) async {
    for (var track in collection.tracks) {
      if (trackStatuses.value[track.id] == TrackStatus.downloaded) {
        await deleteTrack(track);
      }
    }
  }
}
