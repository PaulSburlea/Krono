import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/utils/logger_service.dart';

/// A gamified widget that displays the user's current consecutive journal days.
///
/// Features a pulsing animation to draw attention and a detailed breakdown
/// of the current week's activity in a bottom sheet when tapped.
class StreakCard extends StatelessWidget {
  /// The current number of consecutive days the user has journaled.
  final int streak;

  /// A list of all dates on which the user has made a journal entry, used for
  /// displaying the weekly activity view.
  final List<DateTime> activeDates;

  /// Creates a card to display the user's journaling streak.
  const StreakCard({
    super.key,
    required this.streak,
    required this.activeDates,
  });

  /// Formats the total days into a human-readable duration (Years, Weeks, Days).
  ///
  /// Takes the [totalDays] and a localized [l10n] instance to produce a string
  /// like "1 year, 2 weeks, 3 days". Returns a prompt to start if the streak is zero.
  String _formatStreakDuration(int totalDays, AppLocalizations l10n) {
    if (totalDays == 0) return l10n.startFirstDay;

    final int years = totalDays ~/ 365;
    final int remainingDays = totalDays % 365;
    final int weeks = remainingDays ~/ 7;
    final int days = remainingDays % 7;

    final List<String> parts = [];
    if (years > 0) parts.add("$years ${years == 1 ? l10n.year : l10n.years}");
    if (weeks > 0) parts.add("$weeks ${l10n.weekShort}");
    if (days > 0 || parts.isEmpty) {
      parts.add("$days ${days == 1 ? l10n.day : l10n.days}");
    }

    final result = parts.join(", ");
    Logger.debug('Formatted streak duration for $totalDays days: "$result"');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = streak > 0;
    final theme = Theme.of(context);
    final Color streakColor = Colors.orange;
    final Color inactiveColor = theme.disabledColor;

    return GestureDetector(
      onTap: () {
        Logger.info('Streak card tapped. Current streak: $streak');
        HapticFeedback.lightImpact();
        _showStreakDetails(context);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? streakColor.withValues(alpha: 0.1)
              : inactiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive
                ? streakColor.withValues(alpha: 0.3)
                : inactiveColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.92, end: 1.08),
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Icon(
                Icons.local_fire_department_rounded,
                color: isActive ? streakColor : inactiveColor,
                size: 20,
              ),
            ),
            const Gap(6),
            Text(
              '$streak',
              style: TextStyle(
                color: isActive ? Colors.orange[900] : theme.hintColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays a modal bottom sheet with a detailed weekly view of the user's streak.
  ///
  /// This modal shows the formatted streak duration, a grid of the current week's
  /// activity based on the [activeDates], and a motivational message.
  void _showStreakDetails(BuildContext context) {
    Logger.info('Showing streak details modal.');
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).languageCode;
    final List<String> weekDaysNames =
        DateFormat.E(locale).dateSymbols.NARROWWEEKDAYS;

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime startOfWeek =
    today.subtract(Duration(days: today.weekday - 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Gap(32),
            const Icon(Icons.local_fire_department_rounded,
                color: Colors.orange, size: 72),
            const Gap(12),
            Text(
              _formatStreakDuration(streak, l10n),
              textAlign: TextAlign.center,
              style:
              theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const Gap(4),
            Text(
              l10n.streakSuffix,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
            const Gap(32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final DateTime dayDate = startOfWeek.add(Duration(days: index));
                final bool isRecorded = activeDates.any((d) =>
                d.year == dayDate.year &&
                    d.month == dayDate.month &&
                    d.day == dayDate.day);

                final bool isToday = dayDate.year == today.year &&
                    dayDate.month == today.month &&
                    dayDate.day == today.day;

                int dayLabelIndex = (index + 1) % 7;

                return Column(
                  children: [
                    Text(
                      weekDaysNames[dayLabelIndex],
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? Colors.orange : theme.hintColor,
                      ),
                    ),
                    const Gap(12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isRecorded
                            ? Colors.orange
                            : Colors.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: Colors.orange, width: 2)
                            : null,
                      ),
                      child: isRecorded
                          ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                          : null,
                    ),
                  ],
                );
              }),
            ),
            const Gap(40),
            Text(
              streak > 0 ? l10n.streakLongMessage(streak) : l10n.addMemory,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color:
                theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}