import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/logger_service.dart';

/// A reusable and styled list tile for settings screens.
///
/// Provides a consistent layout with an icon, title, optional subtitle,
/// and a trailing widget or navigation chevron. It handles tap feedback
/// and theming automatically.
class SettingsTile extends StatelessWidget {
  /// The icon to display on the left side of the tile.
  final IconData icon;

  /// The primary text label for the setting.
  final String title;

  /// Optional secondary text displayed below the [title].
  final String? subtitle;

  /// An optional widget to display at the end of the tile, replacing the default chevron.
  final Widget? trailing;

  /// The callback function to execute when the tile is tapped. If null, the tile is not interactive.
  final VoidCallback? onTap;

  /// An optional color for the icon and its background highlight. Defaults to the theme's primary color.
  final Color? iconColor;

  /// Creates a settings list tile.
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final accentColor = iconColor ?? colorScheme.primary;

    final double iconBgAlpha = isDark ? 0.1 : 0.15;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null
            ? () {
          Logger.info('Tapped on settings tile: "$title"');
          HapticFeedback.lightImpact();
          onTap!();
        }
            : null,
        splashColor: accentColor.withValues(alpha: 0.1),
        highlightColor: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon Layout
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: iconBgAlpha),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.transparent
                        : accentColor.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: isDark
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: isDark ? 0.7 : 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing logic
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}