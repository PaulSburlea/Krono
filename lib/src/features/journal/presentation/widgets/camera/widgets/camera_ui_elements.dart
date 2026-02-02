import 'package:flutter/material.dart';

// --- BUTTONS ---

/// The primary trigger button for the camera.
///
/// Displays a circular shutter button that transforms into a loading indicator
/// when [isRecording] is true.
class ShutterButton extends StatelessWidget {
  /// Indicates if a capture or processing operation is currently in progress.
  ///
  /// When true, the button displays a [CircularProgressIndicator].
  /// When false, it displays the standard white shutter circle.
  final bool isRecording;

  const ShutterButton({super.key, required this.isRecording});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 5),
        color: Colors.white.withValues(alpha: 0.2),
      ),
      child: Center(
        child: isRecording
            ? const SizedBox(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        )
            : AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            // Currently configured for photo mode (circle).
            // If video mode is added later, this radius can be animated to 4.0.
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    );
  }
}

/// A circular button with a semi-transparent "frosted glass" background.
///
/// Used for secondary camera controls like flash toggle or camera switch.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          color: Colors.black.withValues(alpha: 0.3),
          child: Icon(icon, color: color, size: size * 0.55),
        ),
      ),
    );
  }
}

/// A vertical layout button containing an icon and a text label.
///
/// Primarily used in the post-capture review screen for "Retake" or "Save" actions.
class TextActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  /// If true, the button uses the [color] as its background to emphasize the primary action.
  final bool isPrimary;

  const TextActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPrimary ? color : Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// --- PAINTERS ---

/// Paints a "Rule of Thirds" grid overlay on the camera preview.
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw vertical lines
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * i / 3, 0),
        Offset(size.width * i / 3, size.height),
        paint,
      );
      // Draw horizontal lines
      canvas.drawLine(
        Offset(0, size.height * i / 3),
        Offset(size.width, size.height * i / 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Renders the visual feedback for focus and exposure locking.
///
/// Draws a ring at the [focusPoint] and optionally a lock icon if [isLocked] is true.
class FocusOverlayPainter extends CustomPainter {
  final Offset focusPoint;
  final bool isLocked;
  final bool showInnerDot;

  FocusOverlayPainter({
    required this.focusPoint,
    required this.isLocked,
    this.showInnerDot = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final color = isLocked ? Colors.yellow : Colors.white;

    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw the main focus ring
    canvas.drawCircle(focusPoint, 35, strokePaint);

    if (showInnerDot) {
      canvas.drawCircle(focusPoint, 4.0, fillPaint);
    }

    // Draw the lock indicator if focus/exposure is locked
    if (isLocked) {
      canvas.drawCircle(
        Offset(focusPoint.dx, focusPoint.dy - 40),
        10,
        Paint()..color = Colors.yellow,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.lock_rounded.codePoint),
          style: TextStyle(
            fontSize: 12,
            fontFamily: Icons.lock_rounded.fontFamily,
            color: Colors.black,
            package: Icons.lock_rounded.fontPackage,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(focusPoint.dx - 6, focusPoint.dy - 46));
    }
  }

  @override
  bool shouldRepaint(covariant FocusOverlayPainter old) =>
      old.focusPoint != focusPoint || old.isLocked != isLocked;
}

// --- SLIDER COMPONENTS ---

/// A custom slider widget designed for exposure compensation control.
///
/// Uses a minimal visual style with a split track and a sun-like thumb.
class SplitTrackSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final bool showSun;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const SplitTrackSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.showSun,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 1.5,
        thumbShape: const MinimalSunThumbShape(),
        trackShape: SplitTrackShape(showSun: showSun),
        overlayShape: SliderComponentShape.noOverlay,
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.5),
        thumbColor: Colors.white,
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}

/// A custom track shape for the slider that draws a simple line.
class SplitTrackShape extends SliderTrackShape {
  final bool showSun;
  const SplitTrackShape({this.showSun = false});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    return Rect.fromLTWH(
      offset.dx,
      offset.dy + (parentBox.size.height - trackHeight) / 2,
      parentBox.size.width,
      trackHeight,
    );
  }

  @override
  void paint(
      PaintingContext context,
      Offset offset, {
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required Animation<double> enableAnimation,
        required TextDirection textDirection,
        required Offset thumbCenter,
        bool isEnabled = false,
        bool isDiscrete = false,
        Offset? secondaryOffset,
      }) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    context.canvas.drawLine(
      Offset(offset.dx, thumbCenter.dy),
      Offset(offset.dx + parentBox.size.width, thumbCenter.dy),
      paint,
    );
  }
}

/// A custom thumb shape for the slider, rendered as a small filled circle.
class MinimalSunThumbShape extends SliderComponentShape {
  const MinimalSunThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(20, 20);

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    context.canvas.drawCircle(
      center,
      7.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }
}