import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../l10n/app_localizations.dart';

class StreakCard extends StatelessWidget {
  final int streak;
  final List<DateTime> activeDates;

  const StreakCard({
    super.key,
    required this.streak,
    required this.activeDates,
  });

  String _formatStreakDuration(int totalDays, AppLocalizations l10n) {
    if (totalDays == 0) return l10n.startFirstDay;
    int years = totalDays ~/ 365;
    int remainingDays = totalDays % 365;
    int weeks = remainingDays ~/ 7;
    int days = remainingDays % 7;

    List<String> parts = [];
    if (years > 0) parts.add("$years ${years == 1 ? l10n.year : l10n.years}");
    if (weeks > 0) parts.add("$weeks ${l10n.weekShort}");
    if (days > 0 || parts.isEmpty) parts.add("$days ${days == 1 ? l10n.day : l10n.days}");
    return parts.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = streak > 0;

    return GestureDetector(
      onTap: () => _showStreakDetails(context),
      child: Container(
        margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.orange.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.95, end: 1.05),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Icon(Icons.local_fire_department, color: isActive ? Colors.orange : Colors.grey, size: 20),
            ),
            const SizedBox(width: 4),
            Text('$streak', style: TextStyle(color: isActive ? Colors.orange[900] : Colors.grey[600], fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showStreakDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final zileSaptamana = DateFormat.E(locale).dateSymbols.NARROWWEEKDAYS;

    final acum = DateTime.now();
    final azi = DateTime(acum.year, acum.month, acum.day);
    final luniCurent = azi.subtract(Duration(days: azi.weekday - 1));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            Icon(Icons.local_fire_department, color: streak > 0 ? Colors.orange : Colors.grey, size: 64),
            const SizedBox(height: 10),
            Text(_formatStreakDuration(streak, l10n), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.streakSuffix, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final dataZilei = luniCurent.add(Duration(days: index));

                // ✅ Verificăm dacă data respectivă se află în ISTORICUL STREAK-ULUI
                final bool eInStreak = activeDates.any((d) =>
                d.year == dataZilei.year &&
                    d.month == dataZilei.month &&
                    d.day == dataZilei.day
                );

                final bool eAzi = dataZilei.isAtSameMomentAs(azi);
                int displayIndex = (index + 1) % 7;

                return Column(
                  children: [
                    Text(
                        zileSaptamana[displayIndex],
                        style: TextStyle(
                            fontWeight: eAzi ? FontWeight.bold : FontWeight.normal,
                            color: eAzi ? Colors.orange : Colors.grey
                        )
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: eInStreak ? Colors.orange : Colors.orange.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: eAzi ? Border.all(color: Colors.orange, width: 2) : null,
                      ),
                      child: eInStreak ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 30),
            Text(streak > 0 ? l10n.streakLongMessage(streak) : l10n.addMemory, textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}