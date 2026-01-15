import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canAuthenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isDeviceSupported;
    } catch (e) {
      debugPrint("Eroare verificare suport auth: $e");
      return false;
    }
  }

  static Future<bool> authenticate(String reason) async {
    try {
      if (!await canAuthenticate()) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
      );
    } on PlatformException catch (e) {
      debugPrint("Auth Error: ${e.code} - ${e.message}");
      return false;
    }
  }

}