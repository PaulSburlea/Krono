import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../database/database.dart';
import '../logger_service.dart';

/// Scans the local storage for thumbnail files that are no longer referenced in the database.
///
/// This maintenance task prevents storage bloat by identifying and removing cached
/// images that remain on the filesystem after their corresponding [DayEntry] has
/// been deleted or modified.
Future<void> cleanupOrphanThumbnails(AppDatabase db) async {
  try {
    Logger.info('Starting orphan thumbnail cleanup process.');

    // 1. Collect all thumbnail paths currently registered in the database.
    final rows = await db.select(db.dayEntries).get();
    final used = rows
        .map((r) => r.thumbnailPath)
        .where((path) => path != null && path.isNotEmpty)
        .cast<String>()
        .toSet();

    Logger.debug('Found ${used.length} thumbnails currently referenced in database.');

    // 2. Locate the thumbnails directory.
    final dir = await getApplicationSupportDirectory();
    final thumbsDir = Directory(p.join(dir.path, 'thumbnails'));

    if (!await thumbsDir.exists()) {
      Logger.info('Thumbnails directory does not exist. Skipping cleanup.');
      return;
    }

    // 3. Iterate through the filesystem and remove unreferenced files.
    int deletedCount = 0;
    await for (final entity in thumbsDir.list(recursive: false, followLinks: false)) {
      if (entity is File) {
        final filePath = entity.path;
        if (!used.contains(filePath)) {
          try {
            await entity.delete();
            deletedCount++;
            Logger.debug('Deleted orphan thumbnail: $filePath');
          } catch (e, stack) {
            // Log individual deletion failures as warnings to avoid halting the entire process.
            Logger.warning('Failed to delete specific orphan thumbnail: $filePath', e, stack);
          }
        }
      }
    }

    if (deletedCount > 0) {
      Logger.info('Cleanup completed. Removed $deletedCount orphan thumbnails.');
    } else {
      Logger.info('Cleanup completed. No orphan thumbnails were found.');
    }
  } catch (e, stack) {
    // Critical failures in the cleanup logic are reported to Crashlytics.
    Logger.error('Failed to complete orphan thumbnail cleanup', e, stack);
  }
}