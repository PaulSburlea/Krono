// test/src/core/utils/backup_service_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:file_picker/file_picker.dart';
import 'package:krono/src/core/database/database.dart';
import 'package:krono/src/core/utils/backup_service.dart';
import 'package:krono/src/core/utils/thumbnail/thumbnail_service.dart';
import 'package:krono/src/features/journal/data/journal_repository.dart';
import 'package:krono/l10n/app_localizations_en.dart';

@GenerateMocks([JournalRepository, ThumbnailService])
import 'backup_service_test.mocks.dart';

class FakePathProvider extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  final Directory tempDir;
  FakePathProvider(this.tempDir);
  @override Future<String?> getTemporaryPath() async => tempDir.path;
  @override Future<String?> getApplicationDocumentsPath() async => tempDir.path;
  @override Future<String?> getApplicationSupportPath() async => tempDir.path;
}

class MockFilePicker extends FilePicker {
  final String? saveResult;
  final FilePickerResult? pickResult;
  MockFilePicker({this.saveResult, this.pickResult});
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async =>
      saveResult;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async =>
      pickResult;

  // evită warning-ul legat de clearTemporaryFiles în teste
  @override
  Future<bool> clearTemporaryFiles() async => true;
}

void main() {
  late AppDatabase db;
  late MockJournalRepository mockRepo;
  late Directory testDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    testDir = await Directory.systemTemp.createTemp('backup_test');
    PathProviderPlatform.instance = FakePathProvider(testDir);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockRepo = MockJournalRepository();
  });

  tearDown(() async {
    await db.close();
    try {
      await testDir.delete(recursive: true);
    } catch (_) {}
  });

  group('BackupService Production Tests', () {
    test('exportFullBackup returns true on success', () async {
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        journalRepositoryProvider.overrideWithValue(mockRepo),
        thumbnailServiceProvider.overrideWithValue(MockThumbnailService()),
      ]);

      FilePicker.platform = MockFilePicker(saveResult: 'path/to/save.zip');

      final success = await container.read(backupServiceProvider).exportFullBackup(AppLocalizationsEn());
      expect(success, true);
    });

    test('importFullBackup restores data correctly even without media files', () async {
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        journalRepositoryProvider.overrideWithValue(mockRepo),
        thumbnailServiceProvider.overrideWithValue(MockThumbnailService()),
      ]);

      // Construim arhiva doar cu database.json (fara fisier media)
      final archive = Archive();
      final dbData = [
        {
          'date': DateTime.now().millisecondsSinceEpoch,
          // photoPath gol -> importFullBackup nu va sari intrarea (vede photoName empty)
          'photoPath': '',
          'moodRating': 5,
          'note': 'test note'
        }
      ];
      final dbJsonString = jsonEncode(dbData);
      final dbBytes = utf8.encode(dbJsonString);
      archive.addFile(ArchiveFile('database.json', dbBytes.length, dbBytes));

      final zipBytes = ZipEncoder().encode(archive);
      final zipFile = File('${testDir.path}/import.zip')..writeAsBytesSync(zipBytes);

      FilePicker.platform = MockFilePicker(
        pickResult: FilePickerResult([
          PlatformFile(name: 'import.zip', size: zipBytes.length, path: zipFile.path)
        ]),
      );

      when(mockRepo.deleteAllData()).thenAnswer((_) async {});

      final success = await container.read(backupServiceProvider).importFullBackup();
      expect(success, true);

      final entries = await db.select(db.dayEntries).get();
      expect(entries.length, 1);

      final entry = entries.first;
      expect(entry.moodRating, 5);
      expect(entry.note, 'test note');
      // photoPath se așteaptă a fi string gol (așa cum a fost importat)
      expect(entry.photoPath, '');
    });
  });
}
