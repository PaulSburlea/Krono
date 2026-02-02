import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../features/journal/data/journal_repository.dart';
import '../database/database.dart';
import 'logger_service.dart';

/// Provides a singleton instance of the [BackupService].
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref: ref);
});

// Helper functions for isolate-based JSON processing via `compute`.
List<Map<String, dynamic>> _serializeEntries(List<DayEntry> entries) =>
    entries.map((e) => e.toJson()).toList();
List<Map<String, dynamic>> _serializeAdjustments(
    List<StreakAdjustment> adjustments) =>
    adjustments.map((e) => e.toJson()).toList();
List<Map<String, dynamic>> _serializeActivityLogs(List<ActivityLogData> logs) =>
    logs.map((e) => e.toJson()).toList();
String _jsonStringify(dynamic data) => jsonEncode(data);
List<dynamic> _jsonParse(String data) => jsonDecode(data) as List<dynamic>;

/// A service that handles the creation and restoration of full application backups.
///
/// Orchestrates the collection of database records and media assets into a
/// compressed ZIP archive, ensuring data integrity across device migrations.
class BackupService {
  final Ref _ref;
  bool _isExporting = false;
  bool _isImporting = false;

  /// Creates an instance of the [BackupService].
  BackupService({required Ref ref}) : _ref = ref;

  /// Exports all user data into a single compressed `.zip` file.
  ///
  /// Gathers database tables and media files. Missing thumbnails are generated
  /// via [ThumbnailService] during the process.
  /// Returns `true` if the export was successful and saved.
  Future<bool> exportFullBackup(AppLocalizations l10n) async {
    if (_isExporting) {
      Logger.warning('Export already in progress, ignoring duplicate request');
      return false;
    }

    _isExporting = true;
    final requestId = DateTime.now().millisecondsSinceEpoch;
    Logger.info('Full backup export initiated. Request ID: $requestId');

    await Future.delayed(const Duration(milliseconds: 500));

    File? tempZipFile;
    try {
      final timestamp =
      DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final fileName = 'krono_backup_$timestamp.zip';
      final tempDir = await getTemporaryDirectory();
      final tempZipPath = p.join(tempDir.path, fileName);

      final encoder = ZipFileEncoder();
      encoder.create(tempZipPath);

      final db = _ref.read(databaseProvider);
      final thumbService = _ref.read(thumbnailServiceProvider);

      // 1. Serialize and add database tables
      final allEntries = await (db.select(db.dayEntries)
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();
      Logger.info('Backup: Found ${allEntries.length} entries to export');

      final dbJson = await compute(_serializeEntries, allEntries);
      final dbContent = await compute(_jsonStringify, dbJson);
      encoder.addArchiveFile(ArchiveFile(
          'database.json', dbContent.length, utf8.encode(dbContent)));

      final allAdjustments = await db.select(db.streakAdjustments).get();
      final adjJson = await compute(_serializeAdjustments, allAdjustments);
      final adjContent = await compute(_jsonStringify, adjJson);
      encoder.addArchiveFile(ArchiveFile(
          'adjustments.json', adjContent.length, utf8.encode(adjContent)));

      final allLogs = await db.select(db.activityLog).get();
      final logsJson = await compute(_serializeActivityLogs, allLogs);
      final logsContent = await compute(_jsonStringify, logsJson);
      encoder.addArchiveFile(ArchiveFile(
          'activity_log.json', logsContent.length, utf8.encode(logsContent)));

      // 2. Process and add media files
      int successfulPhotos = 0;
      int successfulThumbs = 0;
      final Set<String> addedFiles = {};

      for (final entry in allEntries) {
        final photoFile = File(entry.photoPath);

        if (entry.photoPath.isNotEmpty && await photoFile.exists()) {
          final photoName = p.basename(entry.photoPath);

          if (addedFiles.contains(photoName)) {
            Logger.warning('Duplicate photo detected: $photoName (entry ${entry.id})');
          } else {
            encoder.addFile(photoFile, 'media/$photoName');
            addedFiles.add(photoName);
            successfulPhotos++;
          }

          // Process thumbnail
          String? thumbPath = entry.thumbnailPath;
          File? thumbFile;

          if (thumbPath != null && thumbPath.isNotEmpty && thumbPath != entry.photoPath) {
            final tFile = File(thumbPath);
            if (await tFile.exists()) {
              thumbFile = tFile;
            } else {
              Logger.warning('Thumbnail file missing for entry ${entry.id}');
            }
          }

          // Generate thumbnail if missing
          if (thumbFile == null) {
            try {
              final newThumbPath = await thumbService.generateThumbnail(
                entry.photoPath,
                width: 300,
              );

              if (newThumbPath != null) {
                final newThumbFile = File(newThumbPath);
                if (await newThumbFile.exists()) {
                  thumbFile = newThumbFile;
                  thumbPath = newThumbPath;

                  await (db.update(db.dayEntries)
                    ..where((t) => t.id.equals(entry.id)))
                      .write(DayEntriesCompanion(
                      thumbnailPath: Value(newThumbPath)));
                }
              }
            } catch (e, stack) {
              Logger.warning('Failed to generate thumbnail for entry ${entry.id}', e, stack);
            }
          }

          // Add thumbnail to archive
          if (thumbFile != null && thumbPath != null) {
            final thumbName = p.basename(thumbPath);
            final photoBaseName = p.basename(entry.photoPath);

            if (addedFiles.contains(thumbName)) {
              Logger.warning('Duplicate thumbnail detected: $thumbName (entry ${entry.id})');
            } else if (thumbName != photoBaseName) {
              encoder.addFile(thumbFile, 'media/$thumbName');
              addedFiles.add(thumbName);
              successfulThumbs++;
            }
          }
        } else {
          Logger.warning('Photo file not found for entry ${entry.id}: ${entry.photoPath}');
        }
      }

      await Future.delayed(const Duration(milliseconds: 100));

      Logger.info('Backup: Added $successfulPhotos photos and $successfulThumbs thumbnails (${addedFiles.length} total files)');

      encoder.close();

      // Verify archive integrity
      tempZipFile = File(tempZipPath);
      final verifyArchive = ZipDecoder().decodeBytes(await tempZipFile.readAsBytes());
      final mediaFiles = verifyArchive.files.where((f) => f.name.startsWith('media/')).toList();

      if (mediaFiles.length != addedFiles.length) {
        Logger.error(
          'Archive verification failed: Expected ${addedFiles.length} files but found ${mediaFiles.length}',
          Exception('File count mismatch'),
          StackTrace.current,
        );
      } else {
        Logger.info('Backup: Archive verified successfully');
      }

      final Uint8List zipBytes = await tempZipFile.readAsBytes();

      final String? result = await FilePicker.platform.saveFile(
        dialogTitle: l10n.exportBackup,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['zip'],
        bytes: zipBytes,
      );

      final success = result != null;
      Logger.info('Backup export completed. Request ID: $requestId, Success: $success');
      return success;
    } catch (e, st) {
      Logger.error("Backup export failed. Request ID: $requestId", e, st);
      return false;
    } finally {
      _isExporting = false;
      if (tempZipFile != null && await tempZipFile.exists()) {
        await tempZipFile.delete();
      }
      await cleanupCache();
    }
  }

  /// Imports user data from a `.zip` archive, replacing current state.
  ///
  /// Supports both modern and legacy formats. Reconstructs absolute file paths
  /// to ensure media visibility on the current device.
  Future<bool> importFullBackup() async {
    if (_isImporting) {
      Logger.warning('Import already in progress, ignoring duplicate request');
      return false;
    }

    _isImporting = true;
    Logger.info('Full backup import initiated.');

    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
      if (result == null || result.files.single.path == null) return false;

      final zipPath = result.files.single.path!;
      final archive = ZipDecoder().decodeBytes(await File(zipPath).readAsBytes());

      final db = _ref.read(databaseProvider);
      await _ref.read(journalRepositoryProvider).deleteAllData();
      await db.delete(db.streakAdjustments).go();
      await db.delete(db.activityLog).go();

      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(appDir.path, 'media'));
      if (!await mediaDir.exists()) await mediaDir.create(recursive: true);

      final Map<String, String> oldToNewPathMap = {};

      // 1. Extract media assets
      for (final file in archive.files) {
        if (file.isFile && (file.name.contains('media/') || file.name.contains('images/'))) {
          final filename = p.basename(file.name.replaceAll('\\', '/'));
          final destPath = p.join(mediaDir.path, filename);
          await File(destPath).writeAsBytes(file.content as List<int>);
          oldToNewPathMap[filename] = destPath;
        }
      }

      Logger.info('Import: Extracted ${oldToNewPathMap.length} media files');

      // 2. Restore database records
      final dbFile = archive.findFile('database.json');
      if (dbFile != null) {
        final List<dynamic> dbJson = await compute(
            _jsonParse, utf8.decode(dbFile.content as List<int>));
        await db.batch((batch) {
          for (final entry in dbJson) {
            final photoName = p.basename(entry['photoPath']?.toString() ??
                entry['photo_path']?.toString() ?? '');
            final newPhotoPath = oldToNewPathMap[photoName] ?? '';

            final rawThumb = entry['thumbnailPath']?.toString() ??
                entry['thumbnail_path']?.toString();
            final newThumbPath = rawThumb != null ? oldToNewPathMap[p.basename(rawThumb)] : null;

            DateTime entryDate;
            final rawDate = entry['date'];
            entryDate = rawDate is int
                ? DateTime.fromMillisecondsSinceEpoch(rawDate)
                : DateTime.parse(rawDate.toString());

            batch.insert(db.dayEntries, DayEntriesCompanion.insert(
              date: entryDate,
              photoPath: newPhotoPath,
              thumbnailPath: Value(newThumbPath),
              moodRating: entry['moodRating'] ?? entry['mood_rating'] ?? 3,
              note: Value(entry['note']),
              location: Value(entry['location']),
              weatherTemp: Value(entry['weatherTemp'] ?? entry['weather_temp']),
              weatherIcon: Value(entry['weatherIcon'] ?? entry['weather_icon']),
            ));
          }
        });
        Logger.info('Import: Restored ${dbJson.length} entries');
        await _restoreAuxTables(archive, db);
      } else {
        // Handle legacy data.json format
        final legacyFile = archive.findFile('data.json');
        if (legacyFile != null) {
          final List<dynamic> legacyJson = await compute(
              _jsonParse, utf8.decode(legacyFile.content as List<int>));
          await db.batch((batch) {
            for (final item in legacyJson) {
              final photoName = p.basename(item['photoPath'] ?? '');
              final newPhotoPath = oldToNewPathMap[photoName] ?? '';
              if (newPhotoPath.isEmpty) continue;

              final date = DateTime.parse(item['date']);
              batch.insert(db.dayEntries, DayEntriesCompanion.insert(
                date: date,
                photoPath: newPhotoPath,
                moodRating: item['moodRating'] ?? 3,
                note: Value(item['note']),
                location: Value(item['location']),
                weatherTemp: Value(item['weatherTemp']),
                weatherIcon: Value(item['weatherIcon']),
              ));
              batch.insert(db.activityLog, ActivityLogCompanion.insert(
                  date: DateTime(date.year, date.month, date.day)),
                  mode: InsertMode.insertOrIgnore);
            }
          });
          Logger.info('Import: Restored ${legacyJson.length} legacy entries');
        }
      }

      Logger.info('Backup import completed successfully');
      return true;
    } catch (e, st) {
      Logger.error("Backup import failed", e, st);
      return false;
    } finally {
      _isImporting = false;
      await cleanupCache();
    }
  }

  Future<void> _restoreAuxTables(Archive archive, AppDatabase db) async {
    final adjFile = archive.findFile('adjustments.json');
    if (adjFile != null) {
      final List<dynamic> adjJson = await compute(
          _jsonParse, utf8.decode(adjFile.content as List<int>));
      await db.batch((batch) {
        for (final adj in adjJson) {
          final rawDate = adj['date'];
          batch.insert(db.streakAdjustments, StreakAdjustmentsCompanion.insert(
            date: rawDate is int ? DateTime.fromMillisecondsSinceEpoch(rawDate) : DateTime.parse(rawDate.toString()),
            type: adj['type'] ?? 'restore',
          ));
        }
      });
      Logger.info('Import: Restored ${adjJson.length} streak adjustments');
    }

    final logFile = archive.findFile('activity_log.json');
    if (logFile != null) {
      final List<dynamic> logJson = await compute(
          _jsonParse, utf8.decode(logFile.content as List<int>));
      await db.batch((batch) {
        for (final log in logJson) {
          final rawDate = log['date'];
          batch.insert(db.activityLog, ActivityLogCompanion.insert(
              date: rawDate is int ? DateTime.fromMillisecondsSinceEpoch(rawDate) : DateTime.parse(rawDate.toString())),
              mode: InsertMode.insertOrIgnore);
        }
      });
      Logger.info('Import: Restored ${logJson.length} activity log entries');
    }
  }

  /// Clears temporary file picker artifacts.
  static Future<void> cleanupCache() async {
    try {
      await FilePicker.platform.clearTemporaryFiles();
    } catch (e, stack) {
      Logger.warning('Failed to clear temporary file cache', e, stack);
    }
  }
}