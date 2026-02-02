import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../settings/providers/locale_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../settings/providers/theme_provider.dart';
import '../../../core/utils/logger_service.dart';

import '../../journal/presentation/add_entry_screen.dart';
import 'home_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'widgets/camera/custom_camera_screen.dart';

/// Manages the state of the bottom navigation bar index.
class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Updates the currently selected page index.
  void setPage(int index) {
    Logger.info('Navigation changed to page index: $index');
    state = index;
  }
}

/// Provides the current navigation index to the UI.
final navigationProvider = NotifierProvider<NavigationNotifier, int>(NavigationNotifier.new);

/// The main wrapper widget for the application's core screens.
///
/// It handles the bottom navigation dock, screen switching, and global listeners
/// for locale and theme changes. It uses an [IndexedStack] to preserve the state
/// of each screen.
class MainWrapper extends ConsumerWidget {
  /// Creates the main application wrapper.
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationProvider);

    // Listen to theme changes to trigger a rebuild of the dock when switching modes.
    ref.watch(themeNotifierProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    _setupLocaleListener(ref);

    final List<Widget> screens = [
      const HomeScreen(),
      const Center(child: Text("Stats coming soon")), // Placeholder
      const Center(child: Text("Video Recap coming soon")), // Placeholder
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true, // Allows content to flow behind the floating dock.
      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: screens,
          ),
          _FloatingDock(
            currentIndex: selectedIndex,
            isDark: isDark,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  /// Sets up a listener to refresh notifications when the app locale changes.
  void _setupLocaleListener(WidgetRef ref) {
    ref.listen(localeProvider, (previous, next) {
      if (previous != null && next != previous) {
        Logger.info('Locale changed from ${previous.languageCode} to ${next.languageCode}. Updating notifications.');
        final notifState = ref.read(notificationProvider);
        if (notifState.isEnabled) {
          ref.read(notificationProvider.notifier).updateSettings(
              true,
              notifState.hour,
              notifState.minute,
              force: true
          );
        }
      }
    });
  }
}

/// A custom floating bottom navigation dock with a "fake glass" effect.
///
/// It uses opacity and gradients to simulate a glass look without the performance
/// cost of a real-time blur filter.
class _FloatingDock extends ConsumerWidget {
  final int currentIndex;
  final bool isDark;
  final ColorScheme colorScheme;

  const _FloatingDock({
    required this.currentIndex,
    required this.isDark,
    required this.colorScheme
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final double dockMarginBottom = systemBottomPadding > 0 ? systemBottomPadding + 20 : 24.0;

    // Increased opacity for a more matte, solid feel
    final double opacity = isDark ? 0.98 : 0.98;
    final Color glassBaseColor = colorScheme.surface;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.only(bottom: dockMarginBottom, left: 24, right: 24),
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          // Subtle gradient for a "frosted" look without being too transparent
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              glassBaseColor.withValues(alpha: opacity),
              glassBaseColor.withValues(alpha: opacity - 0.03),
            ],
            stops: const [0.0, 1.0],
          ),
          // A subtle border to define the edges like real glass
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DockItem(icon: Icons.grid_view_rounded, isSelected: currentIndex == 0, onTap: () => _handleNav(ref, 0)),

                // Stats button placeholder (commented out as per requirements)
                /*
                _DockItem(icon: Icons.bar_chart_rounded, isSelected: currentIndex == 1, onTap: () => _handleNav(ref, 1)),
                */

                const _AddButton(),

                // Video Recap button placeholder (commented out as per requirements)
                /*
                _DockItem(icon: Icons.movie_filter_rounded, isSelected: currentIndex == 2, onTap: () => _handleNav(ref, 2)),
                */

                _DockItem(icon: Icons.settings_rounded, isSelected: currentIndex == 3, onTap: () => _handleNav(ref, 3)),
              ]
          ),
        ),
      ),
    );
  }

  void _handleNav(WidgetRef ref, int index) {
    HapticFeedback.selectionClick();
    ref.read(navigationProvider.notifier).setPage(index);
  }
}

/// An individual item within the floating dock.
class _DockItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DockItem({required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    icon,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 26
                ),
                const Gap(4),
                AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    width: 4,
                    decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primary : Colors.transparent,
                        shape: BoxShape.circle
                    )
                ),
              ]
          ),
        ),
      ),
    );
  }
}

/// The central "Add" button in the dock.
///
/// Supports a short tap to open the standard add entry screen, and a long press
/// to quickly launch the camera.
class _AddButton extends StatelessWidget {
  const _AddButton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Logger.info('User tapped Add button (standard entry).');
        HapticFeedback.heavyImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEntryScreen()));
      },
      onLongPress: () async {
        Logger.info('User long-pressed Add button (quick camera).');
        HapticFeedback.heavyImpact();

        final String? photoPath = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomCameraScreen()),
        );

        if (photoPath != null && context.mounted) {
          Logger.info('Photo captured via quick camera, navigating to AddEntryScreen.');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEntryScreen(initialImagePath: photoPath),
            ),
          );
        }
      },
      child: Hero(
        tag: 'add_button_main',
        child: Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6)
              )
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}