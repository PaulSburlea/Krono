import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/providers/theme_provider.dart';
import '../../../core/utils/notification_service.dart';
import '../../../core/utils/auth_wrapper.dart';
import '../../journal/presentation/main_wrapper.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlideData> _slides = [
    const _OnboardingSlideData(
      icon: Icons.auto_stories_rounded,
      title: "Your Life in Photos",
      description: "Capture one photo every day. Build a timeline of memories that you can cherish forever.",
      accentColor: Color(0xFF6366F1), // Indigo
    ),
    const _OnboardingSlideData(
      icon: Icons.lock_outline_rounded,
      title: "Private & Offline",
      description: "Your data stays on your device. Krono is designed with privacy first—no tracking, no cloud uploads.",
      accentColor: Colors.teal, // Emerald
    ),
    const _OnboardingSlideData(
      icon: Icons.notifications_active_rounded,
      title: "Never Miss a Day",
      description: "Consistency is key. Enable notifications to get a gentle reminder to capture your moment.",
      accentColor: Colors.orange, // Sunset
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  Future<void> _finishOnboarding() async {
    HapticFeedback.heavyImpact();

    // 1. Persist State
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    // 2. Navigate
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthWrapper(child: MainWrapper()),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _slides.length - 1;

    final currentAccent = _slides[_currentPage].accentColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. BACKGROUND GLOW
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            top: -100,
            left: _currentPage % 2 == 0 ? -100 : null,
            right: _currentPage % 2 != 0 ? -100 : null,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentAccent.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: currentAccent.withOpacity(0.2),
                    blurRadius: 120,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. SKIP BUTTON
                Align(
                  alignment: Alignment.topRight,
                  child: AnimatedOpacity(
                    opacity: isLastPage ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextButton(
                        onPressed: isLastPage ? null : _finishOnboarding,
                        child: Text(
                          "Skip",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // 3. SLIDES CAROUSEL
                SizedBox(
                  height: 450,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      return _OnboardingSlide(data: _slides[index]);
                    },
                  ),
                ),

                const Spacer(),

                // 4. BOTTOM CONTROLS
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page Indicators
                      Row(
                        children: List.generate(_slides.length, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: isActive ? 32 : 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? currentAccent
                                  : theme.colorScheme.onSurface.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      // Dynamic Action Button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        // Animăm lățimea de la cerc (64) la buton lat (160)
                        width: isLastPage ? 160 : 64,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isLastPage) {
                              _finishOnboarding();
                            } else {
                              HapticFeedback.lightImpact();
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutQuart,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isLastPage ? 20 : 32),
                            ),
                            elevation: 8,
                            shadowColor: currentAccent.withOpacity(0.5),
                          ),
                          // ✅ FIX: Folosim SingleChildScrollView pentru a preveni eroarea de Overflow
                          // în timpul animației de lățime.
                          child: isLastPage
                              ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Start",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                                Gap(8),
                                Icon(Icons.arrow_forward_rounded),
                              ],
                            ),
                          )
                              : const Icon(Icons.arrow_forward_rounded, size: 28),
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

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingSlideData data;

  const _OnboardingSlide({required this.data});

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
              color: data.accentColor.withOpacity(0.1),
              border: Border.all(
                color: data.accentColor.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              data.icon,
              size: 80,
              color: data.accentColor,
            ),
          ),
          const Gap(48),

          Text(
            data.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Gap(16),

          Text(
            data.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}