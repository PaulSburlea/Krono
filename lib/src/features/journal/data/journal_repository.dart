import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/utils/image_service.dart';
import '../../../core/utils/logger_service.dart';
import '../../../core/utils/thumbnail/thumbnail_service.dart';
import 'models/journal_entry.dart';

/// Provides a singleton instance of the [ImageService].
final imageServiceProvider = Provider<ImageService>((ref) => ImageService());

/// Provides a singleton instance of the [ThumbnailService].
final thumbnailServiceProvider = Provider<ThumbnailService>((ref) => ThumbnailService());

/// Provides the [JournalRepository] for interacting with journal data.
///
/// This provider acts as the single source of truth for journal operations,
/// combining database access with file system management.
final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(
    db: ref.watch(databaseProvider),
    imageService: ref.watch(imageServiceProvider),
    thumbnailService: ref.watch(thumbnailServiceProvider),
  );
});

/// Manages the data persistence and file handling for Journal Entries.
///
/// This repository abstracts the complexity of coordinating SQLite database
/// operations (via Drift) with physical file management (images and thumbnails).
class JournalRepository {
  final AppDatabase _db;
  final ImageService _imageService;
  final ThumbnailService _thumbnailService;

  /// Creates a [JournalRepository] with required dependencies.
  JournalRepository({
    required AppDatabase db,
    required ImageService imageService,
    required ThumbnailService thumbnailService,
  })  : _db = db,
        _imageService = imageService,
        _thumbnailService = thumbnailService;

  /// Persists a new journal entry and handles image optimization.
  ///
  /// This method performs three key steps:
  /// 1. Optimizes the temporary image file to WebP format for permanent storage.
  /// 2. Generates a thumbnail for performance optimization in lists.
  /// 3. Inserts the metadata and file paths into the database.
  ///
  /// Throws an [Exception] if the primary image processing fails.
  Future<void> addEntry(JournalEntry entry, String tempPath, {bool deleteSource = false}) async {
    Logger.info('Attempting to add new journal entry...');

    // 1. Process the main image (WebP, quality 85)
    // Returns the PERMANENT path (e.g., .../krono_123.webp)
    final optimizedPath = await _imageService.processAndOptimizeImage(tempPath, deleteSource: deleteSource);

    if (optimizedPath == null) {
      const error = "Failed to process and optimize the primary image.";
      Logger.error(error, Exception(error), StackTrace.current);
      throw Exception(error);
    }

    // 2. Generate the thumbnail from the PERMANENT path
    final thumbPath = await _thumbnailService.generateThumbnail(optimizedPath, width: 300);

    // 3. Save to database
    final companion = entry.toDriftCompanion().copyWith(
      photoPath: Value(optimizedPath),
      thumbnailPath: Value(thumbPath),
      date: Value(entry.date),
    );

    await _db.into(_db.dayEntries).insert(companion);
    Logger.info('Journal entry successfully added to database.');
  }

  /// Updates an existing journal entry, handling potential image replacement.
  ///
  /// If [newTempPath] is provided, the old image and thumbnail are deleted from
  /// the filesystem, and new assets are generated and linked.
  Future<void> updateEntry(JournalEntry entry, {String? newTempPath, bool deleteSource = false}) async {
    if (entry.id == null) {
      throw Exception('Entry ID is required for update operations.');
    }

    Logger.info('Updating journal entry ID: ${entry.id}');

    final existingRow = await (_db.select(_db.dayEntries)
      ..where((t) => t.id.equals(entry.id!)))
        .getSingleOrNull();

    if (existingRow == null) {
      throw Exception('Entry not found in database.');
    }

    String finalPhotoPath = existingRow.photoPath;
    String? finalThumbPath = existingRow.thumbnailPath;

    // Check if the user has replaced the photo
    if (newTempPath != null && newTempPath != existingRow.photoPath) {
      Logger.debug('Image replacement detected. Processing new image...');

      // A. Process the new image
      final processed =
      await _imageService.processAndOptimizeImage(newTempPath, deleteSource: deleteSource);

      if (processed != null) {
        // B. Cleanup old files to prevent storage bloat
        await _imageService.deleteFile(existingRow.photoPath);
        if (existingRow.thumbnailPath != null) {
          await _imageService.deleteFile(existingRow.thumbnailPath!);
        }

        finalPhotoPath = processed;

        // C. Generate new thumbnail
        finalThumbPath = await _thumbnailService.generateThumbnail(processed, width: 300);
      }
    }

    final companion = entry.toDriftCompanion().copyWith(
      photoPath: Value(finalPhotoPath),
      thumbnailPath: Value(finalThumbPath),
    );

    await (_db.update(_db.dayEntries)..where((t) => t.id.equals(entry.id!)))
        .write(companion);
    Logger.info('Journal entry ID ${entry.id} updated successfully.');
  }

  /// Permanently removes a journal entry and its associated media files.
  Future<void> deleteEntry(JournalEntry entry) async {
    Logger.info('Deleting journal entry ID: ${entry.id}');

    // Remove physical files
    await _imageService.deleteFile(entry.photoPath);
    if (entry.thumbnailPath != null) {
      await _imageService.deleteFile(entry.thumbnailPath!);
    }

    // Remove database record
    if (entry.id != null) {
      await (_db.delete(_db.dayEntries)..where((t) => t.id.equals(entry.id!)))
          .go();
    }
  }

  /// Retrieves all journal entries sorted by date (newest first).
  Future<List<JournalEntry>> getAllEntries() async {
    final rows = await (_db.select(_db.dayEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();

    return rows.map((row) => JournalEntry.fromDrift(row)).toList();
  }

  /// Destructive operation: Deletes ALL journal data and files.
  ///
  /// Use with caution. This wipes the `dayEntries` table and clears the
  /// associated images from the filesystem.
  Future<void> deleteAllData() async {
    Logger.warning('Initiating complete data wipe (deleteAllData).');

    final rows = await _db.select(_db.dayEntries).get();
    for (final r in rows) {
      await _imageService.deleteFile(r.photoPath);
      if (r.thumbnailPath != null) {
        await _imageService.deleteFile(r.thumbnailPath!);
      }
    }
    await _db.delete(_db.dayEntries).go();
    Logger.info('All journal data and files have been deleted.');
  }
}