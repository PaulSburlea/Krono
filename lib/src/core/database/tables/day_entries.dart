import 'package:drift/drift.dart';

/// Schema definition for the [DayEntries] table.
///
/// This table stores all user-generated journal content, including
/// media references, emotional tracking, and environmental metadata.
@TableIndex(name: 'idx_day_entries_date', columns: {#date})
class DayEntries extends Table {
  /// Unique identifier for each entry.
  IntColumn get id => integer().autoIncrement()();

  /// The timestamp when the entry was captured.
  DateTimeColumn get date => dateTime()();

  /// Local file system path to the captured image.
  TextColumn get photoPath => text()();

  /// Local file system path to the generated thumbnail.
  TextColumn get thumbnailPath => text().nullable()();


  /// User's mood rating (typically on a scale of 1-5).
  IntColumn get moodRating => integer()();

  /// Optional text content provided by the user.
  TextColumn get note => text().nullable()();

  /// Formatted address or city name where the entry was created.
  TextColumn get location => text().nullable()();

  /// Temperature at the time of entry (e.g., "22°C").
  TextColumn get weatherTemp => text().nullable()();

  /// Identifier or URL for the weather condition icon.
  TextColumn get weatherIcon => text().nullable()();

}
