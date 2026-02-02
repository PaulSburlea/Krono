import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import '../utils/logger_service.dart';
import '../utils/thumbnail/thumbnail_cleanup.dart';

/// The key used to store the last cleanup timestamp in [SharedPreferences].
const _kLastThumbCleanupKey = 'last_thumbs_cleanup_epoch';

/// Orchestrates periodic maintenance tasks for the application's filesystem.
///
/// Checks the last execution timestamp against the specified [daysThreshold] to
/// prevent redundant I/O operations on every app launch. This is a background
/// maintenance task to ensure the app remains performant.
Future<void> runCleanupIfNeeded({
  required AppDatabase db,
  required SharedPreferences prefs,
  int daysThreshold = 30,
}) async {
  try {
    final lastEpoch = prefs.getInt(_kLastThumbCleanupKey) ?? 0;
    final last = DateTime.fromMillisecondsSinceEpoch(lastEpoch);
    final now = DateTime.now();

    if (lastEpoch == 0 || now.difference(last).inDays >= daysThreshold) {
      Logger.info('Starting scheduled thumbnail cleanup...');
      await cleanupOrphanThumbnails(db);
      await prefs.setInt(_kLastThumbCleanupKey, now.millisecondsSinceEpoch);
      Logger.info('Thumbnail cleanup completed successfully.');
    }
  } catch (e, stack) {
    Logger.error('Failed to run scheduled cleanup task', e, stack);
  }
}