import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import 'auth_service.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const AuthWrapper({super.key, required this.child});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialAuth();
    });
  }

  Future<void> _checkInitialAuth() async {
    final isEnabled = ref.read(authSettingsProvider);

    if (!isEnabled) {
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
      }
      return;
    }

    // ✅ REZOLVARE: Oprim loading-ul imediat pentru a randa UI-ul cu butonul
    // Chiar dacă _isAuthenticated este încă false, build() va genera ecranul de blocare
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    // Declanșăm autentificarea automată
    _performAuth();
  }

  Future<void> _performAuth() async {
    final l10n = AppLocalizations.of(context);
    final String reason = l10n?.authReason ?? 'Accesează jurnalul tău';

    final success = await AuthService.authenticate(reason);

    if (mounted) {
      setState(() {
        _isAuthenticated = success;
        // Nu mai setăm isLoading aici, am făcut-o deja în _checkInitialAuth
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Loading doar la pornirea strictă a aplicației (milisecunde)
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    // 2. Dacă suntem autentificați, intrăm în aplicație
    if (_isAuthenticated) {
      return widget.child;
    }

    // 3. ECRANUL DE SALVARE (Blocare)
    // Acesta va fi vizibil dacă auth a eșuat sau a fost închis
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
              colorScheme.primaryContainer.withOpacity(0.2),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const Gap(32),
            Text(
              l10n.accessRestricted,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const Gap(12),
            Text(
              l10n.confirmIdentity,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.6),
                height: 1.4,
              ),
            ),
            const Gap(48),
            // BUTONUL CARE TE SALVEAZĂ dacă fereastra se închide
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: _performAuth,
                icon: const Icon(Icons.fingerprint_rounded, size: 28),
                label: Text(
                  l10n.unlock,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}