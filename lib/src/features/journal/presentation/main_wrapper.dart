import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'dart:ui';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/notification_provider.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'add_entry_screen.dart';

class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setPage(int index) => state = index;
}

final navigationProvider = NotifierProvider<NavigationNotifier, int>(() {
  return NavigationNotifier();
});

class MainWrapper extends ConsumerWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // ✅ LOGICA DE ACTUALIZARE AUTOMATĂ A NOTIFICĂRILOR LA SCHIMBAREA LIMBII
    ref.listen(localeProvider, (previous, next) {
      if (previous != null && next != previous) {
        final notifState = ref.read(notificationsEnabledProvider);
        if (notifState.isEnabled) {
          // Re-apelăm updateSettings care va încărca l10n pentru noua limbă 'next'
          ref.read(notificationsEnabledProvider.notifier).updateSettings(
              true,
              notifState.hour,
              notifState.minute
          );
        }
      }
    });

    final List<Widget> screens = [
      const HomeScreen(),
      const Center(child: Text("Stats coming soon")),
      const Center(child: Text("Video Recap coming soon")),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: screens,
          ),
          _buildFloatingDock(context, ref, isDark, selectedIndex, colorScheme),
        ],
      ),
    );
  }

  Widget _buildFloatingDock(BuildContext context, WidgetRef ref, bool isDark, int currentIndex, ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 34, left: 24, right: 24),
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(isDark ? 0.7 : 0.85),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _dockIcon(ref, Icons.grid_view_rounded, currentIndex == 0, 0, colorScheme),
                  _dockIcon(ref, Icons.bar_chart_rounded, currentIndex == 1, 1, colorScheme),
                  _buildAddButton(context, colorScheme),
                  _dockIcon(ref, Icons.movie_filter_rounded, currentIndex == 2, 2, colorScheme),
                  _dockIcon(ref, Icons.settings_rounded, currentIndex == 3, 3, colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEntryScreen())
        );
      },
      child: Hero(
        tag: 'add_button',
        child: Container(
          height: 54, width: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _dockIcon(WidgetRef ref, IconData icon, bool isSelected, int index, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(navigationProvider.notifier).setPage(index);
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: colorScheme.primary.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  icon,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
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
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}