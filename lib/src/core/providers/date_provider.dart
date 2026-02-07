import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A Notifier that holds the current date and automatically updates at midnight.
class CurrentDateNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    // Initialize the timer when the provider is first built
    _scheduleMidnightUpdate();

    // Clean up the timer when the provider is disposed
    ref.onDispose(() => _timer?.cancel());

    return DateTime.now();
  }

  void _scheduleMidnightUpdate() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);

    _timer?.cancel();
    _timer = Timer(timeUntilMidnight, () {
      // Update state to trigger rebuilds
      state = DateTime.now();
      // Reschedule for the next night
      _scheduleMidnightUpdate();
    });
  }
}

/// Provides the current [DateTime] and automatically refreshes at midnight.
final currentDateProvider = NotifierProvider<CurrentDateNotifier, DateTime>(CurrentDateNotifier.new);