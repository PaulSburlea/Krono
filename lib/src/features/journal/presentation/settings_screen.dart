import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart'; // Avem nevoie de acesta pentru openAppSettings()

import '../../../../l10n/app_localizations.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/pdf_provider.dart';
import '../data/journal_repository.dart';
import '../../../core/utils/backup_service.dart';
import '../../../core/utils/auth_service.dart';
import '../../../core/utils/notification_service.dart';

import 'widgets/settings_tile.dart';
import 'widgets/settings/settings_section.dart';
import 'widgets/settings/theme_selector_sheet.dart';
import 'widgets/settings/language_selector_sheet.dart';
import 'widgets/settings/time_picker_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _getLanguageName(String code) {
    switch (code) {
      case 'ro':
        return 'Română';
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeNotifierProvider);
    final accentColor = ref.watch(accentColorProvider);
    final currentLocale = ref.watch(localeProvider);
    final isAuthEnabled = ref.watch(authSettingsProvider);
    final notifState = ref.watch(notificationsEnabledProvider);
    final db = ref.watch(databaseProvider);

    final exportPdf = ref.read(exportPdfProvider);

    final String formattedTime =
        "${notifState.hour.toString().padLeft(2, '0')}:${notifState.minute
        .toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings, style: const TextStyle(fontWeight: FontWeight
            .bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // SECTIUNE NOTIFICARI
          SettingsSection(title: l10n.notifications, children: [
            SettingsTile(
              icon: Icons.notifications_active_outlined,
              title: l10n.dailyReminder,
              subtitle: notifState.isEnabled
                  ? "${l10n.reminderSubtitle} ($formattedTime)"
                  : l10n.reminderSubtitle,
              onTap: () async {
                // Dacă utilizatorul apasă pe rândul de notificări când sunt deja pornite, deschidem picker-ul de timp
                if (notifState.isEnabled) {
                  _openModal(context, const TimePickerSheet());
                } else {
                  // Altfel, încercăm să le activăm
                  _handleToggleNotifications(context, ref, true);
                }
              },
              trailing: Switch.adaptive(
                value: notifState.isEnabled,
                onChanged: (val) =>
                    _handleToggleNotifications(context, ref, val),
              ),
            ),
          ]),
          const Gap(24),

          // SECTIUNE PERSONALIZARE
          SettingsSection(title: l10n.personalization, children: [
            SettingsTile(
              icon: Icons.palette_outlined,
              title: l10n.appTheme,
              subtitle: l10n.chooseAccent,
              trailing: CircleAvatar(radius: 12, backgroundColor: accentColor),
              onTap: () => _openModal(context, const ThemeSelector()),
            ),
            SettingsTile(
              icon: Icons.language_rounded,
              title: l10n.language,
              subtitle: _getLanguageName(currentLocale.languageCode),
              onTap: () => _openModal(context, const LanguageSelector()),
            ),
            SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: l10n.darkMode,
              trailing: Switch.adaptive(
                value: themeMode == ThemeMode.dark,
                onChanged: (_) {
                  HapticFeedback.lightImpact();
                  ref.read(themeNotifierProvider.notifier).toggleTheme();
                },
              ),
            ),
          ]),
          const Gap(24),

          // SECTIUNE DATE
          SettingsSection(title: l10n.dataBackup, children: [
            SettingsTile(
              icon: Icons.cloud_upload_outlined,
              title: l10n.exportBackup,
              onTap: () async {
                HapticFeedback.mediumImpact();
                await BackupService.exportFullBackup(db);
              },
            ),
            SettingsTile(
              icon: Icons.cloud_download_outlined,
              title: l10n.importBackup,
              onTap: () async {
                HapticFeedback.mediumImpact();
                final success = await BackupService.importFullBackup(db);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.backupRestored),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }
              },
            ),
            SettingsTile(
              icon: Icons.picture_as_pdf_outlined,
              title: l10n.exportPdf,
              onTap: () async {
                HapticFeedback.mediumImpact();
                await exportPdf();
              },
            ),
          ]),
          const Gap(24),

          // SECTIUNE INFO
          SettingsSection(title: l10n.info, children: [
            SettingsTile(
              icon: Icons.fingerprint_rounded,
              title: l10n.appLock,
              subtitle: l10n.biometrics,
              onTap: () => _handleToggleAuth(context, ref, !isAuthEnabled),
              trailing: Switch.adaptive(
                value: isAuthEnabled,
                onChanged: (val) => _handleToggleAuth(context, ref, val),
              ),
            ),
            SettingsTile(
              icon: Icons.info_outline_rounded,
              title: l10n.aboutKrono,
              onTap: () => _showAboutDialog(context, l10n),
            ),
          ]),
          const Gap(24),

          // SECTIUNE DANGER
          SettingsSection(title: l10n.dangerZone, children: [
            SettingsTile(
              icon: Icons.delete_forever_outlined,
              iconColor: Colors.red,
              title: l10n.deleteAll,
              onTap: () => _showDeleteDialog(context, ref, l10n),
            ),
          ]),

          const Gap(40),
          _buildFooter(l10n),
          const Gap(100),
        ],
      ),
    );
  }

  // --- Helper Methods ---

  void _openModal(BuildContext context, Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => child,
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Center(
      child: Column(
        children: [
          Text(l10n.appTitle,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.5)),
          Text('${l10n.version} 1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }

  /// Gestionează pornirea/oprirea notificărilor
  Future<void> _handleToggleNotifications(BuildContext context, WidgetRef ref,
      bool newValue) async {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;

    if (newValue) {
      // 1. Încercăm să cerem permisiunea
      final granted = await NotificationService.requestPermission();

      if (granted) {
        // Dacă e ok, deschidem selectorul de oră
        if (context.mounted) {
          _openModal(context, const TimePickerSheet());
        }
      } else {
        // 2. Dacă a refuzat, verificăm dacă este refuzată permanent (Android)
        // Pe Android 13+, dacă a dat "Deny" de două ori, pop-up-ul nu mai apare.
        if (context.mounted) {
          _showPermissionDeniedDialog(context, l10n);
        }
      }
    } else {
      // Oprirea notificărilor
      final state = ref.read(notificationsEnabledProvider);
      await ref.read(notificationsEnabledProvider.notifier)
          .updateSettings(false, state.hour, state.minute);
    }
  }

  /// Dialog care explică utilizatorului cum să activeze permisiunile manual
  void _showPermissionDeniedDialog(BuildContext context,
      AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: Text(l10n.notificationsDeniedTitle), // Variabilă l10n
            content: Text(l10n.notificationsDeniedContent), // Variabilă l10n
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                  foregroundColor: Theme
                      .of(context)
                      .colorScheme
                      .onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.openSettings), // Variabilă l10n
              ),
            ],
          ),
    );
  }

  Future<void> _handleToggleAuth(BuildContext context, WidgetRef ref,
      bool newValue) async {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;

    await ref.read(authSettingsProvider.notifier).toggleAuth(newValue);

    bool success = false;
    try {
      success = await AuthService.authenticate(
        newValue ? l10n.authReasonToggleOn : l10n.authReasonToggleOff,
      );
    } catch (e) {
      success = false;
    } finally {
      if (!success) {
        HapticFeedback.vibrate();
        await ref.read(authSettingsProvider.notifier).toggleAuth(!newValue);
      }
    }
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showAboutDialog(
      context: context,
      applicationName: 'Krono',
      applicationVersion: '1.0.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/app_icon.png', width: 60, height: 60),
      ),
      applicationLegalese: l10n.copyright,
      children: [
        const Gap(16),
        Text(l10n.aboutKronoDetail),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref,
      AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(l10n.confirmDeleteTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(l10n.confirmDeleteContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  // Executăm ștergerea (asigură-te că ai deleteAllData definit în repo)
                  await ref.read(journalRepositoryProvider).deleteAllData();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.deleteAllSuccess),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                },
                child: Text(l10n.delete,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
    );
  }
}