import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scripturesongs/services/service_locator.dart';
import 'package:scripturesongs/services/api_service.dart';
import 'package:scripturesongs/services/audio_manager.dart';
import 'package:scripturesongs/models/song.dart';
import 'package:share_plus/share_plus.dart';

class HomeManager {
  final ApiService _apiService = locator<ApiService>();
  final AudioManager _audioManager = locator<AudioManager>();

  final ValueNotifier<List<Song>> songs = ValueNotifier<List<Song>>([]);
  final ValueNotifier<ProgressBarState> progressNotifier =
      ValueNotifier<ProgressBarState>(
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
  }

  Future<void> loadSongs() async {
    final songList = await _apiService.fetchSongs();
    songs.value = songList;
    _audioManager.initSongs(songList);
  }

  Future<bool> _requestPermission() async {
    if (Platform.isIOS) return true;

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // On Android 13+ (SDK 33), permission is READ_MEDIA_AUDIO,
      // but writing to "Downloads" usually works without it if using specific paths.
      // On older Android, we strictly need WRITE_EXTERNAL_STORAGE.

      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ usually allows writing to Downloads without explicit permission
        // if not using Mediastore, but let's check Audio to be safe for reading later.
        return true;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return false;
  }

  Future<String> downloadSong(Song song) async {
    // 1. Check Permissions
    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      throw Exception('Permission denied. Cannot save file.');
    }

    try {
      // 2. Determine the save path
      Directory? directory;

      if (Platform.isAndroid) {
        // Try to get the public Download folder
        directory = Directory('/storage/emulated/0/Download');
        // Fallback if that folder doesn't exist (unlikely)
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        // iOS: Use Documents directory (visible in Files app)
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) throw Exception('Could not determine save path');

      // 3. Create filename and check existence
      final cleanTitle = song.title.replaceAll(RegExp(r'[^\w\s\.-]'), '');
      final fileName = '$cleanTitle.mp3';
      final savePath = '${directory.path}/$fileName';
      final file = File(savePath);

      if (await file.exists()) {
        return 'Song already exists in ${Platform.isAndroid ? "Downloads" : "Files"}!';
      }

      // 4. Download
      final response = await get(Uri.parse(song.url));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return 'Saved to ${Platform.isAndroid ? "Downloads" : "Files app"}';
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Download failed: $e');
    }
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
