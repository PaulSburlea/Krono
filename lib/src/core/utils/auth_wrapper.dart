import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import 'logger_service.dart';

/// A gatekeeper widget that enforces local authentication before revealing its [child].
///
/// This widget checks the user's preference for biometric security. If enabled,
/// it presents an authentication prompt and only builds the [child] widget tree
/// upon successful verification.
class AuthWrapper extends ConsumerStatefulWidget {
  /// The primary content to display after successful authentication.
  final Widget child;

  /// Creates an instance of the authentication gatekeeper.
  const AuthWrapper({super.key, required this.child});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

/// The state for [AuthWrapper] which manages the authentication lifecycle.
class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  /// Tracks whether the user has successfully authenticated for the current session.
  bool _isSessionAuthenticated = false;

  /// Indicates if the initial security check is in progress to prevent UI flicker.
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _initializeSecurity();
  }

  /// Evaluates authentication requirements and triggers the biometric prompt if enabled.
  ///
  /// This is the entry point for the security check. It reads the user's preference
  /// and either grants access immediately or proceeds to the authentication flow.
  Future<void> _initializeSecurity() async {
    final isEnabled = ref.read(authSettingsProvider);

    if (!isEnabled) {
      Logger.info('Biometric lock is disabled. Granting access immediately.');
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isSessionAuthenticated = true;
        });
      }
      return;
    }

    Logger.info('Biometric lock is enabled. Initiating security check.');
    // A small delay ensures the native view hierarchy is stable before presenting the dialog.
    Logger.debug('Delaying auth prompt to ensure view hierarchy is stable.');
    await Future.delayed(const Duration(milliseconds: 300));
    await _handleAuthentication();

    if (mounted) setState(() => _isChecking = false);
  }

  /// Invokes the [AuthService] to perform biometric or passcode verification.
  ///
  /// This method handles the interaction with the authentication service and updates
  /// the session state based on the outcome.
  Future<void> _handleAuthentication() async {
    final l10n = AppLocalizations.of(context)!;
    final authService = ref.read(authServiceProvider);

    final success = await authService.authenticate(l10n.authReason);

    if (success) {
      Logger.info('User successfully authenticated.');
    } else {
      Logger.info('User failed or cancelled authentication.');
    }

    if (mounted) {
      setState(() => _isSessionAuthenticated = success);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator during the initial check to prevent UI flickering.
    if (_isChecking && !_isSessionAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    // Grant access if the session is authenticated or if the feature is disabled.
    // The second check on `ref.watch` ensures that if the user disables the
    // feature from settings while the app is locked, it unlocks immediately.
    if (_isSessionAuthenticated || !ref.watch(authSettingsProvider)) {
      return widget.child;
    }

    // Otherwise, show the locked screen overlay.
    return _LockedOverlay(onRetry: _handleAuthentication);
  }
}

/// A UI overlay displayed when the application is locked, prompting the user to authenticate.
class _LockedOverlay extends StatelessWidget {
  /// The callback function to execute when the user attempts to unlock the app.
  final VoidCallback onRetry;

  /// Creates the locked overlay UI.
  const _LockedOverlay({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withAlpha((255 * 0.1).round()),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLockIcon(colorScheme),
            const Gap(32),
            Text(
              l10n.accessRestricted,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const Gap(12),
            Text(
              l10n.confirmIdentity,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha((255 * 0.6).round()),
              ),
            ),
            const Gap(48),
            _UnlockButton(onPressed: onRetry),
          ],
        ),
      ),
    );
  }

  /// Builds the decorative lock icon for the locked overlay.
  Widget _buildLockIcon(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha((255 * 0.1).round()),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.lock_outline_rounded,
        size: 64,
        color: colorScheme.primary,
      ),
    );
  }
}

/// A standardized button used within the [_LockedOverlay] to trigger the authentication prompt.
class _UnlockButton extends StatelessWidget {
  /// The callback function to execute when the button is pressed.
  final VoidCallback onPressed;

  /// Creates the unlock button.
  const _UnlockButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.fingerprint_rounded),
        label: Text(l10n.unlock),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
