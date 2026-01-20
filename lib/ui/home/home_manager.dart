import 'package:flutter/material.dart';
import 'package:scripturesongs/services/service_locator.dart';
import 'package:scripturesongs/services/api_service.dart';
import 'package:scripturesongs/services/audio_manager.dart';
import 'package:scripturesongs/models/song.dart';

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
}
