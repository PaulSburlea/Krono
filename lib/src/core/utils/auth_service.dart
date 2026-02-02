import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'logger_service.dart';

/// A service that abstracts the `local_auth` plugin to provide a simple
/// interface for biometric and device passcode authentication.
///
/// This service centralizes authentication logic, including hardware capability
/// checks and standardized error handling.
class AuthService {
  /// The underlying `local_auth` plugin instance.
  final LocalAuthentication _auth;

  /// Creates an instance of the [AuthService].
  ///
  /// Requires an instance of [LocalAuthentication] to be injected.
  AuthService(this._auth);

  /// Verifies if the device hardware supports biometrics or a device passcode.
  ///
  /// This check is performed to determine if an authentication prompt can be shown.
  /// It returns `true` if the device can perform checks, and `false` otherwise.
  ///
  /// Implementation notes:
  /// - `canCheckBiometrics` only indicates hardware availability, not whether any biometrics are enrolled.
  /// - `getAvailableBiometrics()` returns the enrolled biometric types.
  /// - `isDeviceSupported()` returns true on devices that support local authentication methods
  ///   (including device passcode) even if no biometrics are enrolled.
  Future<bool> canAuthenticate() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics =
      await _auth.getAvailableBiometrics();
      final bool isDeviceSupported = await _auth.isDeviceSupported();

      // True if device supports authentication at OS level OR there are enrolled biometrics.
      final bool can = isDeviceSupported || availableBiometrics.isNotEmpty || canCheckBiometrics;

      Logger.debug(
        'canAuthenticate -> deviceSupported: $isDeviceSupported, '
            'canCheckBiometrics: $canCheckBiometrics, '
            'availableBiometrics: ${availableBiometrics.map((b) => b.toString()).toList()}, '
            'result: $can',
      );

      return can;
    } catch (e, stack) {
      Logger.error(
        "Hardware verification for authentication failed",
        e,
        stack,
      );
      return false;
    }
  }

  /// Returns true if there are biometrics enrolled on the device.
  Future<bool> isBiometricEnrolled() async {
    try {
      final List<BiometricType> available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (e, stack) {
      Logger.error("Failed to check enrolled biometrics", e, stack);
      return false;
    }
  }

  /// Initiates the native authentication prompt (e.g., Face ID, fingerprint, or passcode).
  ///
  /// Displays a system dialog to the user with the provided [reason].
  /// Returns `true` upon successful authentication, or `false` for any
  /// failures, including user cancellation or hardware errors.
  Future<bool> authenticate(String reason) async {
    try {
      if (!await canAuthenticate()) {
        Logger.warning(
            "Authentication skipped: device does not support local authentication or no biometric/passcode available.");
        return false;
      }

      Logger.info("Authentication process initiated.");

      // Use the recommended authenticate signature for local_auth 3.0.0.
      // By default this may fallback to device passcode unless biometricOnly is true.
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );

      Logger.info("Authentication completed with result: $didAuthenticate");
      return didAuthenticate;
    } on LocalAuthException catch (e, stack) {
      // The plugin uses LocalAuthException for most failure cases — log and
      // handle specific codes if needed (e.g., biometricLockout, noBiometricHardware).
      Logger.error(
        "Authentication failed due to a local auth issue: ${e.code}",
        e,
        stack,
      );

      // Example of handling specific codes (extend as needed):
      // if (e.code == LocalAuthExceptionCode.biometricLockout) { ... }

      return false;
    } on PlatformException catch (e, stack) {
      // Platform-level issues (rare but possible).
      Logger.error(
        "Authentication failed due to a platform issue: [${e.code}] ${e.message}",
        e,
        stack,
      );
      return false;
    } catch (e, stack) {
      // Fallback for any other unexpected exceptions.
      Logger.error("An unhandled error occurred during authentication", e, stack);
      return false;
    }
  }
}
