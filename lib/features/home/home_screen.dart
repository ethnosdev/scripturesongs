import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:scripturesongs/core/service_locator.dart';
import 'package:scripturesongs/core/services/audio_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:scripturesongs/features/about/about_screen.dart';
import 'package:scripturesongs/features/home/home_manager.dart';
import 'package:scripturesongs/features/settings/settings_screen.dart';
import 'package:scripturesongs/models/song_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _homeManager = locator<HomeManager>();
  final _audioManager = locator<AudioManager>();

  @override
  void initState() {
    super.initState();
    _homeManager.loadSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scripture Songs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // UPDATED: Increased flex to 4 to give player more room (40% of screen)
          _buildPlayer(),
          // UPDATED: Decreased list flex to 6 (60% of screen)
          Expanded(flex: 6, child: _buildSongList()),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    return Container(
      height: 200,
      // UPDATED: Reduced vertical padding slightly to prevent overflow on small screens
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Metadata Section
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder(
                  valueListenable: _audioManager.currentSongNotifier,
                  builder: (_, song, _) {
                    return Text(
                      song?.title ?? '',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                const SizedBox(height: 4.0),
                ValueListenableBuilder(
                  valueListenable: _audioManager.currentSongNotifier,
                  builder: (_, song, __) {
                    return Text(
                      song?.artist ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ],
            ),
          ),

          // Progress Bar
          ValueListenableBuilder<ProgressBarState>(
            valueListenable: _homeManager.progressNotifier,
            builder: (_, progressBarState, __) {
              return ProgressBar(
                progress: progressBarState.current,
                buffered: progressBarState.buffered,
                total: progressBarState.total,
                onSeek: _audioManager.seek,
                timeLabelLocation: TimeLabelLocation.sides,
              );
            },
          ),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ValueListenableBuilder<LoopMode>(
                valueListenable: _audioManager.loopModeNotifier,
                builder: (context, loopMode, child) {
                  return IconButton(
                    onPressed: _audioManager.cycleLoopMode,
                    icon: Icon(
                      loopMode == LoopMode.off
                          ? Icons.repeat
                          : loopMode == LoopMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                    ),
                  );
                },
              ),
              IconButton(
                onPressed: _audioManager.previous,
                icon: const Icon(Icons.skip_previous),
              ),
              ValueListenableBuilder<ButtonState>(
                valueListenable: _audioManager.playButtonNotifier,
                builder: (_, buttonState, __) {
                  switch (buttonState) {
                    case ButtonState.loading:
                      return const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    case ButtonState.paused:
                      return IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: _audioManager.play,
                        iconSize: 32, // Slightly larger play button
                      );
                    case ButtonState.playing:
                      return IconButton(
                        icon: const Icon(Icons.pause),
                        onPressed: _audioManager.pause,
                        iconSize: 32,
                      );
                  }
                },
              ),
              IconButton(
                onPressed: _audioManager.next,
                icon: const Icon(Icons.skip_next),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Implement more menu
                },
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    return ValueListenableBuilder<List<Song>>(
      valueListenable: _homeManager.songs,
      builder: (context, songs, _) {
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(songs[index].title),
              subtitle: Text(songs[index].reference),
              trailing: IconButton(
                onPressed: () {
                  // TODO: Implement more menu
                },
                icon: const Icon(Icons.more_vert),
              ),
              onTap: () {
                _audioManager.seek(Duration.zero, index: index);
                _audioManager.play();
              },
            );
          },
        );
      },
    );
  }
}
