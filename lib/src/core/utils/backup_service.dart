import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

import '../database/database.dart';

class BackupService {
  // ✅ Metoda de Export corectată pentru a evita ZIP-ul gol
  static Future<void> exportFullBackup(AppDatabase db) async {
    // 1. Preluăm toate intrările din baza de date primită ca parametru
    final entries = await db.select(db.dayEntries).get();

    final tempDir = await getTemporaryDirectory();
    final backupFolderPath = '${tempDir.path}/krono_export';
    final backupFolder = Directory(backupFolderPath);

    // Curățăm folderul de export dacă există deja
    if (await backupFolder.exists()) {
      await backupFolder.delete(recursive: true);
    }
    await backupFolder.create(recursive: true);

    // 2. Creăm obiectul JSON
    final jsonData = entries.map((e) => {
      'date': e.date.toIso8601String(),
      'photoPath': p.basename(e.photoPath),
      'moodRating': e.moodRating,
      'note': e.note,
    }).toList();

    // 3. Salvăm JSON-ul în folderul temporar
    final jsonFile = File('$backupFolderPath/data.json');
    await jsonFile.writeAsString(jsonEncode(jsonData));

    // 4. Copiem imaginile în folderul de backup
    final imagesFolder = Directory('$backupFolderPath/images');
    await imagesFolder.create(recursive: true);

    for (var entry in entries) {
      final imageFile = File(entry.photoPath);
      if (await imageFile.exists()) {
        try {
          await imageFile.copy('${imagesFolder.path}/${p.basename(entry.photoPath)}');
        } catch (e) {
          print("Eroare la copierea imaginii: $e");
        }
      }
    }

    // 5. ARHIVARE (Metoda sigură: adăugăm fișierele unul câte unul)
    final zipPath = '${tempDir.path}/krono_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    // Adăugăm JSON-ul
    await encoder.addFile(jsonFile);

    // Adăugăm manual imaginile pentru a evita erorile de addDirectory
    final copiedImages = imagesFolder.listSync();
    for (var entity in copiedImages) {
      if (entity is File) {
        // Al doilea parametru păstrează structura folderului în interiorul ZIP-ului
        await encoder.addFile(entity, 'images/${p.basename(entity.path)}');
      }
    }

    encoder.close();

    // 6. Share fișierul ZIP
    final zipFile = File(zipPath);
    if (await zipFile.exists()) {
      await Share.shareXFiles([XFile(zipPath)], text: 'Backup Krono Journal');
    }
  }

  // ✅ Metoda de Import corectată
  static Future<bool> importFullBackup(AppDatabase db) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null) return false;

    final appDir = await getApplicationDocumentsDirectory();
    final zipFile = File(result.files.single.path!);

    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      List<dynamic>? jsonData;

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;

          if (filename.endsWith('data.json')) {
            jsonData = jsonDecode(utf8.decode(data));
          } else if (filename.contains('images/')) {
            final outFileName = p.basename(filename);
            final outFile = File('${appDir.path}/$outFileName');
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(data);
          }
        }
      }

      if (jsonData != null) {
        await db.batch((batch) {
          for (var item in jsonData!) {
            batch.insert(
              db.dayEntries,
              DayEntriesCompanion.insert(
                date: DateTime.parse(item['date']),
                photoPath: '${appDir.path}/${item['photoPath']}',
                moodRating: item['moodRating'],
                note: Value(item['note']),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
        return true;
      }
    } catch (e) {
      print("Eroare la import: $e");
      return false;
    }
    return false;
  }
}