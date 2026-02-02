import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krono/src/core/database/database.dart';
import 'package:krono/src/core/database/models/streak_adjustment_type.dart';
import 'package:krono/src/core/providers/streak_provider.dart';

void main() {
  ProviderContainer createContainer({
    List<ActivityLogData> logs = const [],
    List<StreakAdjustment> adjustments = const [],
  }) {
    return ProviderContainer(
      overrides: [
        activityLogStreamProvider.overrideWithValue(AsyncValue.data(logs)),
        streakAdjustmentsProvider.overrideWithValue(AsyncValue.data(adjustments)),
      ],
    );
  }

  DateTime toDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  group('Production Tests for StreakProvider', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10, 0);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final threeDaysAgo = today.subtract(const Duration(days: 3));

    test('Initial state (no data) returns count 0', () {
      final container = createContainer();
      final state = container.read(streakProvider);
      expect(state.count, 0);
      expect(state.activeDates, isEmpty);
    });

    test('Streak is 1 if activity exists TODAY', () {
      final logs = [ActivityLogData(id: 1, date: today)];
      final container = createContainer(logs: logs);
      final state = container.read(streakProvider);
      expect(state.count, 1);
      expect(toDate(state.lastActivityDate!), toDate(today));
    });

    test('Streak is 1 if activity exists YESTERDAY', () {
      final logs = [ActivityLogData(id: 1, date: yesterday)];
      final container = createContainer(logs: logs);
      final state = container.read(streakProvider);
      expect(state.count, 1);
    });

    test('Streak is BROKEN (0) if last activity was 2 days ago', () {
      final logs = [ActivityLogData(id: 1, date: twoDaysAgo)];
      final container = createContainer(logs: logs);
      final state = container.read(streakProvider);
      expect(state.count, 0);
    });

    test('Calculates consecutive streak correctly (Today + Yesterday)', () {
      final logs = [
        ActivityLogData(id: 1, date: today),
        ActivityLogData(id: 2, date: yesterday),
      ];
      final container = createContainer(logs: logs);
      final state = container.read(streakProvider);
      expect(state.count, 2);
    });

    test('Streak stops at a gap', () {
      final logs = [
        ActivityLogData(id: 1, date: today),
        ActivityLogData(id: 2, date: yesterday),
        ActivityLogData(id: 3, date: threeDaysAgo),
      ];
      final container = createContainer(logs: logs);
      final state = container.read(streakProvider);
      expect(state.count, 2);
    });

    test('Merges data from ActivityLog and StreakAdjustments', () {
      final logs = [ActivityLogData(id: 1, date: today), ActivityLogData(id: 2, date: twoDaysAgo)];
      final adjustments = [
        StreakAdjustment(id: 1, date: yesterday, createdAt: DateTime.now(), type: StreakAdjustmentType.restore),
      ];
      final container = createContainer(logs: logs, adjustments: adjustments);
      final state = container.read(streakProvider);
      expect(state.count, 3);
    });

    test('Handles duplicates (multiple entries on same day)', () {
      final logs = [
        ActivityLogData(id: 1, date: today),
        ActivityLogData(id: 2, date: today.add(const Duration(hours: 2))),
        ActivityLogData(id: 3, date: yesterday),
      ];
      final container = createContainer(logs: logs);
      final state = container.read(streakProvider);
      expect(state.count, 2);
      expect(state.activeDates.length, 2);
    });

    test('Ignores time components when calculating streak', () {
      final lateToday = DateTime(now.year, now.month, now.day, 23, 59);
      final earlyYesterday = DateTime(now.year, now.month, now.day, 0, 1).subtract(const Duration(days: 1));
      final logs = [ActivityLogData(id: 1, date: lateToday), ActivityLogData(id: 2, date: earlyYesterday)];
      final container = createContainer(logs: logs);
      final state = container.read(streakProvider);
      expect(state.count, 2);
    });
  });
}