import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:krono/src/core/utils/thumbnail/thumbnail_utils.dart';

import '../../database/database.dart';
import '../logger_service.dart';

/// Orchestrates the background generation of thumbnails for legacy journal entries.
///
/// This migration utility identifies entries missing a [DayEntry.thumbnailPath] and
/// processes them using a pool of workers to avoid blocking the main thread.
///
/// [concurrency] defines the number of parallel workers (recommended 2-4 for mobile).
/// [targetWidth] sets the resolution for the generated thumbnails.
Future<void> runBackgroundThumbnailMigration(
    AppDatabase db, {
      int concurrency = 3,
      int targetWidth = 300,
    }) async {
  try {
    final rows = await (db.select(db.dayEntries)
      ..where((t) => t.thumbnailPath.isNull() | t.thumbnailPath.equals('')))
        .get();

    if (rows.isEmpty) {
      Logger.info('All entries have thumbnails. Migration not required.');
      return;
    }

    Logger.info(
      'Starting thumbnail migration for ${rows.length} legacy images (concurrency: $concurrency).',
    );

    // Create a thread-safe queue from the retrieved rows.
    final queue = List.of(rows);
    final workers = <Future<void>>[];

    for (int w = 0; w < concurrency; w++) {
      workers.add(Future(() async {
        while (true) {
          if (queue.isEmpty) break;
          final row = queue.removeLast();

          try {
            final photoPath = row.photoPath;
            if (photoPath.isEmpty) continue;

            final file = File(photoPath);
            if (!file.existsSync()) {
              Logger.debug('Source file missing for entry ID ${row.id}: $photoPath');
              continue;
            }

            // Offload the heavy image processing to a separate isolate via compute.
            final thumbPath = await compute(
              _generateThumbCompute,
              {'path': photoPath, 'width': targetWidth},
            );

            // Persist the new thumbnail path to the database.
            await (db.update(db.dayEntries)..where((t) => t.id.equals(row.id)))
                .write(
              DayEntriesCompanion(
                thumbnailPath: Value(thumbPath),
              ),
            );

            Logger.debug('Thumbnail generated successfully for entry ID: ${row.id}');
          } catch (e, stack) {
            Logger.error('Failed to migrate thumbnail for entry ID: ${row.id}', e, stack);
          }

          // Brief delay to prevent event loop starvation during intensive processing.
          await Future.delayed(const Duration(milliseconds: 40));
        }
      }));
    }

    await Future.wait(workers);
    Logger.info('Thumbnail migration completed successfully.');
  } catch (e, stack) {
    Logger.error('Critical failure during thumbnail migration process', e, stack);
  }
}

/// Helper function executed within a [compute] isolate to generate a thumbnail.
///
/// Expects a [Map] containing the 'path' (String) and 'width' (int).
Future<String> _generateThumbCompute(Map<String, dynamic> args) async {
  final String path = args['path'] as String;
  final int width = args['width'] as int? ?? 300;
  return await generateThumbnail(path, width: width);
}