import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:scripturesongs/services/service_locator.dart';
import 'package:scripturesongs/services/audio_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:scripturesongs/ui/about/about_screen.dart';
import 'package:scripturesongs/ui/home/home_manager.dart';
import 'package:scripturesongs/ui/settings/settings_screen.dart';
import 'package:scripturesongs/models/song.dart';

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              } else if (value == 'about') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem<String>(value: 'about', child: Text('About')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPlayer(),
          Expanded(flex: 6, child: _buildSongList()),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    return Container(
      height: 200,
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
                  builder: (context, song, _) {
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
            builder: (context, progressBarState, _) {
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
                builder: (context, buttonState, _) {
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
        return ValueListenableBuilder<MediaItem?>(
          valueListenable: _audioManager.currentSongNotifier,
          builder: (context, currentMediaItem, _) {
            return ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final isPlaying = currentMediaItem?.id == song.id;
                return ListTile(
                  title: Text(
                    song.title,
                    style: TextStyle(
                      fontWeight: isPlaying
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(song.reference),
                  selected: isPlaying,
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),

                    onSelected: (value) {
                      if (value == 'download') {
                        _handleDownload(context, song);
                      } else if (value == 'share') {
                        _homeManager.shareSong(song);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'download',
                            child: ListTile(
                              leading: Icon(Icons.download),
                              title: Text('Download'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'share',
                            child: ListTile(
                              leading: Icon(Icons.share),
                              title: Text('Share'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
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
      },
    );
  }

  Future<void> _handleDownload(BuildContext context, Song song) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Downloading "${song.title}"...')));

    try {
      final message = await _homeManager.downloadSong(song);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
