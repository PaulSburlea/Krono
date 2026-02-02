import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:krono/src/core/utils/auth_service.dart';

// Generate mocks for the LocalAuthentication plugin
@GenerateMocks([LocalAuthentication])
import 'auth_service_test.mocks.dart';

void main() {
  late AuthService authService;
  late MockLocalAuthentication mockLocalAuth;

  setUp(() {
    mockLocalAuth = MockLocalAuthentication();
    authService = AuthService(mockLocalAuth);
  });

  group('Production Tests for AuthService', () {
    group('canAuthenticate', () {
      test('returns true if device is supported', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

        // Act
        final result = await authService.canAuthenticate();

        // Assert
        expect(result, true);
      });

      test('returns true if biometrics can be checked', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

        // Act
        final result = await authService.canAuthenticate();

        // Assert
        expect(result, true);
      });

      test('returns false if no hardware support is available', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

        // Act
        final result = await authService.canAuthenticate();

        // Assert
        expect(result, false);
      });

      test('returns false gracefully on exception', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenThrow(PlatformException(code: 'ERROR'));

        // Act
        final result = await authService.canAuthenticate();

        // Assert
        expect(result, false);
      });
    });

    group('authenticate', () {
      test('returns true when authentication succeeds', () async {
        // Arrange: Ensure canAuthenticate returns true first
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.face]);

        // Mock the actual auth call
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          biometricOnly: anyNamed('biometricOnly'),
          sensitiveTransaction: anyNamed('sensitiveTransaction'),
          persistAcrossBackgrounding: anyNamed('persistAcrossBackgrounding'),
        )).thenAnswer((_) async => true);

        // Act
        final result = await authService.authenticate('Unlock App');

        // Assert
        expect(result, true);
      });

      test('returns false immediately if hardware is not supported', () async {
        // Arrange: Ensure canAuthenticate returns false
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

        // Act
        final result = await authService.authenticate('Unlock App');

        // Assert
        expect(result, false);
        // Verify authenticate was NEVER called
        verifyNever(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
        ));
      });

      test('returns false when user cancels or auth fails', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          biometricOnly: anyNamed('biometricOnly'),
          sensitiveTransaction: anyNamed('sensitiveTransaction'),
          persistAcrossBackgrounding: anyNamed('persistAcrossBackgrounding'),
        )).thenAnswer((_) async => false);

        // Act
        final result = await authService.authenticate('Unlock App');

        // Assert
        expect(result, false);
      });

      test('returns false gracefully on LocalAuthException (e.g. Locked Out)', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          biometricOnly: anyNamed('biometricOnly'),
          sensitiveTransaction: anyNamed('sensitiveTransaction'),
          persistAcrossBackgrounding: anyNamed('persistAcrossBackgrounding'),
        )).thenThrow(PlatformException(code: 'LockedOut')); // ✅ FIX: Use string literal

        // Act
        final result = await authService.authenticate('Unlock App');

        // Assert
        expect(result, false);
      });
    });
  });
}