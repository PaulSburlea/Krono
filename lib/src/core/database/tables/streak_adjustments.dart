import 'package:drift/drift.dart';

import '../models/streak_adjustment_type.dart';

/// Stores manual overrides for the streak logic.
///
/// This allows for "Streak Freezes" (Grace Periods) or "Paid Restores"
/// to bridge gaps between physical journal entries.
class StreakAdjustments extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The specific date being "bridged" or "frozen".
  DateTimeColumn get date => dateTime()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Type of adjustment: 'freeze' (grace period) or 'restore' (paid).
  IntColumn get type => intEnum<StreakAdjustmentType>()();
}
