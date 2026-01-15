import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../core/database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(ref.watch(databaseProvider));
});

class JournalRepository {
  final AppDatabase _db;
  JournalRepository(this._db);

  /// --- LOGICĂ PROCESARE IMAGINE ---
  Future<String> _processAndOptimizeImage(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.webp';
    final permanentPath = '${dir.path}/$fileName';

    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      permanentPath,
      quality: 85,
      format: CompressFormat.webp,
    );

    final tempFile = File(sourcePath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    return result?.path ?? permanentPath;
  }

  /// --- ADD ENTRY ---
  Future<void> addEntry({
    required String tempPhotoPath,
    required int mood,
    required String note,
    String? location,
    String? weatherTemp,
    String? weatherIcon,
    DateTime? date,
  }) async {
    final optimizedPath = await _processAndOptimizeImage(tempPhotoPath);

    await _db.into(_db.dayEntries).insert(
      DayEntriesCompanion.insert(
        date: date ?? DateTime.now(),
        photoPath: optimizedPath,
        moodRating: mood,
        note: Value(note.isEmpty ? null : note),
        location: Value(location),
        weatherTemp: Value(weatherTemp),
        weatherIcon: Value(weatherIcon),
      ),
    );
  }

  /// --- UPDATE ENTRY ---
  Future<void> updateEntry({
    required DayEntry entry,
    required String newPhotoPath,
    required int newMood,
    String? newNote,
    String? newLocation,
    String? newWeatherTemp,
    String? newWeatherIcon,
  }) async {
    String finalPath = entry.photoPath;

    if (entry.photoPath != newPhotoPath) {
      finalPath = await _processAndOptimizeImage(newPhotoPath);

      final oldFile = File(entry.photoPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }

    await (_db.update(_db.dayEntries)..where((t) => t.id.equals(entry.id))).write(
      DayEntriesCompanion(
        photoPath: Value(finalPath),
        moodRating: Value(newMood),
        note: Value(newNote?.isEmpty == true ? null : newNote),
        location: Value(newLocation),
        weatherTemp: Value(newWeatherTemp),
        weatherIcon: Value(newWeatherIcon),
      ),
    );
  }

  /// --- DELETE ENTRY ---
  Future<void> deleteEntry(DayEntry entry) async {
    final file = File(entry.photoPath);
    if (await file.exists()) {
      await file.delete();
    }
    await (_db.delete(_db.dayEntries)..where((t) => t.id.equals(entry.id))).go();
  }

  /// --- DELETE ALL DATA ---
  /// Această metodă șterge toate rândurile din DB și toate pozele de pe disc
  Future<void> deleteAllData() async {
    try {
      // 1. Ștergem toate înregistrările din tabelul Drift
      await _db.delete(_db.dayEntries).go();

      // 2. Localizăm folderul unde salvăm pozele
      final dir = await getApplicationDocumentsDirectory();
      final directory = Directory(dir.path);

      if (await directory.exists()) {
        // Listăm toate fișierele și le ștergem doar pe cele .webp (pentru a nu strica DB-ul)
        final List<FileSystemEntity> files = directory.listSync();
        for (var file in files) {
          if (file is File && file.path.endsWith('.webp')) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Logăm eroarea dacă e cazul, dar nu blocăm UI-ul
      print("Eroare la ștergerea totală: $e");
    }
  }

  /// --- GET ALL ---
  Future<List<DayEntry>> getAllEntries() async {
    return await (_db.select(_db.dayEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }
}