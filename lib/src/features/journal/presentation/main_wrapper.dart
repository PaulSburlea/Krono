import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../settings/providers/locale_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../settings/providers/theme_provider.dart';
import '../../../core/utils/logger_service.dart';

import 'home_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'widgets/add_button.dart';
import 'add_entry_screen.dart'; // Required for navigation

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
/// It handles the bottom navigation dock, screen switching, and global listeners.
/// It also checks for unfinished drafts on startup to restore the user's session.
class MainWrapper extends ConsumerStatefulWidget {
  /// Creates the main application wrapper.
  const MainWrapper({super.key});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  @override
  void initState() {
    super.initState();

    // Check for drafts immediately after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRestoreDraft();
    });
  }

  /// Checks if a draft exists and navigates to the AddEntryScreen if found.
  Future<void> _checkAndRestoreDraft() async {
    final prefs = ref.read(sharedPreferencesProvider);

    // Check if the specific draft key exists in storage
    if (prefs.containsKey('journal_draft')) {
      Logger.info('Unfinished draft detected on startup. Auto-navigating to AddEntryScreen.');

      if (!mounted) return;

      // Navigate instantly (zero duration) to make it feel like the app resumed state.
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AddEntryScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
    // ✅ Detectare text scale și dimensiune ecran
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final screenWidth = MediaQuery.sizeOf(context).width;

    // ✅ Calculare dimensiuni responsive
    final isLargeText = textScaleFactor > 1.15;
    final isSmallScreen = screenWidth < 360;

    // Dock height se adaptează la text scale
    final dockHeight = isLargeText
        ? 80.0
        : isSmallScreen
        ? 68.0
        : 72.0;

    // Border radius proporțional cu height
    final borderRadius = dockHeight / 2;

    // Horizontal padding se adaptează
    final horizontalPadding = isLargeText ? 12.0 : isSmallScreen ? 6.0 : 8.0;

    // Margin-uri responsive
    final horizontalMargin = isSmallScreen ? 16.0 : 24.0;

    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final double dockMarginBottom = systemBottomPadding > 0 ? systemBottomPadding + 20 : 24.0;

    final double opacity = 0.98;
    final Color glassBaseColor = colorScheme.surface;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.only(
          bottom: dockMarginBottom,
          left: horizontalMargin,
          right: horizontalMargin,
        ),
        height: dockHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              glassBaseColor.withValues(alpha: opacity),
              glassBaseColor.withValues(alpha: opacity - 0.03),
            ],
            stops: const [0.0, 1.0],
          ),
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
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DockItem(
                  icon: Icons.grid_view_rounded,
                  isSelected: currentIndex == 0,
                  onTap: () => _handleNav(ref, 0),
                  isLargeText: isLargeText,
                ),

                // The central AddButton imported from widgets/add_button.dart
                AddButton(isLargeText: isLargeText),

                _DockItem(
                  icon: Icons.settings_rounded,
                  isSelected: currentIndex == 3,
                  onTap: () => _handleNav(ref, 3),
                  isLargeText: isLargeText,
                ),
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
  final bool isLargeText;

  const _DockItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isLargeText = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // ✅ Icon size responsive
    final iconSize = isLargeText ? 28.0 : 26.0;

    // ✅ Padding responsive
    final horizontalPadding = isLargeText ? 14.0 : 12.0;
    final verticalPadding = isLargeText ? 10.0 : 8.0;

    // ✅ Indicator size
    final indicatorSize = isLargeText ? 5.0 : 4.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                  size: iconSize,
                ),
                const Gap(4),
                AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: indicatorSize,
                    width: indicatorSize,
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