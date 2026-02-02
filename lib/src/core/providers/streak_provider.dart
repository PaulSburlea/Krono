import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../utils/logger_service.dart';

/// Represents the calculated state of the user's activity streak.
///
/// This is an immutable data class that holds the result of the streak calculation,
/// including the consecutive day count and the underlying activity dates.
class StreakState {
  /// The number of consecutive days of activity.
  final int count;

  /// The most recent date of any recorded activity. Can be null if no activity exists.
  final DateTime? lastActivityDate;

  /// A comprehensive, sorted list of all unique dates with recorded activity.
  final List<DateTime> activeDates;

  /// Creates an instance of the streak state.
  const StreakState({
    required this.count,
    this.lastActivityDate,
    this.activeDates = const [],
  });

  /// A factory for creating an initial, empty [StreakState].
  factory StreakState.initial() =>
      const StreakState(count: 0, activeDates: []);
}

/// Provides a continuous stream of the user's activity log from the database.
///
/// This stream automatically emits a new list of [ActivityLogData] whenever
/// the `activityLog` table is updated, ensuring reactive updates.
final activityLogStreamProvider = StreamProvider<List<ActivityLogData>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.activityLog)).watch();
});

/// Provides a continuous stream of streak adjustments from the database.
///
/// These adjustments represent manually added days, such as from a streak
/// restore feature, and are combined with the regular activity log.
final streakAdjustmentsProvider =
StreamProvider<List<StreakAdjustment>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.streakAdjustments)).watch();
});

/// The primary provider for calculating and exposing the user's activity streak.
///
/// This provider combines data from two sources: the [activityLogStreamProvider]
/// (for regular daily entries) and the [streakAdjustmentsProvider] (for manual
/// additions). It then computes the number of consecutive days of activity
/// leading up to the present day.
///
/// Importantly, deleting a journal entry does not affect the streak, as the
/// activity record persists in the dedicated `ActivityLog` table.
final streakProvider = Provider<StreakState>((ref) {
  final activityAsync = ref.watch(activityLogStreamProvider);
  final adjustmentsAsync = ref.watch(streakAdjustmentsProvider);

  // Gracefully handle loading/error states by using the last known good value or an empty list.
  final logs = activityAsync.value ?? [];
  final adjustments = adjustmentsAsync.value ?? [];

  if (logs.isEmpty && adjustments.isEmpty) {
    return StreakState.initial();
  }

  // 1. Consolidate all activity dates into a single, unique Set to prevent duplicates.
  final Set<DateTime> combinedDates = {};

  for (final log in logs) {
    combinedDates.add(DateTime(log.date.year, log.date.month, log.date.day));
  }

  for (final adj in adjustments) {
    combinedDates.add(DateTime(adj.date.year, adj.date.month, adj.date.day));
  }

  // 2. Sort the dates in descending order (most recent first).
  final sortedDates = combinedDates.toList()..sort((a, b) => b.compareTo(a));

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  // 3. Check if the streak is active. A streak is broken if the last activity
  // was before yesterday.
  final lastActiveDate = sortedDates.first;
  if (lastActiveDate.isBefore(yesterday)) {
    Logger.debug('Streak broken: Last activity was before yesterday.');
    return StreakState(
      count: 0,
      lastActivityDate: lastActiveDate,
      activeDates: sortedDates,
    );
  }

  // 4. Calculate the number of consecutive days by iterating backwards from the last active date.
  int streakCount = 0;
  DateTime currentCheckDate = lastActiveDate;

  for (final date in sortedDates) {
    if (date.isAtSameMomentAs(currentCheckDate)) {
      streakCount++;
      currentCheckDate = currentCheckDate.subtract(const Duration(days: 1));
    } else {
      // A gap was found that is not covered by any record, so the streak ends here.
      break;
    }
  }

  return StreakState(
    count: streakCount,
    lastActivityDate: lastActiveDate,
    activeDates: sortedDates,
  );
});