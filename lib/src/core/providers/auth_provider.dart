import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../utils/auth_service.dart';
import '../../features/settings/providers/theme_provider.dart';

/// Provides a singleton instance of the [LocalAuthentication] plugin.
///
/// This is the low-level service used to interact with the device's
/// biometric hardware (e.g., fingerprint or face ID).
final localAuthProvider =
Provider<LocalAuthentication>((ref) => LocalAuthentication());

/// Provides the application's authentication business logic, [AuthService].
///
/// This service abstracts the underlying [LocalAuthentication] plugin and
/// provides simple methods for checking and performing biometric authentication.
final authServiceProvider = Provider<AuthService>((ref) {
  final localAuth = ref.watch(localAuthProvider);
  return AuthService(localAuth);
});

/// Manages the user's preference for enabling or disabling the biometric lock feature.
///
/// This provider exposes the [AuthSettingsNotifier] to the UI, allowing widgets
/// to read and update the authentication setting.
final authSettingsProvider = NotifierProvider<AuthSettingsNotifier, bool>(() {
  return AuthSettingsNotifier();
});

/// A [Notifier] that controls the state of the biometric authentication setting.
///
/// It persists the user's choice to [SharedPreferences] and rebuilds widgets
/// when the setting is changed.
class AuthSettingsNotifier extends Notifier<bool> {
  /// The key used to store the authentication preference in SharedPreferences.
  static const _storageKey = 'is_auth_enabled';

  @override
  bool build() {
    // Watching sharedPreferencesProvider ensures the state automatically updates
    // if the preference is ever changed by another part of the app.
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_storageKey) ?? false;
  }

  /// Updates the biometric lock preference.
  ///
  /// Persists the new [isEnabled] value to [SharedPreferences] and updates the
  /// provider's state to trigger a UI rebuild.
  Future<void> toggleAuth(bool isEnabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_storageKey, isEnabled);
    state = isEnabled;
  }
}

/// Represents the possible states of the local authentication flow.
enum LocalAuthState {
  loading,      // Initial check (SPLASH/Loading)
  unauthenticated, // Auth is enabled but user hasn't proven identity
  authenticated,   // User is allowed to see the content
  disabled         // Security lock is turned off in settings
}
