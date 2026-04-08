import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:scripturesongs/models/catalog_models.dart';

class AudioManager {
  final _audioPlayer = AudioPlayer();

  final currentSongNotifier = ValueNotifier<MediaItem?>(null);
  final isFirstSongNotifier = ValueNotifier<bool>(true);
  final isLastSongNotifier = ValueNotifier<bool>(true);
  final playButtonNotifier = ValueNotifier<ButtonState>(ButtonState.paused);
  final loopModeNotifier = ValueNotifier<LoopMode>(LoopMode.off);

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

  Future<void> setPlaylist(
    List<Track> tracks,
    List<String> filePaths, {
    String? initialTrackId,
    Duration? initialPosition,
  }) async {
    if (tracks.isEmpty || tracks.length != filePaths.length) return;

    final List<AudioSource> audioSources = List.generate(tracks.length, (
      index,
    ) {
      final track = tracks[index];
      return AudioSource.file(
        filePaths[index],
        tag: MediaItem(
          id: track.id,
          title: track.title,
          artist: track.reference,
        ),
      );
    });

    int initialIndex = 0;
    if (initialTrackId != null) {
      final index = tracks.indexWhere((t) => t.id == initialTrackId);
      if (index != -1) {
        initialIndex = index;
      } else {
        initialPosition = Duration.zero;
      }
    }

    await _audioPlayer.setAudioSources(
      audioSources,
      initialIndex: initialIndex,
      initialPosition: initialPosition ?? Duration.zero,
    );
  }

  int getIndexForTrackId(String trackId) {
    final sequence = _audioPlayer.sequence;
    for (int i = 0; i < sequence.length; i++) {
      final tag = sequence[i].tag;
      if (tag is MediaItem && tag.id == trackId) {
        return i;
      }
    }
    return -1;
  }

  void _listenForSequenceState() {
    _audioPlayer.sequenceStateStream.listen((sequenceState) {
      final currentItem = sequenceState.currentSource;
      if (currentItem?.tag is MediaItem) {
        currentSongNotifier.value = currentItem!.tag as MediaItem;
      }

      final currentIndex = sequenceState.currentIndex;
      isFirstSongNotifier.value = currentIndex == 0;
      isLastSongNotifier.value =
          currentIndex == sequenceState.sequence.length - 1;
    });
  }

  void _listenForPlayerState() {
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      // Detect when playback reaches the end
      if (processingState == ProcessingState.completed) {
        if (_audioPlayer.loopMode == LoopMode.off &&
            _audioPlayer.currentIndex == _audioPlayer.sequence.length - 1) {
          _audioPlayer.seek(Duration.zero, index: 0);
          _audioPlayer.pause();
        }
      }

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
  void previous() => _audioPlayer.seekToPrevious();

  Future<void> seekToIndex(int index) async {
    await _audioPlayer.seek(Duration.zero, index: index);
  }

  Future<bool> next() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
      return true;
    }
    return false;
  }

  // Changed to an async Future so we can wait for the seek to finish before playing.
  Future<void> seekToStats(int index) async =>
      await _audioPlayer.seek(Duration.zero, index: index);

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

  void _listenForLoopMode() {
    _audioPlayer.loopModeStream.listen((mode) {
      loopModeNotifier.value = mode;
    });
  }

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
