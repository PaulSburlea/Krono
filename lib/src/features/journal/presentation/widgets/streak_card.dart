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

  /// Returns a motivational message based on streak milestones
  String _getStreakMessage(int days, AppLocalizations l10n) {
    if (days == 0) return l10n.startFirstDay;
    if (days == 1) return l10n.streakFirstDay;
    if (days < 7) return l10n.streakWeekProgress;
    if (days == 7) return l10n.streakFirstWeek;
    if (days < 30) return l10n.streakMonthProgress;
    if (days == 30) return l10n.streakFirstMonth;
    if (days < 100) return l10n.streakHundredProgress;
    if (days == 100) return l10n.streakHundred;
    if (days < 365) return l10n.streakYearProgress;
    if (days == 365) return l10n.streakFirstYear;
    return l10n.streakLegendary;
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

    // Calculate progress to next milestone
    final nextMilestone = _getNextMilestone(streak);
    final progressToNext = nextMilestone > 0 ? streak / nextMilestone : 1.0;

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
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Gap(32),

            // 🔥 Big flame icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.2),
                      Colors.orange.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.orange,
                  size: 64,
                ),
              ),
            ),

            const Gap(20),

            // ✨ Main streak number - HERO
            Text(
              '$streak',
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 72,
                height: 1.0,
                color: Colors.orange,
                letterSpacing: -2,
              ),
            ),

            const Gap(8),

            // Simple, clean subtitle
            Text(
              streak == 1 ? l10n.streakDaySingular : l10n.streakDaysPlural,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),

            const Gap(24),

            // Progress bar to next milestone
            if (nextMilestone > 0) ...[
              _ProgressToMilestone(
                current: streak,
                target: nextMilestone,
                progress: progressToNext,
                l10n: l10n,
              ),
              const Gap(32),
            ] else
              const Gap(16),

            // Week view
            Text(
              l10n.thisWeek,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(16),

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

                final bool isFuture = dayDate.isAfter(today);

                int dayLabelIndex = (index + 1) % 7;

                return Opacity(
                  opacity: isFuture ? 0.3 : 1.0,
                  child: Column(
                    children: [
                      Text(
                        weekDaysNames[dayLabelIndex],
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday
                              ? Colors.orange
                              : theme.hintColor.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                      const Gap(10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isRecorded
                              ? Colors.orange
                              : theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: isToday
                              ? Border.all(color: Colors.orange, width: 2.5)
                              : null,
                          boxShadow: isRecorded
                              ? [
                            BoxShadow(
                              color: Colors.orange
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                              : null,
                        ),
                        child: isRecorded
                            ? const Icon(Icons.check_rounded,
                            size: 18, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                );
              }),
            ),

            const Gap(32),

            // Motivational message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                _getStreakMessage(streak, l10n),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[900],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get next milestone target
  int _getNextMilestone(int current) {
    const milestones = [7, 14, 30, 50, 100, 200, 365, 500, 1000];
    for (final milestone in milestones) {
      if (current < milestone) return milestone;
    }
    return 0; // No more milestones
  }
}

/// Progress bar widget showing progress to next milestone
class _ProgressToMilestone extends StatelessWidget {
  final int current;
  final int target;
  final double progress;
  final AppLocalizations l10n;

  const _ProgressToMilestone({
    required this.current,
    required this.target,
    required this.progress,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = target - current;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.nextMilestone,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              l10n.daysRemaining(remaining),
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Gap(8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        ),
        const Gap(6),
        Text(
          '$current / $target ${l10n.days}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.hintColor.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}