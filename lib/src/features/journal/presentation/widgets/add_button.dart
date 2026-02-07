import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../settings/providers/theme_provider.dart';
import '../add_entry_screen.dart';
import 'camera/custom_camera_screen.dart';
import '../../../settings/presentation/widgets/notification_prompt_sheet.dart';

class AddButton extends ConsumerStatefulWidget {
  final bool isLargeText;

  const AddButton({super.key, this.isLargeText = false});

  @override
  ConsumerState<AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends ConsumerState<AddButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Checks if the user should be prompted to enable notifications.
  Future<void> _handlePostSavePrompt() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final hasPrompted = prefs.getBool('has_prompted_notification') ?? false;
    final isNotifEnabled = ref.read(notificationProvider).isEnabled;

    if (!hasPrompted && !isNotifEnabled) {
      Logger.info('Successful first entry. Showing notification prompt.');
      await prefs.setBool('has_prompted_notification', true);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const NotificationPromptSheet(),
      );
    }
  }

  Future<void> _navigateTo(Widget page) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
      ),
    );

    // If the screen returned 'true', it means an entry was saved.
    if (result == true) {
      _handlePostSavePrompt();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // ✅ Dimensiuni responsive bazate pe text scale
    final buttonSize = widget.isLargeText ? 58.0 : 56.0;
    final iconSize = widget.isLargeText ? 34.0 : 32.0;
    final blurRadius = widget.isLargeText ? 14.0 : 12.0;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.mediumImpact();
        _navigateTo(const AddEntryScreen());
      },
      onLongPress: () async {
        HapticFeedback.heavyImpact();
        _controller.reverse();

        final String? photoPath = await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const CustomCameraScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );

        if (photoPath != null && context.mounted) {
          _navigateTo(AddEntryScreen(initialImagePath: photoPath));
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Hero(
          tag: 'add_button_main',
          child: Container(
            height: buttonSize,
            width: buttonSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: blurRadius,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}