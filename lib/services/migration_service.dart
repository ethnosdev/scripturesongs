import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scripturesongs/services/api_service.dart';
import 'package:scripturesongs/services/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// This can be deleted after a time.
class MigrationService {
  static const String _migrationKey = 'has_migrated_v1_to_v2_ios';

  // Maps the old numeric IDs to the new string IDs
  static const Map<String, String> _oldToNewIdMap = {
    '1': 'phil_1_grace_peace',
    '2': 'phil_1_in_every_prayer',
    '3': 'phil_1_by_my_chains',
    '4': 'phil_1_live_is_christ',
    '5': 'phil_1_side_by_side',
    '6': 'phil_2_in_humility',
    '7': 'phil_2_let_this_mind',
    '8': 'phil_2_god_works',
    '9': 'phil_2_blameless',
    '10': 'phil_2_proven_worth',
    '11': 'phil_2_fellow_soldier',
    '12': 'phil_3_know_christ',
    '13': 'phil_3_press_on',
    '14': 'phil_3_citizenship',
    '15': 'phil_4_joy_and_crown',
    '16': 'phil_4_peace_of_god',
    '17': 'phil_4_think_on_these',
    '18': 'phil_4_content',
    '19': 'phil_4_supply_needs',
    '20': 'phil_4_greet_saints',
  };

  Future<void> runMigration() async {
    // 1. Only run this migration on iOS
    if (!Platform.isIOS) return;

    final prefs = await SharedPreferences.getInstance();
    final hasMigrated = prefs.getBool(_migrationKey) ?? false;

    if (hasMigrated) return;

    try {
      // 2. Do not migrate favorites. Just delete them.
      if (prefs.containsKey('favorite_song_ids')) {
        await prefs.remove('favorite_song_ids');
      }

      final dir = await getApplicationDocumentsDirectory();
      final existingFiles = dir.listSync().whereType<File>().toList();

      // Look for files matching the old pattern (e.g., "1_Graceandpeacetoyou.mp3")
      final oldFiles = existingFiles.where((file) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        return fileName.contains('_') && fileName.endsWith('.mp3');
      }).toList();

      // 3. If there are no old files, this is a new install (or already clean).
      if (oldFiles.isEmpty) {
        await prefs.setBool(_migrationKey, true);
        return;
      }

      debugPrint('Starting iOS V1 to V2 File Migration...');

      final apiService = getIt<ApiService>();
      final catalog = await apiService.getCatalog();

      // 4. Migrate the files
      for (var file in oldFiles) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        final oldId = fileName.split('_').first;

        if (_oldToNewIdMap.containsKey(oldId)) {
          final newTrackId = _oldToNewIdMap[oldId];

          // Find the version ID for this new track from the catalog
          String? targetVersionId;
          for (var collection in catalog.collections) {
            try {
              final track = collection.tracks.firstWhere(
                (t) => t.id == newTrackId,
              );
              targetVersionId = track.versions.first.id;
              break;
            } catch (_) {}
          }

          if (targetVersionId != null) {
            final newFile = File('${dir.path}/$targetVersionId.mp3');

            // Rename the file if the new one doesn't already exist
            if (await newFile.exists()) {
              await file.delete();
            } else {
              await file.rename(newFile.path);
            }
          } else {
            // Delete old file if we couldn't match it, to free up space
            await file.delete();
          }
        } else {
          // Delete old file if it doesn't exist in our map at all
          await file.delete();
        }
      }

      // Mark migration as complete
      await prefs.setBool(_migrationKey, true);
      debugPrint('iOS V1 to V2 Migration complete!');
    } catch (e) {
      debugPrint('Migration error: $e');
    }
  }
}
