import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../settings/providers/theme_provider.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../../../l10n/app_localizations.dart';

/// A bottom sheet widget that allows users to select the application's accent color.
///
/// This widget displays all available color themes in a unified, responsive grid.
/// It handles user selection, displays premium status badges, and provides
/// haptic feedback upon interaction.
class ThemeSelector extends ConsumerWidget {
  /// Creates a [ThemeSelector] instance.
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentAccent = ref.watch(accentColorProvider);
    final theme = Theme.of(context);

    // Defines the complete list of available themes.
    // The order in this list determines the display order in the grid.
    final List<_ThemeModel> allThemes = [
      // --- Basic Themes ---
      _ThemeModel(name: l10n.themeKrono, color: const Color(0xFF6366F1)),
      _ThemeModel(name: l10n.themeEmerald, color: Colors.teal),
     // _ThemeModel(name: l10n.themeOcean, color: Colors.blue),
      // _ThemeModel(name: l10n.themeSunset, color: Colors.orange),

      // --- Premium Themes ---
      // These will automatically wrap to the next line in the grid.
/*      _ThemeModel(
          name: l10n.themeBerry, color: Colors.pink, isPremium: true),
      _ThemeModel(
          name: l10n.themeMidnight, color: Colors.deepPurple, isPremium: true),
      _ThemeModel(
          name: l10n.themeGarnet,
          color: const Color(0xFF7F1D1D),
          isPremium: true),
      _ThemeModel(
          name: l10n.themeAurora,
          color: const Color(0xFF22D3EE),
          isPremium: true),*/


      // --- Premium Themes ---
      _ThemeModel(
          name: l10n.themeGold,
          color: const Color(0xFFD4AF37), // Gold auriu
          isPremium: true),
/*      _ThemeModel(
          name: l10n.themeTurquoise,
          color: const Color(0xFF06B6D4), // Cyan vibrant
          isPremium: true),*/
      _ThemeModel(
          name: l10n.themeRose,
          color: const Color(0xFFE11D48), // Rose intens
          isPremium: true),
/*      _ThemeModel(
          name: l10n.themeSapphire,
          color: const Color(0xFF0F52BA), // Albastru safir
          isPremium: true),*/

    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visual drag handle indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(24),

          // Sheet Title
          Text(
            l10n.chooseTheme,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const Gap(32),

          // Renders the grid of theme options.
          // The Wrap widget automatically handles line breaking based on available width.
          _ThemeGrid(
            themes: allThemes,
            currentAccent: currentAccent,
            onSelected: (color) => _handleSelection(context, ref, color),
          ),
        ],
      ),
    );
  }

  /// Updates the application theme and closes the sheet.
  void _handleSelection(BuildContext context, WidgetRef ref, Color color) {
    Logger.info('User selected new accent color: ${color.toARGB32()}');
    HapticFeedback.lightImpact();
    ref.read(accentColorProvider.notifier).setAccentColor(color);
    Navigator.pop(context);
  }
}

/// A helper widget responsible for rendering the responsive grid of theme options.
class _ThemeGrid extends StatelessWidget {
  /// The list of themes to display.
  final List<_ThemeModel> themes;

  /// The currently active accent color.
  final Color currentAccent;

  /// Callback triggered when a theme is selected.
  final ValueChanged<Color> onSelected;

  const _ThemeGrid({
    required this.themes,
    required this.currentAccent,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16, // Horizontal spacing between items
      runSpacing: 24, // Vertical spacing between lines
      alignment: WrapAlignment.center,
      children: themes.map((t) {
        // Compare integer values of colors to determine selection state.
        // Using toARGB32() instead of deprecated .value
        final isSelected = currentAccent.toARGB32() == t.color.toARGB32();

        return _ThemeChip(
          model: t,
          isSelected: isSelected,
          onTap: () => onSelected(t.color),
        );
      }).toList(),
    );
  }
}

/// A widget representing a single theme option (Circle + Label).
class _ThemeChip extends StatelessWidget {
  /// The data model for the theme.
  final _ThemeModel model;

  /// Whether this chip is currently selected.
  final bool isSelected;

  /// Callback triggered on tap.
  final VoidCallback onTap;

  const _ThemeChip({
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Aligns circles to the top to ensure uniformity even if text wraps.
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // The Color Circle Indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? model.color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: model.color,
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 28)
                      : null,
                ),
                // Premium Badge Indicator
                if (model.isPremium)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: const Icon(Icons.star_rounded,
                          size: 12, color: Colors.orange),
                    ),
                  ),
              ],
            ),
          ),
          const Gap(8),

          // The Theme Label
          SizedBox(
            width: 76, // Fixed width to ensure consistent grid alignment
            child: Text(
              model.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: theme.textTheme.labelMedium?.copyWith(
                height: 1.1,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : theme.hintColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A private data model representing a theme option.
class _ThemeModel {
  final String name;
  final Color color;
  final bool isPremium;

  _ThemeModel({
    required this.name,
    required this.color,
    this.isPremium = false,
  });
}