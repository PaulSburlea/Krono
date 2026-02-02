import 'package:drift/drift.dart';

import '../database/database.dart';
import 'logger_service.dart';

/// A utility to synchronize the activity history from existing journal entries.
///
/// This function is designed to be run during app initialization. It ensures that
/// users migrating from an older app version (before the `ActivityLog` table
/// existed) have their past entries correctly reflected in the new activity log,
/// preserving their historical streak data.
Future<void> syncActivityLogFromEntries(AppDatabase db) async {
  try {
    Logger.info('Starting sync of existing entries to activity log...');

    // 1. Retrieve all existing journal entries.
    final entries = await db.select(db.dayEntries).get();

    if (entries.isEmpty) {
      Logger.info('No existing entries to sync. Activity log is up to date.');
      return;
    }

    // 2. Extract unique dates, ignoring the time component, to prevent duplicates.
    final uniqueDates = entries
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet();

    Logger.debug('Found ${uniqueDates.length} unique dates to sync.');

    // 3. Insert all unique dates into the ActivityLog table using a batch for performance.
    // The `insertOrIgnore` mode gracefully handles any dates that might already exist.
    await db.batch((batch) {
      for (final date in uniqueDates) {
        batch.insert(
          db.activityLog,
          ActivityLogCompanion.insert(date: date),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });

    Logger.info('Successfully synced activity log from existing entries.');
  } catch (e, stack) {
    // Log the error but do not rethrow, as this is a non-critical background
    // task and should not block the application from starting.
    Logger.error('Failed to sync activity log from entries', e, stack);
  }
}