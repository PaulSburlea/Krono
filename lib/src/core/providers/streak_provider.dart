import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Model pentru a stoca cifra și istoricul de date
class StreakState {
  final int count;
  final List<DateTime> history;
  StreakState(this.count, this.history);
}

final streakProvider = NotifierProvider<StreakNotifier, StreakState>(() {
  return StreakNotifier();
});

class StreakNotifier extends Notifier<StreakState> {
  static const _keyStreak = 'current_streak_value';
  static const _keyHistory = 'streak_history_dates';

  @override
  StreakState build() {
    _loadPersistedData();
    return StreakState(0, []);
  }

  Future<void> _loadPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    int savedStreak = prefs.getInt(_keyStreak) ?? 0;
    List<String> historyStr = prefs.getStringList(_keyHistory) ?? [];

    List<DateTime> history = historyStr.map((s) => DateTime.parse(s)).toList();

    if (history.isNotEmpty) {
      final lastActivity = history.last;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastActivityDay = DateTime(lastActivity.year, lastActivity.month, lastActivity.day);

      final difference = today.difference(lastActivityDay).inDays;

      if (difference > 1) {
        // Dacă a trecut mai mult de o zi fără activitate, resetăm totul
        savedStreak = 0;
        history = [];
        await prefs.setInt(_keyStreak, 0);
        await prefs.setStringList(_keyHistory, []);
      }
    }
    state = StreakState(savedStreak, history);
  }

  Future<void> markActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Verificăm dacă am marcat deja ziua de azi în istoric
    bool alreadyMarked = state.history.any((d) =>
    d.year == today.year && d.month == today.month && d.day == today.day);

    if (!alreadyMarked) {
      final newCount = state.count + 1;
      final newHistory = [...state.history, today];

      state = StreakState(newCount, newHistory);

      await prefs.setInt(_keyStreak, newCount);
      // Salvăm datele în format scurt (YYYY-MM-DD) pentru eficiență
      await prefs.setStringList(
        _keyHistory,
        newHistory.map((d) => d.toIso8601String().split('T')[0]).toList(),
      );
    }
  }
}