import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/pdf_provider.dart';
import '../../../core/utils/backup_service.dart';
import '../../../core/utils/logger_service.dart';
import '../../journal/data/journal_repository.dart';
import '../../../core/utils/notification_service.dart';

import 'widgets/settings_tile.dart';
import 'widgets/settings_section.dart';
import 'widgets/theme_selector_sheet.dart';
import 'widgets/language_selector_sheet.dart';
import 'widgets/time_picker_sheet.dart';

/// The main settings screen of the application.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String _feedbackFormUrl = 'https://forms.gle/8ppmLJi6itKeCZig7';
  static const String _privacyPolicyUrl = 'https://sites.google.com/view/krono-privacy';

  String _getLanguageName(String code) {
    return switch (code) {
      'ro' => 'Română',
      'fr' => 'Français',
      'en' => 'English',
      _ => 'English',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = ref.watch(accentColorProvider);
    final currentLocale = ref.watch(localeProvider);
    final isAuthEnabled = ref.watch(authSettingsProvider);
    final notifState = ref.watch(notificationProvider);
    final isExportingPdf = ref.watch(pdfExportLoadingProvider);
    final exportPdf = ref.read(exportPdfProvider);

    final String formattedTime =
        "${notifState.hour.toString().padLeft(2, '0')}:${notifState.minute.toString().padLeft(2, '0')}";

    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;
    const double dockHeight = 72.0;
    final double dockMargin = systemBottomPadding > 0 ? systemBottomPadding + 20 : 24.0;
    const double visualBuffer = 16.0;
    final double listBottomPadding = dockHeight + dockMargin + visualBuffer;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 10, 20, listBottomPadding),
        physics: const BouncingScrollPhysics(),
        children: [
          SettingsSection(
            title: l10n.notifications,
            children: [
              SettingsTile(
                icon: Icons.notifications_active_outlined,
                title: l10n.dailyReminder,
                subtitle: notifState.isEnabled
                    ? "${l10n.reminderSubtitle} ($formattedTime)"
                    : l10n.reminderSubtitle,
                onTap: () {
                  if (notifState.isEnabled) {
                    _openModal(context, const TimePickerSheet());
                  } else {
                    _handleToggleNotifications(context, ref, true);
                  }
                },
                trailing: Switch.adaptive(
                  value: notifState.isEnabled,
                  activeThumbColor: accentColor,
                  activeTrackColor: accentColor.withValues(alpha: 0.4),
                  onChanged: (val) => _handleToggleNotifications(context, ref, val),
                ),
              ),
            ],
          ),
          const Gap(24),
          SettingsSection(
            title: l10n.personalization,
            children: [
              SettingsTile(
                icon: Icons.palette_outlined,
                title: l10n.appTheme,
                subtitle: l10n.chooseAccent,
                trailing: CircleAvatar(radius: 10, backgroundColor: accentColor),
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
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(themeNotifierProvider.notifier).toggleTheme();
                },
                trailing: Switch.adaptive(
                  value: Theme.of(context).brightness == Brightness.dark,
                  activeThumbColor: accentColor,
                  activeTrackColor: accentColor.withValues(alpha: 0.4),
                  onChanged: (_) {
                    HapticFeedback.lightImpact();
                    ref.read(themeNotifierProvider.notifier).toggleTheme();
                  },
                ),
              ),
            ],
          ),
          const Gap(24),
          SettingsSection(
            title: l10n.dataBackup,
            children: [
              SettingsTile(
                icon: Icons.cloud_upload_outlined,
                title: l10n.exportBackup,
                onTap: () => _handleExportWithLoading(context, ref, l10n),
              ),
              SettingsTile(
                icon: Icons.cloud_download_outlined,
                title: l10n.importBackup,
                onTap: () => _handleImportBackup(context, ref, l10n),
              ),
              SettingsTile(
                icon: Icons.picture_as_pdf_outlined,
                title: l10n.exportPdf,
                trailing: isExportingPdf ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                // Fixed: Pass 'ref' to the handler function
                onTap: isExportingPdf ? null : () => _handlePdfExportFlow(context, ref, exportPdf, l10n),
              ),
            ],
          ),
          const Gap(24),
          SettingsSection(
            title: l10n.info,
            children: [
              SettingsTile(
                icon: Icons.fingerprint_rounded,
                title: l10n.appLock,
                subtitle: l10n.biometrics,
                onTap: () => _handleToggleAuth(context, ref, !isAuthEnabled),
                trailing: Switch.adaptive(
                  value: isAuthEnabled,
                  activeThumbColor: accentColor,
                  activeTrackColor: accentColor.withValues(alpha: 0.4),
                  onChanged: (val) => _handleToggleAuth(context, ref, val),
                ),
              ),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
                onTap: () => _launchUrl(context, _privacyPolicyUrl),
              ),
              SettingsTile(
                icon: Icons.rate_review_outlined,
                title: l10n.sendFeedback,
                subtitle: "Beta Feedback Form",
                onTap: () => _launchUrl(context, _feedbackFormUrl),
              ),
              SettingsTile(
                icon: Icons.info_outline_rounded,
                title: l10n.aboutKrono,
                onTap: () => _showAboutDialog(context, l10n),
              ),
            ],
          ),
          const Gap(24),
          SettingsSection(
            title: l10n.dangerZone,
            children: [
              SettingsTile(
                icon: Icons.delete_forever_outlined,
                iconColor: Colors.redAccent,
                title: l10n.deleteAll,
                onTap: () => _showDeleteDialog(context, ref, l10n),
              ),
            ],
          ),
          const Gap(48),
          _Footer(l10n: l10n),
        ],
      ),
    );
  }

  /// Orchestrates the PDF export flow, starting with a date range picker.
  Future<void> _handlePdfExportFlow(
      BuildContext context,
      WidgetRef ref,
      Future<void> Function(DateTimeRange?) exportPdf,
      AppLocalizations l10n
      ) async {
    HapticFeedback.mediumImpact();

    final firstEntryDate = await ref.read(journalRepositoryProvider).getFirstEntryDate();

    if (!context.mounted) return;

    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: firstEntryDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      helpText: "Select Period for PDF Export",
      confirmText: "Export",
      saveText: "Export",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange == null) return;

    if (context.mounted) {
      await _handlePdfExportWithLoading(context, () => exportPdf(pickedRange), l10n);
    }
  }

  /// Handles the PDF export process with a loading dialog.
  Future<void> _handlePdfExportWithLoading(
      BuildContext context,
      Future<void> Function() exportPdf,
      AppLocalizations l10n,
      ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoadingDialog(
        title: l10n.exportPdf,
        message: l10n.processing,
      ),
    );

    try {
      await exportPdf();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                const Gap(12),
                const Expanded(child: Text('PDF exported successfully!')),
              ],
            ),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        final message = e.toString().contains('No entries')
            ? 'No entries found for the selected period'
            : 'Error during PDF export';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Launches a URL in the external browser.
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        Logger.error('Could not launch URL: $urlString', Exception('Launch failed'), StackTrace.current);
      }
    } catch (e, stack) {
      Logger.error('Error launching URL', e, stack);
    }
  }

  /// Orchestrates the backup export sequence with user feedback.
  Future<void> _handleExportWithLoading(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    Logger.info('Starting backup export process.');
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoadingDialog(
        title: l10n.exportBackup,
        message: l10n.exportingMessage,
      ),
    );

    bool success = false;
    try {
      success = await ref.read(backupServiceProvider).exportFullBackup(l10n);
      Logger.info('Backup export completed. Success: $success');
    } catch (e, stack) {
      Logger.error('Export process exception.', e, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupExportError),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (success && context.mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                const Gap(12),
                Expanded(child: Text(l10n.backupExportedSuccess)),
              ],
            ),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  /// Opens a modal bottom sheet with the provided child widget.
  void _openModal(BuildContext context, Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => child,
    );
  }

  /// Coordinates the import process with a non-blocking UI overlay.
  Future<void> _handleImportBackup(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    Logger.info('Starting backup import process.');
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoadingDialog(
        title: l10n.importBackup,
        message: l10n.processing,
      ),
    );

    bool success = false;
    try {
      success = await ref.read(backupServiceProvider).importFullBackup();
      Logger.info('Backup import completed. Success: $success');
    } catch (e, stack) {
      Logger.error('Settings import handler error.', e, stack);
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupRestored),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Handles the notification toggle with Android 14 permission checks.
  Future<void> _handleToggleNotifications(BuildContext context, WidgetRef ref, bool newValue) async {
    Logger.info('Toggling notifications to: $newValue');
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(notificationServiceProvider);

    if (newValue) {
      final granted = await service.requestPermission();

      if (granted) {
        final bool isExactPermitted = await service.canScheduleExactAlarms();

        final state = ref.read(notificationProvider);
        await ref.read(notificationProvider.notifier).updateSettings(true, state.hour, state.minute);

        if (!isExactPermitted && context.mounted) {
          Logger.warning('Exact alarm permission missing. Showing dialog.');
          _showExactAlarmDialog(context, ref, l10n);
        } else if (context.mounted) {
          _openModal(context, const TimePickerSheet());
        }
      } else if (context.mounted) {
        Logger.warning('Notification permission denied.');
        _showPermissionDeniedDialog(context, l10n);
      }
    } else {
      final state = ref.read(notificationProvider);
      await ref.read(notificationProvider.notifier)
          .updateSettings(false, state.hour, state.minute);
    }
  }

  /// Explains the need for exact alarms as per Google Play policy.
  void _showExactAlarmDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Precise Reminders"),
        content: const Text("To receive reminders at the exact time you set, Krono needs the 'Alarms & Reminders' permission. Please enable it in the next screen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(notificationServiceProvider).openExactAlarmSettings();
            },
            child: const Text("Allow"),
          ),
        ],
      ),
    );
  }

  /// Toggles biometric authentication, guiding the user if security is not set up.
  Future<void> _handleToggleAuth(BuildContext context, WidgetRef ref, bool newValue) async {
    Logger.info('Toggling app lock to: $newValue');
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    final authService = ref.read(authServiceProvider);

    final bool canAuth = await authService.canAuthenticate();

    if (!canAuth) {
      Logger.warning('Authentication toggle aborted: Device not capable.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.securityNotSetup),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final success = await authService.authenticate(
      newValue ? l10n.authReasonToggleOn : l10n.authReasonToggleOff,
    );

    if (success) {
      await ref.read(authSettingsProvider.notifier).toggleAuth(newValue);
    } else {
      Logger.warning('Authentication failed during toggle.');
      HapticFeedback.vibrate();
    }
  }

  /// Shows a confirmation dialog for deleting all app data.
  void _showDeleteDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    Logger.info('Delete all data dialog opened.');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(l10n.confirmDeleteContent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              Logger.info('User confirmed deletion of all data.');
              Navigator.pop(context);
              await ref.read(journalRepositoryProvider).deleteAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.deleteAllSuccess), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog when notification permissions are denied, guiding the user to settings.
  void _showPermissionDeniedDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.notificationsDeniedTitle),
        content: Text(l10n.notificationsDeniedContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }

  /// Shows the "About" dialog with app information.
  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showAboutDialog(
      context: context,
      applicationName: 'Krono',
      applicationVersion: '1.0.0',
      applicationLegalese: l10n.copyright,
      children: [
        const Gap(16),
        Text(l10n.aboutKronoDetail),
      ],
    );
  }
}

/// A footer widget displaying the app name and version.
class _Footer extends StatelessWidget {
  final AppLocalizations l10n;
  const _Footer({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(l10n.appTitle,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
          const Gap(4),
          Text('${l10n.version} 1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }
}

/// A non-dismissible loading dialog with a spinner and message.
class _LoadingDialog extends StatelessWidget {
  final String title;
  final String message;

  const _LoadingDialog({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RepaintBoundary(
                child: SizedBox(
                  height: 50, width: 50,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
              const Gap(24),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}