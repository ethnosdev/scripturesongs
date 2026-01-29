import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:scripturesongs/models/song.dart';

class AudioManager {
  final _audioPlayer = AudioPlayer();

  final currentSongNotifier = ValueNotifier<MediaItem?>(null);
  final isFirstSongNotifier = ValueNotifier<bool>(true);
  final isLastSongNotifier = ValueNotifier<bool>(true);
  final playButtonNotifier = ValueNotifier<ButtonState>(ButtonState.paused);
  final loopModeNotifier = ValueNotifier<LoopMode>(LoopMode.off);
  final shuffleModeNotifier = ValueNotifier<bool>(false);

  final progressNotifier = ValueNotifier<ProgressBarState>(
    ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
    ),
  );

  AudioManager() {
    _init();
  }

  void _init() {
    _listenForPlayerState();
    _listenForPosition();
    _listenForBufferedPosition();
    _listenForDuration();
    _listenForSequenceState();
    _listenForLoopMode();
  }

  /// Loads the entire album into the player as a playlist
  Future<void> setPlaylist(List<Song> songs, List<String> filePaths) async {
    if (songs.length != filePaths.length) return;

    // 1. Create the list of AudioSources (files with metadata)
    final List<AudioSource> audioSources = List.generate(songs.length, (index) {
      final song = songs[index];
      return AudioSource.file(
        filePaths[index],
        tag: MediaItem(id: song.id, title: song.title, artist: song.reference),
      );
    });

    // 2. Load the list directly into the player
    // Note: Assuming your version supports setAudioSources(List<AudioSource>)
    await _audioPlayer.setAudioSources(
      audioSources,
      initialIndex: 0,
      initialPosition: Duration.zero,
    );
  }

  void _listenForSequenceState() {
    _audioPlayer.sequenceStateStream.listen((sequenceState) {
      final currentItem = sequenceState.currentSource;
      if (currentItem?.tag is MediaItem) {
        currentSongNotifier.value = currentItem!.tag as MediaItem;
      }

      // Update First/Last notifiers based on playlist position
      final currentIndex = sequenceState.currentIndex;
      isFirstSongNotifier.value = currentIndex == 0;
      isLastSongNotifier.value =
          currentIndex == sequenceState.sequence.length - 1;
      shuffleModeNotifier.value = sequenceState.shuffleModeEnabled;
    });
  }

  void _listenForPlayerState() {
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        playButtonNotifier.value = ButtonState.loading;
      } else if (!isPlaying) {
        playButtonNotifier.value = ButtonState.paused;
      } else {
        playButtonNotifier.value = ButtonState.playing;
      }
    });
  }

  // --- Controls ---

  void play() => _audioPlayer.play();
  void pause() => _audioPlayer.pause();
  void seek(Duration position) => _audioPlayer.seek(position);
  void previous() => _audioPlayer.seekToPrevious(); // Native playlist prev
  void next() => _audioPlayer.seekToNext(); // Native playlist next

  // Jump to specific song in playlist
  void seekToStats(int index) => _audioPlayer.seek(Duration.zero, index: index);

  void stop() async {
    await _audioPlayer.stop();
    currentSongNotifier.value = null;
  }

  void cycleLoopMode() {
    final current = _audioPlayer.loopMode;
    final next = switch (current) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    _audioPlayer.setLoopMode(next);
  }

  void toggleShuffle() {
    final enable = !shuffleModeNotifier.value;
    _audioPlayer.setShuffleModeEnabled(enable);
    if (enable) _audioPlayer.shuffle();
  }

  void _listenForLoopMode() {
    _audioPlayer.loopModeStream.listen((mode) {
      loopModeNotifier.value = mode;
    });
  }

  // Boilerplate position listeners
  void _listenForPosition() {
    _audioPlayer.positionStream.listen((position) {
      final old = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: position,
        buffered: old.buffered,
        total: old.total,
      );
    });
  }

  void _listenForBufferedPosition() {
    _audioPlayer.bufferedPositionStream.listen((buffered) {
      final old = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: old.current,
        buffered: buffered,
        total: old.total,
      );
    });
  }

  void _listenForDuration() {
    _audioPlayer.durationStream.listen((total) {
      final old = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: old.current,
        buffered: old.buffered,
        total: total ?? Duration.zero,
      );
    });
  }

  void dispose() => _audioPlayer.dispose();
}

// Keep existing Enum/Classes
enum ButtonState { paused, playing, loading }

class ProgressBarState {
  final Duration current;
  final Duration buffered;
  final Duration total;
  ProgressBarState({
    required this.current,
    required this.buffered,
    required this.total,
  });
}
