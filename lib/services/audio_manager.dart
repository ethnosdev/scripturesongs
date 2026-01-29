import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:scripturesongs/models/song.dart';
import 'package:scripturesongs/services/service_locator.dart';
import 'package:scripturesongs/ui/home/home_manager.dart';

class AudioManager {
  final _audioPlayer = AudioPlayer();
  List<Song> _queue = [];
  int _currentIndex = -1;

  final currentSongNotifier = ValueNotifier<MediaItem?>(null);
  final isFirstSongNotifier = ValueNotifier<bool>(true);
  final isLastSongNotifier = ValueNotifier<bool>(true);
  final playButtonNotifier = ValueNotifier<ButtonState>(ButtonState.paused);
  final progressNotifier = ValueNotifier<ProgressBarState>(
    ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
    ),
  );
  final loopModeNotifier = ValueNotifier<LoopMode>(LoopMode.off);

  AudioManager() {
    _listenForChangesInPlayerState();
    _listenForChangesInPlayerPosition();
    _listenForChangesInBufferedPosition();
    _listenForChangesInTotalDuration();
    _listenForChangesInLoopMode();
  }

  void setQueue(List<Song> songs) {
    _queue = songs;
  }

  // Called from UI when tapping a song
  Future<void> playSongAtIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await _loadAndPlayCurrent();
  }

  Future<void> _loadAndPlayCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;

    final song = _queue[_currentIndex];

    // Update Notifiers immediately so UI reflects the target song
    final mediaItem = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.reference,
    );
    currentSongNotifier.value = mediaItem;
    isFirstSongNotifier.value = _currentIndex == 0;
    isLastSongNotifier.value = _currentIndex == _queue.length - 1;

    try {
      final homeManager = locator<HomeManager>();

      // 1. Check if downloaded
      final path = await homeManager.getLocalPathIfAvailable(song);

      if (path != null) {
        // File exists, play it
        await _audioPlayer.setAudioSource(
          AudioSource.file(path, tag: mediaItem),
        );
        _audioPlayer.play();
      } else {
        // File missing. Pause (loading state), download, then play.
        playButtonNotifier.value = ButtonState.loading;

        // Ensure we are in a clean state
        _audioPlayer.pause();

        try {
          final newPath = await homeManager.downloadSongForPlayback(song);
          if (_currentIndex == _queue.indexOf(song)) {
            // Ensure user hasn't skipped away
            await _audioPlayer.setAudioSource(
              AudioSource.file(newPath, tag: mediaItem),
            );
            _audioPlayer.play();
          }
        } catch (e) {
          playButtonNotifier.value = ButtonState.paused;
          debugPrint("Error downloading song for playback: $e");
          // Optionally trigger play next or stop
        }
      }
    } catch (e) {
      debugPrint("Error loading audio source: $e");
    }
  }

  void _listenForChangesInPlayerState() {
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

      // Handle Auto-Advance (The "Loop" logic)
      if (processingState == ProcessingState.completed) {
        _handleSongCompletion();
      }
    });
  }

  void _handleSongCompletion() {
    final loopMode = loopModeNotifier.value;

    if (loopMode == LoopMode.one) {
      // Replay current
      _audioPlayer.seek(Duration.zero);
      _audioPlayer.play();
    } else {
      // Determine next index
      if (_currentIndex < _queue.length - 1) {
        next();
      } else if (loopMode == LoopMode.all) {
        // Loop back to start
        playSongAtIndex(0);
      } else {
        // End of playlist, stop.
        _audioPlayer.stop();
        _audioPlayer.seek(Duration.zero);
      }
    }
  }

  void _listenForChangesInPlayerPosition() {
    _audioPlayer.positionStream.listen((position) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });
  }

  void _listenForChangesInBufferedPosition() {
    _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: bufferedPosition,
        total: oldState.total,
      );
    });
  }

  void _listenForChangesInTotalDuration() {
    _audioPlayer.durationStream.listen((totalDuration) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: totalDuration ?? Duration.zero,
      );
    });
  }

  void _listenForChangesInLoopMode() {
    _audioPlayer.loopModeStream.listen((loopMode) {
      loopModeNotifier.value = loopMode;
    });
  }

  void play() => _audioPlayer.play();
  void pause() => _audioPlayer.pause();

  void seek(Duration position) => _audioPlayer.seek(position);

  void previous() {
    if (_currentIndex > 0) {
      playSongAtIndex(_currentIndex - 1);
    }
  }

  void next() {
    if (_currentIndex < _queue.length - 1) {
      playSongAtIndex(_currentIndex + 1);
    }
  }

  void cycleLoopMode() {
    final current = loopModeNotifier.value;
    final next = switch (current) {
      LoopMode.off => LoopMode.one,
      LoopMode.one => LoopMode.all,
      LoopMode.all => LoopMode.off,
    };
    loopModeNotifier.value = next;
    // We don't set it on the player because we handle looping manually logic above
    // except for LoopMode.one which we can let the player handle or handle manually.
    // However, since we reload files, manual handling is safer for the queue,
    // but player.setLoopMode(LoopMode.one) works fine for a single file.
    _audioPlayer.setLoopMode(
      next == LoopMode.one ? LoopMode.one : LoopMode.off,
    );
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

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
