import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krono/src/core/database/database.dart';
import 'package:krono/src/core/utils/image_service.dart';
import 'package:krono/src/core/utils/thumbnail/thumbnail_service.dart';
import 'package:krono/src/features/journal/data/journal_repository.dart';
import 'package:krono/src/features/journal/data/models/journal_entry.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';


// Generate mocks for the file system services
@GenerateMocks([ImageService, ThumbnailService])
import 'journal_repository_test.mocks.dart';

void main() {
  late AppDatabase db;
  late MockImageService mockImageService;
  late MockThumbnailService mockThumbnailService;
  late JournalRepository repository;

  setUp(() {
    // Use an in-memory database for testing to ensure SQL logic is valid
    // without writing to the actual device storage.
    db = AppDatabase.forTesting(NativeDatabase.memory());

    mockImageService = MockImageService();
    mockThumbnailService = MockThumbnailService();

    repository = JournalRepository(
      db: db,
      imageService: mockImageService,
      thumbnailService: mockThumbnailService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Production Tests for JournalRepository', () {
    final testDate = DateTime(2024, 1, 1);
    final testEntry = JournalEntry(
      date: testDate,
      photoPath: '/tmp/temp_photo.jpg',
      moodRating: 4,
      note: 'Test Note',
    );

    test('addEntry successfully processes image, generates thumbnail, and inserts to DB', () async {
      // Arrange
      const optimizedPath = '/perm/optimized.webp';
      const thumbPath = '/perm/thumb.webp';

      when(mockImageService.processAndOptimizeImage(any, deleteSource: anyNamed('deleteSource')))
          .thenAnswer((_) async => optimizedPath);

      when(mockThumbnailService.generateThumbnail(any, width: anyNamed('width')))
          .thenAnswer((_) async => thumbPath);

      // Act
      await repository.addEntry(testEntry, '/tmp/temp_photo.jpg');

      // Assert
      // 1. Verify DB insertion
      final allEntries = await repository.getAllEntries();
      expect(allEntries.length, 1);
      expect(allEntries.first.photoPath, optimizedPath);
      expect(allEntries.first.thumbnailPath, thumbPath);
      expect(allEntries.first.moodRating, 4);

      // 2. Verify Service interactions
      verify(mockImageService.processAndOptimizeImage('/tmp/temp_photo.jpg', deleteSource: false)).called(1);
      verify(mockThumbnailService.generateThumbnail(optimizedPath, width: 300)).called(1);
    });

    test('addEntry throws Exception if image processing fails', () async {
      // Arrange
      when(mockImageService.processAndOptimizeImage(any, deleteSource: anyNamed('deleteSource')))
          .thenAnswer((_) async => null); // Simulate failure

      // Act & Assert
      expect(
            () => repository.addEntry(testEntry, '/tmp/temp_photo.jpg'),
        throwsException,
      );

      // Verify DB is still empty
      final allEntries = await repository.getAllEntries();
      expect(allEntries, isEmpty);
    });

    test('updateEntry updates metadata without changing photo if newTempPath is null', () async {
      // Arrange: Seed DB
      await db.into(db.dayEntries).insert(
        DayEntriesCompanion.insert(
          date: testDate,
          photoPath: '/perm/original.webp',
          moodRating: 3,
        ),
      );
      final existing = await repository.getAllEntries();
      final entryToUpdate = existing.first;

      final updatedEntry = JournalEntry(
        id: entryToUpdate.id,
        date: testDate,
        photoPath: entryToUpdate.photoPath,
        moodRating: 5, // Changed mood
        note: 'Updated Note',
      );

      // Act
      await repository.updateEntry(updatedEntry);

      // Assert
      final result = await repository.getAllEntries();
      expect(result.first.moodRating, 5);
      expect(result.first.note, 'Updated Note');

      // Verify no image processing happened
      verifyZeroInteractions(mockImageService);
      verifyZeroInteractions(mockThumbnailService);
    });

    test('updateEntry handles image replacement (deletes old, saves new)', () async {
      // Arrange: Seed DB
      const oldPhoto = '/perm/old.webp';
      const oldThumb = '/perm/old_thumb.webp';

      await db.into(db.dayEntries).insert(
        DayEntriesCompanion.insert(
          date: testDate,
          photoPath: oldPhoto,
          thumbnailPath: Value(oldThumb),
          moodRating: 3,
        ),
      );

      final existing = await repository.getAllEntries();
      final entryToUpdate = existing.first;

      const newTemp = '/tmp/new.jpg';
      const newOptimized = '/perm/new.webp';
      const newThumb = '/perm/new_thumb.webp';

      when(mockImageService.processAndOptimizeImage(newTemp, deleteSource: anyNamed('deleteSource')))
          .thenAnswer((_) async => newOptimized);
      when(mockThumbnailService.generateThumbnail(newOptimized, width: 300))
          .thenAnswer((_) async => newThumb);

      // Act
      await repository.updateEntry(
          entryToUpdate,
          newTempPath: newTemp,
          deleteSource: true
      );

      // Assert
      // 1. Verify DB updated with new paths
      final result = await repository.getAllEntries();
      expect(result.first.photoPath, newOptimized);
      expect(result.first.thumbnailPath, newThumb);

      // 2. Verify cleanup of old files
      verify(mockImageService.deleteFile(oldPhoto)).called(1);
      verify(mockImageService.deleteFile(oldThumb)).called(1);
    });

    test('deleteEntry removes files and deletes record from DB', () async {
      // Arrange: Seed DB
      const photoPath = '/perm/photo.webp';
      const thumbPath = '/perm/thumb.webp';

      await db.into(db.dayEntries).insert(
        DayEntriesCompanion.insert(
          date: testDate,
          photoPath: photoPath,
          thumbnailPath: Value(thumbPath),
          moodRating: 3,
        ),
      );

      final existing = await repository.getAllEntries();
      final entryToDelete = existing.first;

      // Act
      await repository.deleteEntry(entryToDelete);

      // Assert
      // 1. Verify DB is empty
      final result = await repository.getAllEntries();
      expect(result, isEmpty);

      // 2. Verify file deletion
      verify(mockImageService.deleteFile(photoPath)).called(1);
      verify(mockImageService.deleteFile(thumbPath)).called(1);
    });

    test('deleteAllData wipes all files and clears DB', () async {
      // Arrange: Seed DB with 2 entries
      await db.into(db.dayEntries).insert(
        DayEntriesCompanion.insert(
          date: testDate,
          photoPath: '/p1.webp',
          thumbnailPath: Value('/t1.webp'),
          moodRating: 1,
        ),
      );
      await db.into(db.dayEntries).insert(
        DayEntriesCompanion.insert(
          date: testDate.add(const Duration(days: 1)),
          photoPath: '/p2.webp',
          moodRating: 2,
        ),
      );

      // Act
      await repository.deleteAllData();

      // Assert
      final result = await repository.getAllEntries();
      expect(result, isEmpty);

      verify(mockImageService.deleteFile('/p1.webp')).called(1);
      verify(mockImageService.deleteFile('/t1.webp')).called(1);
      verify(mockImageService.deleteFile('/p2.webp')).called(1);
    });
  });
}