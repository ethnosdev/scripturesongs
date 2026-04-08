import 'package:flutter/material.dart';
import 'package:scripturesongs/models/catalog_models.dart';
import 'package:scripturesongs/services/api_service.dart';
import 'package:scripturesongs/services/download_manager.dart';
import 'package:scripturesongs/services/service_locator.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = getIt<ApiService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: FutureBuilder<Catalog>(
        future: apiService.getCatalog(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final catalog = snapshot.data!;
          return ListView.builder(
            itemCount: catalog.collections.length,
            itemBuilder: (context, index) {
              return _CollectionDownloadTile(
                collection: catalog.collections[index],
              );
            },
          );
        },
      ),
    );
  }
}

class _CollectionDownloadTile extends StatelessWidget {
  final Collection collection;
  const _CollectionDownloadTile({required this.collection});

  Future<void> _confirmDeleteAll(
    BuildContext context,
    DownloadManager manager,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Downloads'),
          content: Text(
            'Are you sure you want to delete all downloaded songs for ${collection.title}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      manager.deleteCollection(collection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadManager = getIt<DownloadManager>();

    return ExpansionTile(
      title: Text(
        collection.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Download All'),
                  onPressed: () =>
                      downloadManager.downloadCollection(collection),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete All'),
                  onPressed: () => _confirmDeleteAll(context, downloadManager),
                ),
              ),
            ],
          ),
        ),
        ...collection.tracks.map((track) => _TrackDownloadTile(track: track)),
      ],
    );
  }
}

class _TrackDownloadTile extends StatelessWidget {
  final Track track;
  const _TrackDownloadTile({required this.track});

  @override
  Widget build(BuildContext context) {
    final downloadManager = getIt<DownloadManager>();

    return ValueListenableBuilder<Map<String, TrackStatus>>(
      valueListenable: downloadManager.trackStatuses,
      builder: (context, statuses, _) {
        final status = statuses[track.id] ?? TrackStatus.notDownloaded;
        return ListTile(
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(track.reference),
          trailing: _buildAction(status, downloadManager, context),
        );
      },
    );
  }

  Widget _buildAction(
    TrackStatus status,
    DownloadManager manager,
    BuildContext context,
  ) {
    if (status == TrackStatus.downloading) {
      return ValueListenableBuilder<Map<String, double>>(
        valueListenable: manager.trackProgresses,
        builder: (context, progresses, _) {
          final progress = progresses[track.id] ?? 0.0;
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(value: progress, strokeWidth: 3),
            ),
          );
        },
      );
    } else if (status == TrackStatus.notDownloaded) {
      return IconButton(
        icon: const Icon(Icons.cloud_download_outlined),
        onPressed: () => manager.downloadTrack(track),
      );
    } else {
      return IconButton(
        icon: Icon(Icons.delete_outline),
        onPressed: () => manager.deleteTrack(track),
      );
    }
  }
}
