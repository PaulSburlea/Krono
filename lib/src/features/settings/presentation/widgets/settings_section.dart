import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// A reusable container widget for grouping settings items with a consistent visual style.
///
/// This widget renders a titled section containing a list of [children] widgets,
/// wrapped in a card-like container. It handles theme-specific styling (Light vs Dark)
/// to ensure contrast and visual hierarchy.
class SettingsSection extends StatelessWidget {
  /// The section header text, displayed in uppercase.
  final String title;

  /// The list of widgets (usually settings tiles) to display within the section.
  final List<Widget> children;

  /// Optional text displayed below the section, useful for explanatory notes.
  final String? footer;

  /// Creates a [SettingsSection].
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 10, top: 16),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
        ),

        // Main Container (Card)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            // Maintains a constant physical size across themes.
            // In Dark Mode, the border is transparent rather than removed to prevent layout shifts.
            border: Border.all(
              color: isDark
                  ? Colors.transparent
                  : colorScheme.outline.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Material(
            // Adapts background color for depth perception:
            // Light Mode: Uses a slightly transparent 'surfaceContainerHighest' for a subtle grey.
            // Dark Mode: Uses 'surfaceContainerLow' for standard dark elevation.
            color: isDark
                ? colorScheme.surfaceContainerLow
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: _buildChildrenWithSeparators(theme),
            ),
          ),
        ),

        // Optional Footer
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
            child: Text(
              footer!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
        const Gap(8),
      ],
    );
  }

  /// Helper method to insert dividers between children.
  List<Widget> _buildChildrenWithSeparators(ThemeData theme) {
    if (children.isEmpty) return [];
    final List<Widget> items = [];
    final isDark = theme.brightness == Brightness.dark;

    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      // Add a divider after every item except the last one.
      if (i < children.length - 1) {
        items.add(
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: theme.dividerColor.withValues(alpha: isDark ? 0.08 : 0.15),
          ),
        );
      }
    }
    return items;
  }
}