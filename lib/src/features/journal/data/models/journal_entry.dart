import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';

/// A domain-level model for a journal entry, independent of the storage layer.
///
/// This entity represents the core data structure used throughout the application's
/// UI and business logic, decoupling it from the specific database implementation (Drift).
class JournalEntry {
  /// The unique identifier of the entry (nullable for new, unsaved entries).
  final int? id;

  /// The timestamp representing the date of the journal entry.
  final DateTime date;

  /// The local filesystem path to the high-resolution photo.
  final String photoPath;

  /// The local filesystem path to the optimized thumbnail (optional).
  final String? thumbnailPath;

  /// The user's mood rating for the day (typically 1-5).
  final int moodRating;

  /// An optional text note describing the day's events.
  final String? note;

  /// The location name where the entry was created (optional).
  final String? location;

  /// The formatted temperature string (e.g., "24°C") (optional).
  final String? weatherTemp;

  /// The icon code representing the weather condition (optional).
  final String? weatherIcon;

  /// Creates a [JournalEntry] instance.
  JournalEntry({
    this.id,
    required this.date,
    required this.photoPath,
    this.thumbnailPath,
    required this.moodRating,
    this.note,
    this.location,
    this.weatherTemp,
    this.weatherIcon,
  });

  /// Converts a Drift database row [DayEntry] into a domain [JournalEntry].
  ///
  /// This factory method handles the mapping from the persistence layer's
  /// data structure to the application's domain entity.
  factory JournalEntry.fromDrift(DayEntry entry) {
    return JournalEntry(
      id: entry.id,
      date: entry.date,
      photoPath: entry.photoPath,
      thumbnailPath: entry.thumbnailPath,
      moodRating: entry.moodRating,
      note: entry.note,
      location: entry.location,
      weatherTemp: entry.weatherTemp,
      weatherIcon: entry.weatherIcon,
    );
  }

  /// Converts this domain model into a Drift companion object.
  ///
  /// This method prepares the data for database insertion or updates,
  /// handling the conversion of nullable fields to [Value] types required by Drift.
  DayEntriesCompanion toDriftCompanion() {
    return DayEntriesCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      date: Value(date),
      photoPath: Value(photoPath),
      thumbnailPath: Value(thumbnailPath),
      moodRating: Value(moodRating),
      note: Value(note),
      location: Value(location),
      weatherTemp: Value(weatherTemp),
      weatherIcon: Value(weatherIcon),
    );
  }
}