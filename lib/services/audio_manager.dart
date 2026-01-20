import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:scripturesongs/models/song.dart';

class AudioManager {
  final _audioPlayer = AudioPlayer();
  late ConcatenatingAudioSource _playlist;

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

  void initSongs(List<Song> songs) {
    _playlist = ConcatenatingAudioSource(
      children: songs.map((song) {
        return LockCachingAudioSource(
          Uri.parse(song.url),
          tag: MediaItem(
            id: song.id,
            title: song.title,
            artist: song.reference,
          ),
        );
      }).toList(),
    );
    _audioPlayer.setAudioSource(_playlist);

    _listenForChangesInPlayerState();
    _listenForChangesInPlayerPosition();
    _listenForChangesInBufferedPosition();
    _listenForChangesInTotalDuration();
    _listenForChangesInSequenceState();
    _listenForChangesInLoopMode();
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
    });
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

  void _listenForChangesInSequenceState() {
    _audioPlayer.sequenceStateStream.listen((sequenceState) {
      if (sequenceState == null) return;
      final currentItem = sequenceState.currentSource;
      currentSongNotifier.value = currentItem?.tag as MediaItem?;
      isFirstSongNotifier.value = sequenceState.currentIndex == 0;
      isLastSongNotifier.value =
          sequenceState.effectiveSequence.length ==
          sequenceState.currentIndex + 1;
    });
  }

  void _listenForChangesInLoopMode() {
    _audioPlayer.loopModeStream.listen((loopMode) {
      loopModeNotifier.value = loopMode;
    });
  }

  void play() {
    _audioPlayer.play();
  }

  void pause() {
    _audioPlayer.pause();
  }

  void seek(Duration position, {int? index}) {
    _audioPlayer.seek(position, index: index);
  }

  void previous() {
    _audioPlayer.seekToPrevious();
  }

  void next() {
    _audioPlayer.seekToNext();
  }

  void cycleLoopMode() {
    final currentLoopMode = loopModeNotifier.value;
    if (currentLoopMode == LoopMode.off) {
      setLoopMode(LoopMode.one);
    } else if (currentLoopMode == LoopMode.one) {
      setLoopMode(LoopMode.all);
    } else {
      setLoopMode(LoopMode.off);
    }
  }

  void setLoopMode(LoopMode loopMode) {
    _audioPlayer.setLoopMode(loopMode);
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
