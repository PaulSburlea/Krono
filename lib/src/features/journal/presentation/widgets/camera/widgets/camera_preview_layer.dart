import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'camera_ui_elements.dart';

/// A dedicated widget for rendering the camera preview stream and interactive overlays.
///
/// This component separates the rendering logic from the business logic of the
/// main camera screen. It is responsible for:
/// 1. Displaying the raw [CameraPreview] with a specific aspect ratio.
/// 2. Capturing gestures for focus (tap) and zoom (pinch).
/// 3. Rendering visual overlays such as the composition grid and focus/exposure UI.
class CameraPreviewLayer extends StatelessWidget {
  /// The controller managing the camera session.
  final CameraController? controller;

  /// Whether to display the rule-of-thirds grid overlay.
  final bool isGridEnabled;

  // --- Gesture Callbacks ---

  /// Callback triggered when a scale (pinch) gesture begins.
  final void Function(ScaleStartDetails) onScaleStart;

  /// Callback triggered when a scale (pinch) gesture updates.
  final void Function(ScaleUpdateDetails) onScaleUpdate;

  /// Callback triggered on a tap up event (used for focusing).
  final void Function(Offset, BoxConstraints) onTapUp;

  /// Callback triggered on a long press start (used for locking focus).
  final void Function(Offset, BoxConstraints) onLongPressStart;

  // --- Focus UI State ---

  /// The current screen coordinates of the focus point.
  final Offset? focusPoint;

  /// Whether the focus ring and exposure slider should be visible.
  final bool showFocusUI;

  /// Whether the focus/exposure is currently locked (AE/AF Lock).
  final bool isFocusLocked;

  /// Animation controller for the focus ring scaling effect.
  final Animation<double>? focusScaleAnimation;

  /// The current exposure offset value (EV).
  final double currentExposureOffset;

  /// The maximum allowed exposure offset for the UI slider.
  final double uiExposureLimit;

  /// Callback triggered when the exposure slider value changes.
  final ValueChanged<double> onExposureChanged;

  const CameraPreviewLayer({
    super.key,
    required this.controller,
    required this.isGridEnabled,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onTapUp,
    required this.onLongPressStart,
    required this.focusPoint,
    required this.showFocusUI,
    required this.isFocusLocked,
    required this.focusScaleAnimation,
    required this.currentExposureOffset,
    required this.uiExposureLimit,
    required this.onExposureChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetHeight = screenWidth / (3 / 4);

    return Align(
      alignment: const Alignment(0, -0.15),
      child: SizedBox(
        width: screenWidth,
        height: targetHeight,
        child: ClipRect(
          child: LayoutBuilder(builder: (context, constraints) {
            final isCameraReady = controller != null &&
                controller!.value.isInitialized &&
                !controller!.value.isRecordingVideo;

            return Stack(
              fit: StackFit.expand,
              children: [
                // Layer 1: Camera Preview Stream
                if (isCameraReady)
                // OPTIMIZATION: RepaintBoundary isolates the heavy texture rendering
                  RepaintBoundary(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxWidth * controller!.value.aspectRatio,
                        child: CameraPreview(controller!),
                      ),
                    ),
                  )
                else
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),

                // Layer 2: Gesture Detector (Zoom, Focus)
                if (isCameraReady)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: onScaleStart,
                    onScaleUpdate: onScaleUpdate,
                    onTapUp: (d) => onTapUp(d.localPosition, constraints),
                    onLongPressStart: (d) =>
                        onLongPressStart(d.localPosition, constraints),
                  ),

                // Layer 3: Grid Overlay
                if (isGridEnabled)
                  IgnorePointer(
                    // OPTIMIZATION: RepaintBoundary for static grid
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: GridPainter(),
                      ),
                    ),
                  ),

                // Layer 4: Focus & Exposure UI
                if (showFocusUI && focusPoint != null && isCameraReady) ...[
                  // Focus Ring
                  Positioned(
                    left: focusPoint!.dx - 50,
                    top: focusPoint!.dy - 50,
                    width: 100,
                    height: 100,
                    child: IgnorePointer(
                      child: ScaleTransition(
                        scale: focusScaleAnimation!,
                        child: CustomPaint(
                          painter: FocusOverlayPainter(
                            focusPoint: const Offset(50, 50),
                            isLocked: isFocusLocked,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Exposure Slider
                  Builder(builder: (context) {
                    // Determine if the slider should appear above or below the focus ring
                    // to avoid being cut off by the screen edge.
                    final bool showAbove =
                        focusPoint!.dy > constraints.maxHeight * 0.85;
                    return Positioned(
                      left: focusPoint!.dx - 55,
                      top: showAbove
                          ? focusPoint!.dy - 80
                          : focusPoint!.dy + 55,
                      child: ScaleTransition(
                        scale: focusScaleAnimation!,
                        child: SizedBox(
                          width: 110,
                          height: 40,
                          child: SplitTrackSlider(
                            value: currentExposureOffset,
                            min: -uiExposureLimit,
                            max: uiExposureLimit,
                            showSun: false,
                            onChanged: onExposureChanged,
                            onChangeEnd: (_) {},
                          ),
                        ),
                      ),
                    );
                  }),
                ]
              ],
            );
          }),
        ),
      ),
    );
  }
}