import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../l10n/app_localizations.dart';
import '../../settings/providers/theme_provider.dart';
import '../../../core/utils/auth_wrapper.dart';
import '../../journal/presentation/main_wrapper.dart';

/// Screen responsible for introducing new users to the application's core value propositions.
///
/// Handles onboarding state persistence and navigation to the main application wrapper.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Creates an [OnboardingScreen].
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Updates the current page index state.
  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  /// Finalizes the onboarding process by persisting completion state and navigating.
  Future<void> _finishOnboarding() async {
    HapticFeedback.mediumImpact();

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthWrapper(child: MainWrapper()),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Define slides dynamically to support localization context
    final List<_OnboardingSlideData> slides = [
      _OnboardingSlideData(
        icon: Icons.auto_stories_rounded,
        title: l10n.onboardingTitle1,
        description: l10n.onboardingDesc1,
        accentColor: const Color(0xFF6366F1),
      ),
      _OnboardingSlideData(
        icon: Icons.lock_outline_rounded,
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDesc2,
        accentColor: const Color(0xFF14B8A6),
      ),
    ];

    final isLastPage = _currentPage == slides.length - 1;
    final currentAccent = slides[_currentPage].accentColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            top: -100,
            left: _currentPage % 2 == 0 ? -100 : null,
            right: _currentPage % 2 != 0 ? -100 : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    currentAccent.withOpacityDouble(0.2),
                    currentAccent.withOpacityDouble(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isLastPage
                        ? const SizedBox(height: 48)
                        : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextButton(
                        onPressed: _finishOnboarding,
                        child: Text(
                          l10n.onboardingSkip,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacityDouble(0.6),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 450,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: slides.length,
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.hasClients && _pageController.position.haveDimensions) {
                            final page = _pageController.page ?? _pageController.initialPage.toDouble();
                            value = (page - index).abs();
                            value = (1 - (value * 0.3)).clamp(0.7, 1.0);
                          }
                          return Opacity(
                            opacity: value,
                            child: Transform.scale(
                              scale: Curves.easeOut.transform(value),
                              child: child,
                            ),
                          );
                        },
                        child: _OnboardingSlide(key: ValueKey(index), data: slides[index]),
                      );
                    },
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: List.generate(slides.length, (index) {
                            final isActive = index == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.only(right: 8),
                              height: 8,
                              width: isActive ? 32 : 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? currentAccent
                                    : theme.colorScheme.onSurface.withOpacityDouble(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),
                      const Gap(16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 64, maxWidth: 200),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(opacity: animation, child: child),
                            );
                          },
                          child: isLastPage
                              ? _StartButton(
                            key: const ValueKey('start'),
                            color: currentAccent,
                            label: l10n.onboardingStart,
                            onPressed: _finishOnboarding,
                          )
                              : _NextButton(
                            key: const ValueKey('next'),
                            color: currentAccent,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutCubic,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal data model for onboarding slides.
class _OnboardingSlideData {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;

  const _OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}

/// Visual representation of a single onboarding slide.
class _OnboardingSlide extends StatelessWidget {
  final _OnboardingSlideData data;
  const _OnboardingSlide({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  data.accentColor.withOpacityDouble(0.15),
                  data.accentColor.withOpacityDouble(0.05),
                ],
              ),
              border: Border.all(color: data.accentColor.withOpacityDouble(0.3), width: 2),
            ),
            child: Icon(data.icon, size: 80, color: data.accentColor),
          ),
          const Gap(48),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.2,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Gap(16),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard navigation button for onboarding.
class _NextButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;

  const _NextButton({super.key, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          elevation: 8,
          shadowColor: color.withOpacityDouble(0.4),
        ),
        child: const Icon(Icons.arrow_forward_rounded, size: 28),
      ),
    );
  }
}

/// Final action button to complete onboarding.
class _StartButton extends StatelessWidget {
  final Color color;
  final String label;
  final VoidCallback onPressed;

  const _StartButton({
    super.key,
    required this.color,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (isSmallScreen) {
      return SizedBox(
        width: 64,
        height: 64,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            elevation: 8,
            shadowColor: color.withOpacityDouble(0.4),
          ),
          child: const Icon(Icons.check_rounded, size: 32),
        ),
      );
    }

    return Container(
      height: 64,
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 200),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: color.withOpacityDouble(0.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Gap(8),
            const Icon(Icons.arrow_forward_rounded, size: 24),
          ],
        ),
      ),
    );
  }
}

/// Extension to handle color opacity with modern alpha values.
extension ColorExt on Color {
  /// Returns a copy of this color with the given [opacity].
  Color withOpacityDouble(double opacity) => withAlpha((opacity * 255).round());
}