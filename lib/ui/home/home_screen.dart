import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:scripturesongs/models/catalog_models.dart';
import 'package:scripturesongs/services/api_service.dart';
import 'package:scripturesongs/services/download_manager.dart';
import 'package:scripturesongs/services/service_locator.dart';
import 'package:scripturesongs/services/audio_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:scripturesongs/ui/about/about_screen.dart';
import 'package:scripturesongs/ui/downloads/downloads_screen.dart';
import 'package:scripturesongs/ui/home/home_manager.dart';
import 'package:scripturesongs/ui/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _homeManager = getIt<HomeManager>();
  final _audioManager = getIt<AudioManager>();
  final _downloadManager = getIt<DownloadManager>();
  final ScrollController _scrollController = ScrollController();
  final double _itemHeight = 72.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioManager.currentSongNotifier.addListener(_scrollToCurrentSong);
    getIt<DownloadManager>().errorNotifier.addListener(_showErrorSnackBar);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioManager.currentSongNotifier.removeListener(_scrollToCurrentSong);
    _scrollController.dispose();
    getIt<DownloadManager>().errorNotifier.removeListener(_showErrorSnackBar);
    super.dispose();
  }

  void _showErrorSnackBar() {
    final errorMsg = getIt<DownloadManager>().errorNotifier.value;
    if (errorMsg != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
      // Reset the error so it can fire again if needed
      getIt<DownloadManager>().errorNotifier.value = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _homeManager.saveCurrentState();
    }
  }

  void _scrollToCurrentSong() {
    final mediaItem = _audioManager.currentSongNotifier.value;
    if (mediaItem == null) return;

    final currentList = _homeManager.currentTracks.value;
    if (currentList.isEmpty) return;

    final index = currentList.indexWhere((t) => t.id == mediaItem.id);

    if (index != -1 && _scrollController.hasClients) {
      final double rawPosition = index * _itemHeight;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final targetPosition = rawPosition.clamp(0.0, maxScroll);

          _scrollController.animateTo(
            targetPosition,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<String>(
          valueListenable: _homeManager.collectionTitle,
          builder: (context, title, _) => Text(title),
        ),
      ),
      drawer: _buildDrawer(),
      body: ValueListenableBuilder<List<Track>>(
        valueListenable: _homeManager.currentTracks,
        builder: (context, tracks, _) {
          return ValueListenableBuilder<Map<String, TrackStatus>>(
            valueListenable: _downloadManager.trackStatuses,
            builder: (context, statuses, _) {
              // Show player if collection is empty, OR if any track is downloaded/downloading.
              final showPlayer =
                  tracks.isEmpty ||
                  tracks.any((t) {
                    final status = statuses[t.id] ?? TrackStatus.notDownloaded;
                    return status != TrackStatus.notDownloaded;
                  });

              return Column(
                children: [
                  if (showPlayer) _buildPlayer() else _buildDownloadAllHeader(),

                  Expanded(child: _buildTrackListWithData(tracks, statuses)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDownloadAllHeader() {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_download_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No songs downloaded',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Download all songs'),
            onPressed: () {
              _homeManager.downloadAllCurrent();
            },
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
            builder: (_, item, _) {
              return Column(
                children: [
                  Text(
                    item?.title ?? 'Ready to Play',
                    style: Theme.of(context).textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item?.artist ?? 'Select a track below',
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
                onPressed: _homeManager.playPrevious,
                icon: const Icon(Icons.skip_previous),
              ),
              ValueListenableBuilder<ButtonState>(
                valueListenable: _audioManager.playButtonNotifier,
                builder: (_, state, _) {
                  if (state == ButtonState.loading) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    );
                  }
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
                onPressed: _homeManager.playNext,
                icon: const Icon(Icons.skip_next),
              ),
              ValueListenableBuilder<MediaItem?>(
                valueListenable: _audioManager.currentSongNotifier,
                builder: (context, currentItem, _) {
                  return IconButton(
                    icon: const Icon(Icons.share_outlined),
                    color: currentItem != null
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Colors.grey,
                    onPressed: currentItem != null
                        ? _homeManager.shareCurrentTrack
                        : null,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackListWithData(
    List<Track> tracks,
    Map<String, TrackStatus> statuses,
  ) {
    if (tracks.isEmpty) {
      return const Center(child: Text("No tracks found."));
    }

    return ValueListenableBuilder<MediaItem?>(
      valueListenable: _audioManager.currentSongNotifier,
      builder: (context, currentMediaItem, _) {
        return ListView.builder(
          controller: _scrollController,
          itemCount: tracks.length,
          itemExtent: _itemHeight,
          itemBuilder: (context, index) {
            final track = tracks[index];
            final isPlaying = currentMediaItem?.id == track.id;
            final status = statuses[track.id] ?? TrackStatus.notDownloaded;

            return ListTile(
              title: Text(
                '${index + 1}. ${track.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                  color: isPlaying
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              subtitle: Text(
                track.reference,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              selected: isPlaying,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status == TrackStatus.downloading)
                    ValueListenableBuilder<Map<String, double>>(
                      valueListenable: _downloadManager.trackProgresses,
                      builder: (context, progresses, _) {
                        final progress = progresses[track.id] ?? 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 3,
                            ),
                          ),
                        );
                      },
                    ),

                  ValueListenableBuilder<List<Track>>(
                    valueListenable: _homeManager.favoritesNotifier,
                    builder: (_, favs, _) {
                      final isFav = _homeManager.isFavorite(track);
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                        ),
                        onPressed: () => _homeManager.toggleFavorite(track),
                      );
                    },
                  ),
                ],
              ),
              onTap: () => _homeManager.playTrack(track),
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 200,
      child: FutureBuilder<Catalog>(
        future: getIt<ApiService>().getCatalog(),
        builder: (context, snapshot) {
          final List<Widget> menuItems = [
            Image.asset(
              'assets/logo.jpg',
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ),
          ];

          if (snapshot.hasData) {
            for (var collection in snapshot.data!.collections) {
              menuItems.add(
                ListTile(
                  title: Text(collection.title),
                  onTap: () {
                    Navigator.pop(context);
                    _homeManager.loadCollection(collection.id);
                  },
                ),
              );
            }
          } else {
            menuItems.add(
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          menuItems.addAll([
            ListTile(
              title: const Text('Favorites'),
              onTap: () {
                Navigator.pop(context);
                _homeManager.loadCollection('favorites');
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Downloads'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                );
              },
            ),
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
          ]);

          return ListView(padding: EdgeInsets.zero, children: menuItems);
        },
      ),
    );
  }
}
