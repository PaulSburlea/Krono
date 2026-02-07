import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../core/utils/logger_service.dart';
import 'time_picker_sheet.dart';

/// A friendly bottom sheet prompted after the user's first successful entry.
///
/// This widget handles the initial permission request flow before allowing
/// the user to configure the specific reminder time.
class NotificationPromptSheet extends ConsumerWidget {
  /// Creates a [NotificationPromptSheet].
  const NotificationPromptSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const Gap(24),
          Text(
            l10n.notificationPromptTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const Gap(12),
          Text(
            l10n.notificationPromptBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const Gap(32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l10n.maybeLater),
                ),
              ),
              const Gap(16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () => _handlePermissionAndOpenPicker(context, ref),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    l10n.setReminder,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Requests system notification permissions and opens the time picker if granted.
  ///
  /// If the user denies the permission, the prompt is dismissed without opening
  /// the [TimePickerSheet] to avoid a broken user experience.
  Future<void> _handlePermissionAndOpenPicker(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);

    Logger.info('User requested to set reminder. Triggering permission request.');

    // Trigger the native OS permission dialog
    final bool granted = await notificationService.requestPermission();

    if (!context.mounted) return;

    if (granted) {
      Logger.info('Notification permission granted. Opening TimePickerSheet.');
      // Close the prompt first
      Navigator.pop(context);

      // Open the time picker
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const TimePickerSheet(),
      );
    } else {
      Logger.warning('Notification permission denied by user.');
      // Close the prompt. We don't open the picker because scheduling would fail.
      Navigator.pop(context);

      // Optional: Provide feedback that the feature requires permissions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.notificationsDeniedTitle),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}