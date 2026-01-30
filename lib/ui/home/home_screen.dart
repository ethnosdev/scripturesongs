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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scripture Songs')),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildTopArea(), // Dynamic: Player OR Download Button
          Expanded(child: _buildSongList()),
        ],
      ),
    );
  }

  Widget _buildTopArea() {
    return ValueListenableBuilder<CollectionStatus>(
      valueListenable: _homeManager.collectionStatus,
      builder: (context, status, child) {
        if (status == CollectionStatus.downloading) {
          return _buildDownloadingState();
        } else if (status == CollectionStatus.notDownloaded) {
          return _buildDownloadPrompt();
        } else if (status == CollectionStatus.downloaded) {
          return _buildPlayer();
        } else {
          return const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  Widget _buildDownloadPrompt() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "This album is not downloaded.",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _homeManager.downloadCurrentCollection(),
            icon: const Icon(Icons.download),
            label: const Text("Download Album & Play"),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingState() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ValueListenableBuilder<String>(
            valueListenable: _homeManager.downloadMessage,
            builder: (_, msg, __) => Text(msg, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<double>(
            valueListenable: _homeManager.downloadProgress,
            builder: (_, val, __) => LinearProgressIndicator(value: val),
          ),
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
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Song Info
          ValueListenableBuilder<MediaItem?>(
            valueListenable: _audioManager.currentSongNotifier,
            builder: (_, item, __) {
              return Column(
                children: [
                  Text(
                    item?.title ?? 'Ready to Play',
                    style: Theme.of(context).textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item?.artist ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
          // Progress Bar
          ValueListenableBuilder<ProgressBarState>(
            valueListenable: _homeManager.progressNotifier,
            builder: (context, state, _) {
              return ProgressBar(
                progress: state.current,
                buffered: state.buffered,
                total: state.total,
                onSeek: _audioManager.seek,
              );
            },
          ),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Loop Mode
              ValueListenableBuilder<LoopMode>(
                valueListenable: _audioManager.loopModeNotifier,
                builder: (context, loopMode, _) {
                  final icon = loopMode == LoopMode.one
                      ? Icons.repeat_one
                      : Icons.repeat;
                  return IconButton(
                    icon: Icon(icon),
                    color: loopMode == LoopMode.off
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
                    onPressed: _audioManager.cycleLoopMode,
                  );
                },
              ),
              IconButton(
                onPressed: _audioManager.previous,
                icon: const Icon(Icons.skip_previous),
              ),
              ValueListenableBuilder<ButtonState>(
                valueListenable: _audioManager.playButtonNotifier,
                builder: (_, state, __) {
                  if (state == ButtonState.loading)
                    return const CircularProgressIndicator();
                  final isPlaying = state == ButtonState.playing;
                  return IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 40,
                    onPressed: isPlaying
                        ? _audioManager.pause
                        : _audioManager.play,
                  );
                },
              ),
              IconButton(
                onPressed: _audioManager.next,
                icon: const Icon(Icons.skip_next),
              ),
              // Shuffle
              // Menu (Export / Share / Favorite)
              ValueListenableBuilder<MediaItem?>(
                valueListenable: _audioManager.currentSongNotifier,
                builder: (context, mediaItem, _) {
                  final isEnabled = mediaItem != null;
                  return PopupMenuButton<String>(
                    enabled: isEnabled,
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (!isEnabled) return;
                      try {
                        final song = _homeManager
                            .songs
                            .value[_homeManager.currentCollection.value]!
                            .firstWhere((s) => s.id == mediaItem.id);

                        if (value == 'share') {
                          _homeManager.shareSong(song);
                        }
                      } catch (e) {
                        print('Song not found for menu action: $e');
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          // Consolidated into one option
                          const PopupMenuItem<String>(
                            value: 'share',
                            child: ListTile(
                              leading: Icon(Icons.share),
                              title: Text('Share / Save'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    return ValueListenableBuilder<String>(
      valueListenable: _homeManager.currentCollection,
      builder: (context, collection, _) {
        return ValueListenableBuilder<Map<String, List<Song>>>(
          valueListenable: _homeManager.songs,
          builder: (context, songsMap, _) {
            final songList = songsMap[collection] ?? [];
            return _buildSongListView(songList);
          },
        );
      },
    );
  }

  Widget _buildSongListView(List<Song> songList) {
    return ValueListenableBuilder<MediaItem?>(
      valueListenable: _audioManager.currentSongNotifier,
      builder: (context, currentMediaItem, _) {
        return ListView.builder(
          itemCount: songList.length,
          itemBuilder: (context, index) {
            final song = songList[index];
            final isPlaying = currentMediaItem?.id == song.id;

            return ListTile(
              title: Text(
                '${index + 1}. ${song.title}', // Simplified index display
                style: TextStyle(
                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                  color: isPlaying
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              subtitle: Text(song.reference),
              selected: isPlaying,
              trailing: _homeManager.currentCollection.value != 'favorites'
                  ? ValueListenableBuilder<List<Song>>(
                      valueListenable: _homeManager.favoritesNotifier,
                      builder: (_, favs, __) {
                        final isFav = _homeManager.isFavorite(song);
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                          ),
                          onPressed: () => _homeManager.toggleFavorite(song),
                        );
                      },
                    )
                  : null,
              onTap: () {
                // Only allow playing if album is downloaded
                if (_homeManager.collectionStatus.value ==
                    CollectionStatus.downloaded) {
                  _audioManager.seekToStats(index);
                  _audioManager.play();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please download the album first'),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 200,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Image.asset(
            'assets/logo.jpg',
            height: 200,
            width: 200,
            fit: BoxFit.cover,
          ),
          ListTile(
            title: const Text('Philippians'),
            onTap: () {
              Navigator.pop(context);
              _homeManager.loadCollection('philippians');
            },
          ),
          ListTile(
            title: const Text('Jude'),
            onTap: () {
              Navigator.pop(context);
              _homeManager.loadCollection('jude');
            },
          ),
          ListTile(
            title: const Text('Favorites'),
            onTap: () {
              Navigator.pop(context);
              _homeManager.loadCollection('favorites');
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
