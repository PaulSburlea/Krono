import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/notification_service.dart';
import 'theme_provider.dart';
import 'locale_provider.dart';
import '../../../../l10n/app_localizations.dart';

class NotificationState {
  final bool isEnabled;
  final int hour;
  final int minute;

  NotificationState({this.isEnabled = false, this.hour = 20, this.minute = 0});
}

final notificationsEnabledProvider = NotifierProvider<NotificationNotifier, NotificationState>(() {
  return NotificationNotifier();
});

class NotificationNotifier extends Notifier<NotificationState> {
  static const _keyEnabled = 'notifications_enabled';
  static const _keyHour = 'notifications_hour';
  static const _keyMinute = 'notifications_minute';

  @override
  NotificationState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return NotificationState(
      isEnabled: prefs.getBool(_keyEnabled) ?? false,
      hour: prefs.getInt(_keyHour) ?? 20,
      minute: prefs.getInt(_keyMinute) ?? 0,
    );
  }

  Future<void> updateSettings(bool enabled, int h, int m) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final currentLocale = ref.read(localeProvider);

    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setInt(_keyHour, h);
    await prefs.setInt(_keyMinute, m);

    state = NotificationState(isEnabled: enabled, hour: h, minute: m);

    if (enabled) {
      final l10n = await AppLocalizations.delegate.load(currentLocale);

      await NotificationService.scheduleDailyReminder(
        title: l10n.notificationTitle, // Din .arb
        body: l10n.notificationBody,   // Din .arb
        hour: h,
        minute: m,
      );
    } else {
      await NotificationService.cancelAll();
    }
  }
}