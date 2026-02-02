import 'package:drift/drift.dart';

/// Tracks dates on which the user has successfully completed an activity.
///
/// This table is used to calculate user streaks and activity history. It persists
/// a record of a completed day, even if the associated content (e.g., a photo)
/// is deleted later.
class ActivityLog extends Table {
  /// The unique identifier for the log entry.
  IntColumn get id => integer().autoIncrement()();

  /// The calendar date of the completed activity.
  ///
  /// This column has a unique constraint to ensure each date is logged only once.
  /// The time component of the [DateTime] should be ignored.
  DateTimeColumn get date => dateTime().unique()();
}