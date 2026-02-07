import 'dart:math' as math;
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

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Animation controllers for background effects
  late final AnimationController _bgAnimController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnimController.dispose();
    _pulseController.dispose();
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
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Define slides - colors are static, only text needs localization
    final List<_OnboardingSlideData> slides = [
      _OnboardingSlideData(
        icon: Icons.auto_stories_rounded,
        title: l10n.onboardingTitle1,
        description: l10n.onboardingDesc1,
        accentColor: const Color(0xFF6366F1),
        secondaryColor: const Color(0xFF8B5CF6),
      ),
      _OnboardingSlideData(
        icon: Icons.lock_outline_rounded,
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDesc2,
        accentColor: const Color(0xFF14B8A6),
        secondaryColor: const Color(0xFF06B6D4),
      ),
    ];

    final isLastPage = _currentPage == slides.length - 1;
    final currentSlide = slides[_currentPage];
    final currentAccent = currentSlide.accentColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive values
          final responsive = _ResponsiveOnboardingValues.from(
            constraints: constraints,
            context: context,
          );

          return Stack(
            children: [
              // Animated background gradients
              _AnimatedBackground(
                controller: _bgAnimController,
                currentPage: _currentPage,
                accentColor: currentAccent,
                secondaryColor: currentSlide.secondaryColor,
                responsive: responsive,
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Skip button
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(responsive.skipButtonPadding),
                        child: !isLastPage
                            ? TextButton(
                          onPressed: _finishOnboarding,
                          child: Text(
                            l10n.onboardingSkip,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withAlpha((0.6 * 255).round()),
                              fontWeight: FontWeight.w600,
                              fontSize: responsive.skipButtonFontSize,
                            ),
                          ),
                        )
                            : SizedBox(height: responsive.skipButtonPadding),
                      ),
                    ),

                    // Page content - fully flexible
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: slides.length,
                        itemBuilder: (context, index) {
                          return RepaintBoundary(
                            child: _OnboardingSlide(
                              key: ValueKey(index),
                              data: slides[index],
                              isActive: index == _currentPage,
                              responsive: responsive,
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom navigation
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.bottomPaddingHorizontal,
                        vertical: responsive.bottomPaddingVertical,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Page indicators
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: List.generate(slides.length, (index) {
                                final isActive = index == _currentPage;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  margin: EdgeInsets.only(
                                      right: responsive.indicatorSpacing),
                                  height: responsive.indicatorHeight,
                                  width: isActive
                                      ? responsive.indicatorActiveWidth
                                      : responsive.indicatorHeight,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? currentAccent
                                        : theme.colorScheme.onSurface
                                        .withAlpha((0.2 * 255).round()),
                                    borderRadius: BorderRadius.circular(
                                        responsive.indicatorHeight / 2),
                                  ),
                                );
                              }),
                            ),
                          ),
                          Gap(responsive.buttonGap),
                          // Action button
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: responsive.buttonMinWidth,
                              maxWidth: responsive.buttonMaxWidth,
                            ),
                            child: isLastPage
                                ? _StartButton(
                              color: currentAccent,
                              label: l10n.onboardingStart,
                              onPressed: _finishOnboarding,
                              responsive: responsive,
                            )
                                : _PulsingNextButton(
                              color: currentAccent,
                              pulseController: _pulseController,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _pageController.nextPage(
                                  duration:
                                  const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              responsive: responsive,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Responsive values calculator
class _ResponsiveOnboardingValues {
  final double width;
  final double height;
  final double textScale;
  final bool isTablet;
  final bool isSmallScreen;
  final bool isLandscape;

  // Skip button
  final double skipButtonPadding;
  final double skipButtonFontSize;

  // Bottom controls
  final double bottomPaddingHorizontal;
  final double bottomPaddingVertical;
  final double indicatorSpacing;
  final double indicatorHeight;
  final double indicatorActiveWidth;
  final double buttonGap;
  final double buttonMinWidth;
  final double buttonMaxWidth;
  final double buttonHeight;

  // Slide content
  final double contentPaddingHorizontal;
  final double contentPaddingVertical;
  final double iconSize;
  final double iconPadding;
  final double iconBlurRadius;
  final double gapAfterIcon;
  final double gapAfterTitle;
  final double titleFontSize;
  final double descriptionFontSize;

  // Background
  final double primaryOrbSize;
  final double secondaryOrbSize;

  _ResponsiveOnboardingValues._({
    required this.width,
    required this.height,
    required this.textScale,
    required this.isTablet,
    required this.isSmallScreen,
    required this.isLandscape,
    required this.skipButtonPadding,
    required this.skipButtonFontSize,
    required this.bottomPaddingHorizontal,
    required this.bottomPaddingVertical,
    required this.indicatorSpacing,
    required this.indicatorHeight,
    required this.indicatorActiveWidth,
    required this.buttonGap,
    required this.buttonMinWidth,
    required this.buttonMaxWidth,
    required this.buttonHeight,
    required this.contentPaddingHorizontal,
    required this.contentPaddingVertical,
    required this.iconSize,
    required this.iconPadding,
    required this.iconBlurRadius,
    required this.gapAfterIcon,
    required this.gapAfterTitle,
    required this.titleFontSize,
    required this.descriptionFontSize,
    required this.primaryOrbSize,
    required this.secondaryOrbSize,
  });

  factory _ResponsiveOnboardingValues.from({
    required BoxConstraints constraints,
    required BuildContext context,
  }) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final shortestSide = math.min(width, height);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    final isTablet = shortestSide >= 600;
    final isSmallScreen = shortestSide < 360;
    final isLandscape = width > height;

    // Base scale factor (0.8 - 1.3)
    final scaleFactor = (shortestSide / 375).clamp(0.8, 1.3);

    return _ResponsiveOnboardingValues._(
      width: width,
      height: height,
      textScale: textScale,
      isTablet: isTablet,
      isSmallScreen: isSmallScreen,
      isLandscape: isLandscape,

      // Skip button
      skipButtonPadding: isTablet ? 20.0 : 16.0,
      skipButtonFontSize: (16.0 * textScale).clamp(14.0, 18.0),

      // Bottom controls
      bottomPaddingHorizontal: isTablet
          ? 48.0
          : isSmallScreen
          ? 20.0
          : 32.0,
      bottomPaddingVertical: isTablet
          ? 32.0
          : isLandscape
          ? 16.0
          : 24.0,
      indicatorSpacing: isTablet ? 10.0 : 8.0,
      indicatorHeight: isTablet ? 9.0 : 8.0,
      indicatorActiveWidth: isTablet ? 36.0 : 32.0,
      buttonGap: 16.0,
      buttonMinWidth: isTablet ? 72.0 : 64.0,
      buttonMaxWidth: isTablet ? 220.0 : 200.0,
      buttonHeight: isTablet ? 68.0 : 64.0,

      // Slide content - critical for text visibility
      contentPaddingHorizontal: isTablet
          ? 64.0
          : isSmallScreen
          ? 24.0
          : 32.0,
      contentPaddingVertical: isLandscape ? 8.0 : 20.0,
      iconSize: isTablet
          ? 72.0
          : isLandscape
          ? 48.0
          : (56.0 * scaleFactor).clamp(48.0, 64.0),
      iconPadding: isTablet
          ? 28.0
          : isLandscape
          ? 20.0
          : (24.0 * scaleFactor).clamp(20.0, 28.0),
      iconBlurRadius: isTablet ? 35.0 : 28.0,
      gapAfterIcon: isTablet
          ? 32.0
          : isLandscape
          ? 12.0
          : (20.0 * scaleFactor).clamp(16.0, 28.0),
      gapAfterTitle: isTablet
          ? 14.0
          : isLandscape
          ? 8.0
          : (12.0 * scaleFactor).clamp(10.0, 14.0),
      titleFontSize: isTablet
          ? 28.0
          : isLandscape
          ? 20.0
          : (24.0 * scaleFactor).clamp(20.0, 28.0),
      descriptionFontSize: isTablet
          ? 16.0
          : isLandscape
          ? 13.0
          : (14.0 * scaleFactor).clamp(13.0, 16.0),

      // Background
      primaryOrbSize: isTablet ? 450.0 : 350.0,
      secondaryOrbSize: isTablet ? 350.0 : 280.0,
    );
  }
}

/// Internal data model for onboarding slides.
class _OnboardingSlideData {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final Color secondaryColor;

  const _OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.secondaryColor,
  });
}

/// Animated background component
class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final int currentPage;
  final Color accentColor;
  final Color secondaryColor;
  final _ResponsiveOnboardingValues responsive;

  const _AnimatedBackground({
    required this.controller,
    required this.currentPage,
    required this.accentColor,
    required this.secondaryColor,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          final sinValue = math.sin(value * math.pi * 2);
          final cosValue = math.cos(value * math.pi * 2);

          return Stack(
            children: [
              Positioned(
                top: -80 + sinValue * 20,
                left: currentPage % 2 == 0 ? -80 + cosValue * 30 : null,
                right: currentPage % 2 != 0 ? -80 + cosValue * 30 : null,
                child: _GradientOrb(
                  size: responsive.primaryOrbSize,
                  color: accentColor,
                  opacity: 0.25,
                ),
              ),
              Positioned(
                bottom: -120 + cosValue * 25,
                right: currentPage % 2 == 0 ? -100 + sinValue * 20 : null,
                left: currentPage % 2 != 0 ? -100 + sinValue * 20 : null,
                child: _GradientOrb(
                  size: responsive.secondaryOrbSize,
                  color: secondaryColor,
                  opacity: 0.15,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Gradient orb for background decoration.
class _GradientOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GradientOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withAlpha((opacity * 255).round()),
            color.withAlpha((opacity * 0.3 * 255).round()),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// Visual representation of a single onboarding slide.
class _OnboardingSlide extends StatefulWidget {
  final _OnboardingSlideData data;
  final bool isActive;
  final _ResponsiveOnboardingValues responsive;

  const _OnboardingSlide({
    super.key,
    required this.data,
    required this.isActive,
    required this.responsive,
  });

  @override
  State<_OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<_OnboardingSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final Animation<double> _iconAnimation;
  late final Animation<double> _titleAnimation;
  late final Animation<double> _descAnimation;

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _iconAnimation = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    );

    _titleAnimation = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    );

    _descAnimation = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );

    if (widget.isActive) {
      _staggerController.forward();
    }
  }

  @override
  void didUpdateWidget(_OnboardingSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _staggerController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = widget.responsive;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.contentPaddingHorizontal,
          vertical: responsive.contentPaddingVertical,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _iconAnimation,
                builder: (context, child) {
                  final opacity = _iconAnimation.value.clamp(0.0, 1.0);
                  final scale = 0.5 + (opacity * 0.5);

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        padding: EdgeInsets.all(responsive.iconPadding),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.data.accentColor
                                  .withAlpha((0.18 * 255).round()),
                              widget.data.accentColor
                                  .withAlpha((0.06 * 255).round()),
                            ],
                          ),
                          border: Border.all(
                            color: widget.data.accentColor
                                .withAlpha((0.4 * 255).round()),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.data.accentColor
                                  .withAlpha((0.25 * 255).round()),
                              blurRadius: responsive.iconBlurRadius,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.data.icon,
                          size: responsive.iconSize,
                          color: widget.data.accentColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Gap(responsive.gapAfterIcon),

            // Animated title
            AnimatedBuilder(
              animation: _titleAnimation,
              builder: (context, child) {
                final opacity = _titleAnimation.value.clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - opacity)),
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: Text(
                widget.data.title,
                textAlign: TextAlign.center,
                maxLines: responsive.isLandscape ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.2,
                  fontSize: responsive.titleFontSize,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            Gap(responsive.gapAfterTitle),

            // Animated description
            AnimatedBuilder(
              animation: _descAnimation,
              builder: (context, child) {
                final opacity = _descAnimation.value.clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - opacity)),
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: Text(
                widget.data.description,
                textAlign: TextAlign.center,
                maxLines: responsive.isLandscape ? 2 : 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                  fontSize: responsive.descriptionFontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pulsing next button with glow effect.
class _PulsingNextButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;
  final AnimationController pulseController;
  final _ResponsiveOnboardingValues responsive;

  const _PulsingNextButton({
    required this.color,
    required this.onPressed,
    required this.pulseController,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (context, child) {
          final pulseValue = Curves.easeInOut.transform(pulseController.value);
          final scale = 1.0 + (pulseValue * 0.06);
          final glowOpacity = 0.3 + (pulseValue * 0.2);

          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha((glowOpacity * 255).round()),
                    blurRadius: 20 + pulseValue * 10,
                    spreadRadius: pulseValue * 4,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: SizedBox(
          width: responsive.buttonHeight,
          height: responsive.buttonHeight,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
              elevation: 0,
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: responsive.isTablet ? 30.0 : 28.0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Final action button to complete onboarding.
class _StartButton extends StatelessWidget {
  final Color color;
  final String label;
  final VoidCallback onPressed;
  final _ResponsiveOnboardingValues responsive;

  const _StartButton({
    required this.color,
    required this.label,
    required this.onPressed,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    // Small screens get circular button
    if (responsive.isSmallScreen) {
      return SizedBox(
        width: responsive.buttonHeight,
        height: responsive.buttonHeight,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            elevation: 8,
            shadowColor: color.withAlpha((0.4 * 255).round()),
          ),
          child: Icon(
            Icons.check_rounded,
            size: responsive.isTablet ? 34.0 : 32.0,
          ),
        ),
      );
    }

    // Standard rounded button
    final buttonRadius = responsive.buttonHeight / 3;

    return Container(
      height: responsive.buttonHeight,
      constraints: BoxConstraints(
        minWidth: responsive.buttonMinWidth + 60,
        maxWidth: responsive.buttonMaxWidth,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(buttonRadius),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((0.4 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.isTablet ? 28.0 : 24.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: responsive.isTablet ? 19.0 : 18.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Gap(8),
            Icon(
              Icons.arrow_forward_rounded,
              size: responsive.isTablet ? 26.0 : 24.0,
            ),
          ],
        ),
      ),
    );
  }
}