import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../core/providers/theme_provider.dart';

class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentAccent = ref.watch(accentColorProvider);

    // First 4 = basic themes, next ones = premium themes
    final List<Map<String, dynamic>> themes = [
      // --- BASIC (first 4) ---
      {'name': l10n.themeKrono, 'color': const Color(0xFF6366F1)}, // Krono
      {'name': l10n.themeEmerald, 'color': Colors.teal}, // Emerald
      {'name': l10n.themeOcean, 'color': Colors.blue}, // Ocean
      {'name': l10n.themeSunset, 'color': Colors.orange}, // Sunset

      // --- PREMIUM (after first 4) ---
      {'name': l10n.themeBerry, 'color': Colors.pink}, // Berry (premium)
      {'name': l10n.themeMidnight, 'color': Colors.deepPurple}, // Midnight (premium)

      // two additional modern, elegant themes (premium)
      {'name': l10n.themeGarnet, 'color': const Color(0xFF7F1D1D)}, // muted slate gray (elegant)
      {'name': l10n.themeAurora, 'color': const Color(0xFF22D3EE)}, // fresh cyan-teal (modern)
    ];

    // split into two groups (basic vs premium) to force two rows:
    final basicThemes = themes.sublist(0, 4);
    final premiumThemes = themes.sublist(4);

    Widget buildThemeChip(Map<String, dynamic> theme) {
      final Color color = theme['color'] as Color;
      final String name = theme['name'] as String;
      final bool isSelected = currentAccent == color;

      return GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          ref.read(accentColorProvider.notifier).setAccentColor(color);
          Navigator.pop(context);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color,
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 30) : null,
            ),
            const Gap(8),
            SizedBox(
              width: 72, // limit width so labels break nicely and rows look even
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const Gap(24),
          Text(l10n.chooseTheme, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const Gap(24),

          // FIRST ROW: basic themes (4)
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: basicThemes.map((t) => buildThemeChip(t)).toList(),
          ),

          const Gap(18),

          // SECOND ROW: premium themes (remaining)
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: premiumThemes.map((t) => buildThemeChip(t)).toList(),
          ),

          const Gap(24),
        ],
      ),
    );
  }
}
