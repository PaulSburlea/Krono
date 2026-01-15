// custom_camera_screen.dart
// Full file - replace your CustomCameraScreen with this file.
// Uses a MethodChannel 'com.yourapp.volume' for native Android -> Flutter volume button events.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level isolate function for image processing & saving.
/// It's important that this is a top-level function for `compute`.
Future<String?> processAndSaveImage(dynamic rawArgs) async {
  try {
    final Map args = rawArgs as Map;
    final String path = args['path'] as String;
    final bool isFront = args['isFront'] as bool;
    final double aspect = args['aspect'] as double;

    final file = File(path);
    final bytes = await file.readAsBytes();
    img.Image? original = img.decodeImage(bytes);
    if (original == null) return path;

    img.Image processed = original;

    if (isFront) processed = img.flipHorizontal(processed);

    int targetWidth = processed.width;
    int targetHeight = (processed.width / aspect).round();

    if (targetHeight > processed.height) {
      targetHeight = processed.height;
      targetWidth = (targetHeight * aspect).round();
    }

    final int x = (processed.width - targetWidth) ~/ 2;
    final int y = (processed.height - targetHeight) ~/ 2;

    final img.Image cropped = img.copyCrop(processed, x: x, y: y, width: targetWidth, height: targetHeight);

    final jpg = img.encodeJpg(cropped, quality: 90);

    await file.writeAsBytes(jpg, flush: true);
    return path;
  } catch (e) {
    // On errors return original path so UI can still show something
    return (rawArgs is Map && rawArgs['path'] is String) ? rawArgs['path'] as String : null;
  }
}

class CustomCameraScreen extends StatefulWidget {
  const CustomCameraScreen({super.key});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;

  bool _isFlashOn = false;
  bool _isTakingPicture = false;
  bool _isGridEnabled = false;
  XFile? _capturedFile;
  // kept for potential internal use but not shown as a loading overlay
  bool _isProcessing = false;

  int _timerDuration = 0;
  int _currentCountdown = 0;
  bool _isCountingDown = false;
  Timer? _countdownTimer;

  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoomLevel = 1.0;
  double _baseScale = 1.0;

  // Focus & Exposure
  Offset? _focusPoint;
  bool _showFocusUI = false;
  bool _isFocusLocked = false;
  Timer? _focusTimer;
  Timer? _exposureTimer;

  double _realMinExposure = 0.0;
  double _realMaxExposure = 0.0;
  double _uiExposureLimit = 1.0;
  double _currentExposureOffset = 0.0;

  // Aspect ratio 3:4
  final double _targetAspectRatio = 3 / 4;

  // Zoom label
  bool _showZoomLabel = false;
  Timer? _zoomLabelTimer;

  // Exposure UI: dot only
  final bool _exposureSliderShowsSun = false;

  // Zoom presets
  List<double> _zoomPresets = <double>[];

  AnimationController? _zoomAnimationController;
  Animation<double>? _zoomAnimation;

  // MethodChannel for native volume button events
  static const MethodChannel _volumeChannel = MethodChannel('com.yourapp.volume');

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addObserver(this);

    // RawKeyboard fallback (some platforms/emulators)
    RawKeyboard.instance.addListener(_onRawKey);

    // set native MethodChannel handler
    _volumeChannel.setMethodCallHandler(_handleNativeMethodCall);

    _loadGridState();
    _initCamera();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.removeObserver(this);

    RawKeyboard.instance.removeListener(_onRawKey);

    // clear method handler
    _volumeChannel.setMethodCallHandler(null);

    _controller?.dispose();
    _focusTimer?.cancel();
    _exposureTimer?.cancel();
    _countdownTimer?.cancel();
    _zoomLabelTimer?.cancel();
    _zoomAnimationController?.dispose();
    super.dispose();
  }

  // Native -> Flutter handler (MethodChannel)
  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'volume') {
      // native sends int keyCode or string - we ignore details and just trigger photo
      _attemptTakePhoto();
    }
    return null;
  }

  void _onRawKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.audioVolumeUp || key == LogicalKeyboardKey.audioVolumeDown) {
        _attemptTakePhoto();
      }
    }
  }

  Future<void> _loadGridState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _isGridEnabled = prefs.getBool('isGridEnabled') ?? false);
  }

  Future<void> _toggleGrid() async {
    setState(() => _isGridEnabled = !_isGridEnabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGridEnabled', _isGridEnabled);
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    final preferredBack = _selectPreferredBackCamera(_cameras!);
    _selectedCameraIndex = _cameras!.indexOf(preferredBack);
    await _startCamera(preferredBack);
  }

  CameraDescription _selectPreferredBackCamera(List<CameraDescription> cams) {
    final backs = cams.where((c) => c.lensDirection == CameraLensDirection.back).toList();
    if (backs.isEmpty) return cams.first;
    final regexUltra = RegExp(r'ultra|ultrawide|0\.5|0_5|ultra-wide', caseSensitive: false);
    final nonUltra = backs.firstWhere((c) => !regexUltra.hasMatch(c.name), orElse: () => backs.first);
    return nonUltra;
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final old = _controller;
    _controller = null;
    await old?.dispose();

    final controller = CameraController(camera, ResolutionPreset.max, enableAudio: false);
    _controller = controller;

    try {
      await controller.initialize();
      controller.addListener(() {
        if (mounted) setState(() {}); // lightweight rebuild when controller changes
      });

      // small delay to ensure camera is stable
      await Future.delayed(const Duration(milliseconds: 120));
      await controller.setFlashMode(FlashMode.off);

      _minAvailableZoom = await controller.getMinZoomLevel();
      _maxAvailableZoom = await controller.getMaxZoomLevel();

      _zoomPresets = _computeFixedZoomPresets(_minAvailableZoom, _maxAvailableZoom);

      double startZoom = _clampDouble(1.0, _minAvailableZoom, _maxAvailableZoom);
      await controller.setZoomLevel(startZoom);
      _currentZoomLevel = startZoom;

      _realMinExposure = await controller.getMinExposureOffset();
      _realMaxExposure = await controller.getMaxExposureOffset();
      double symmetricalCap = math.min(_realMinExposure.abs(), _realMaxExposure.abs());
      if (symmetricalCap == 0) symmetricalCap = 1.0;
      _uiExposureLimit = symmetricalCap;
      _currentExposureOffset = 0.0;
      await controller.setExposureOffset(0.0);

      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  List<double> _computeFixedZoomPresets(double minZoom, double maxZoom) {
    final List<double> out = [];
    double v = 1.0;
    if (v < minZoom) v = minZoom;
    if (v <= maxZoom) out.add(double.parse(v.toStringAsFixed(2)));

    final candidates = [2.0, 4.0, 8.0];
    for (final c in candidates) {
      if (c <= maxZoom) out.add(double.parse(c.toStringAsFixed(2)));
    }

    final roundedMax = double.parse(maxZoom.toStringAsFixed(2));
    if (!out.contains(roundedMax)) out.add(roundedMax);

    final uniq = out.toSet().toList()..sort();
    return uniq;
  }

  double _clampDouble(double v, double min, double max) => v < min ? min : (v > max ? max : v);

  // Zoom logic: pinch supports continuous zoom (no snapping)
  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentZoomLevel;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (_controller == null) return;
    double scale = _baseScale * details.scale;
    scale = scale.clamp(_minAvailableZoom, _maxAvailableZoom);
    if ((scale - _currentZoomLevel).abs() > 0.01) {
      setState(() {
        _currentZoomLevel = scale;
        _showZoomLabel = true;
      });

      _startZoomLabelTimer();

      try {
        await _controller!.setZoomLevel(scale);
      } catch (_) {}
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    // do NOT snap to presets after pinch (user requested continuous values like 1.8x)
  }

  void _startZoomLabelTimer() {
    _zoomLabelTimer?.cancel();
    _zoomLabelTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showZoomLabel = false);
    });
  }

  void _animateZoomTo(double target) {
    if (_controller == null) return;
    _zoomAnimationController?.stop();
    _zoomAnimationController?.dispose();

    _zoomAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    final start = _currentZoomLevel;
    _zoomAnimation = Tween<double>(begin: start, end: target).animate(CurvedAnimation(parent: _zoomAnimationController!, curve: Curves.easeOut));

    // Ensure label visible during animation
    setState(() => _showZoomLabel = true);
    _startZoomLabelTimer();

    _zoomAnimationController!.addListener(() {
      final v = _zoomAnimation!.value;
      try {
        _controller?.setZoomLevel(v);
      } catch (_) {}
      if (mounted) setState(() => _currentZoomLevel = v);
    });

    _zoomAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        _zoomAnimationController?.dispose();
        _zoomAnimationController = null;
      }
    });

    _zoomAnimationController!.forward();
  }

  // Focus & exposure
  void _onTapToFocus(TapUpDetails details, BoxConstraints constraints) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isFocusLocked || _currentExposureOffset != 0.0) {
      setState(() {
        _isFocusLocked = false;
        _currentExposureOffset = 0.0;
      });
      _controller!.setFocusMode(FocusMode.auto);
      _controller!.setExposureMode(ExposureMode.auto);
      _controller!.setExposureOffset(0.0);
    }

    _runFocusLogic(details.localPosition, constraints);
  }

  void _onLongPressLock(LongPressStartDetails details, BoxConstraints constraints) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    HapticFeedback.heavyImpact();
    setState(() => _isFocusLocked = true);
    _runFocusLogic(details.localPosition, constraints);
    _controller!.setFocusMode(FocusMode.locked);
    _controller!.setExposureMode(ExposureMode.locked);
  }

  void _runFocusLogic(Offset offset, BoxConstraints constraints) {
    final double x = offset.dx / constraints.maxWidth;
    final double y = offset.dy / constraints.maxHeight;

    if (!_isFocusLocked) {
      _controller!.setFocusPoint(Offset(x, y));
      _controller!.setExposurePoint(Offset(x, y));
    }

    setState(() {
      _focusPoint = offset;
      _showFocusUI = true;
    });
    _startHideUITimers();
  }

  Future<void> _setExposureOffset(double value) async {
    if (_controller == null) return;
    setState(() => _currentExposureOffset = value);
    await _controller!.setExposureOffset(value.clamp(_realMinExposure, _realMaxExposure));
    _startHideUITimers();
  }

  void _startHideUITimers() {
    _focusTimer?.cancel();
    _exposureTimer?.cancel();

    if (_isFocusLocked) return;

    _exposureTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showFocusUI = false);
    });
  }

  // Capture & timer
  void _toggleTimer() {
    setState(() {
      if (_timerDuration == 0) _timerDuration = 3;
      else if (_timerDuration == 3) _timerDuration = 10;
      else _timerDuration = 0;
    });
  }

  void _attemptTakePhoto() {
    if (_isTakingPicture || _isCountingDown) return;

    if (_timerDuration > 0) {
      setState(() {
        _isCountingDown = true;
        _currentCountdown = _timerDuration;
      });
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_currentCountdown > 1) {
          setState(() => _currentCountdown--);
          HapticFeedback.selectionClick();
        } else {
          timer.cancel();
          setState(() => _isCountingDown = false);
          _takePicture();
        }
      });
    } else {
      _takePicture();
    }
  }

  /// New behavior: show captured image immediately (no loading overlay).
  /// Processing still done in isolate; when done we swap the file path.
  Future<void> _takePicture() async {
    if (_controller == null) return;
    HapticFeedback.heavyImpact();

    try {
      setState(() {
        _isTakingPicture = true;
      });

      final XFile image = await _controller!.takePicture();

      // Immediately show preview using the raw image path so user sees the photo instantly.
      setState(() {
        _capturedFile = image;
      });

      // Process in isolate (still awaited — doesn't block UI).
      final bool isFrontCamera = _cameras![_selectedCameraIndex].lensDirection == CameraLensDirection.front;

      // mark internal processing flag (not used to show overlay)
      _isProcessing = true;
      final processedPath = await compute(processAndSaveImage, {
        'path': image.path,
        'isFront': isFrontCamera,
        'aspect': _targetAspectRatio,
      });
      _isProcessing = false;

      // If processedPath differs, update the preview to the processed file.
      if (processedPath != null && processedPath != image.path) {
        if (mounted) {
          setState(() {
            _capturedFile = XFile(processedPath);
          });
        }
      }

      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    } catch (e) {
      setState(() {
        _isTakingPicture = false;
        _isProcessing = false;
      });
      debugPrint("Eroare poză: $e");
    }
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.isEmpty) return;

    HapticFeedback.lightImpact();
    final current = _cameras![_selectedCameraIndex];

    if (current.lensDirection == CameraLensDirection.back) {
      final front = _cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => current);
      _selectedCameraIndex = _cameras!.indexOf(front);
      _isFocusLocked = false;
      _startCamera(front);
      return;
    } else {
      final preferredBack = _selectPreferredBackCamera(_cameras!);
      _selectedCameraIndex = _cameras!.indexOf(preferredBack);
      _isFocusLocked = false;
      _startCamera(preferredBack);
      return;
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp || event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
        _attemptTakePhoto();
      }
    }
  }

  void _onPresetTap(int index) {
    if (_zoomPresets.isEmpty || index < 0 || index >= _zoomPresets.length) return;
    final value = _zoomPresets[index];
    _animateZoomTo(value);
    HapticFeedback.selectionClick();
    // show label while animating
    setState(() => _showZoomLabel = true);
    _startZoomLabelTimer();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    if (_capturedFile != null) {
      return _buildReviewUI(primaryColor);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    // put preview a bit higher (y = -0.12)
    final targetHeight = (screenWidth / _targetAspectRatio) - 28.0;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Move preview up a bit using Align
            Align(
              alignment: const Alignment(0, -0.12),
              child: SizedBox(
                width: screenWidth,
                height: targetHeight,
                child: ClipRect(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: ClipRect(
                              child: OverflowBox(
                                maxWidth: constraints.maxWidth,
                                maxHeight: constraints.maxHeight,
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: constraints.maxWidth,
                                    height: constraints.maxHeight,
                                    child: CameraPreview(_controller!),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onScaleStart: _handleScaleStart,
                            onScaleUpdate: _handleScaleUpdate,
                            onScaleEnd: _handleScaleEnd,
                            onTapUp: (details) => _onTapToFocus(details, constraints),
                            onLongPressStart: (details) => _onLongPressLock(details, constraints),
                          ),

                          if (_isGridEnabled)
                            IgnorePointer(child: CustomPaint(size: Size.infinite, painter: _GridPainter())),

                          if (_focusPoint != null && _showFocusUI) ...[
                            Positioned(
                              left: 0, top: 0, right: 0, bottom: 0,
                              child: IgnorePointer(child: CustomPaint(painter: _FocusOverlayPainter(focusPoint: _focusPoint!, isLocked: _isFocusLocked, showInnerDot: !_exposureSliderShowsSun))),
                            ),

                            Positioned(
                              left: _focusPoint!.dx - 55,
                              top: _focusPoint!.dy + 55,
                              child: SizedBox(
                                width: 110,
                                height: 40,
                                child: _SplitTrackSlider(
                                  value: _currentExposureOffset,
                                  min: -_uiExposureLimit,
                                  max: _uiExposureLimit,
                                  showSun: _exposureSliderShowsSun,
                                  onChanged: _setExposureOffset,
                                  onChangeEnd: (_) => _startHideUITimers(),
                                ),
                              ),
                            ),
                          ]
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Preset zoom buttons — positioned above shutter (avoid overlapping preview)
            Positioned(
              bottom: 120, // above shutter area
              left: 0,
              right: 0,
              child: Center(child: _buildZoomPresetRow()),
            ),

            // Zoom label: positioned JUST above presets to avoid overlapping preview border
            if (_showZoomLabel)
              Positioned(
                bottom: 170,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      final resetZoom = _clampDouble(1.0, _minAvailableZoom, _maxAvailableZoom);
                      _animateZoomTo(resetZoom);
                      setState(() => _showZoomLabel = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                      child: Text("${_formatZoomLabel(_currentZoomLevel)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                ),
              ),

            if (_isCountingDown)
              Center(child: Text("$_currentCountdown", style: const TextStyle(color: Colors.white, fontSize: 120, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 4))]))),

            // NOTE: removed the processing overlay so photo appears instantly

            // Controls
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _GlassIconButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
                        _GlassIconButton(
                          icon: _timerDuration == 0 ? Icons.timer_off_rounded : _timerDuration == 3 ? Icons.timer_3_rounded : Icons.timer_10_rounded,
                          color: Colors.white,
                          onTap: _toggleTimer,
                        ),
                        _GlassIconButton(
                          icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _isFlashOn ? Colors.yellow : Colors.white,
                          onTap: () {
                            setState(() => _isFlashOn = !_isFlashOn);
                            _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _GlassIconButton(icon: _isGridEnabled ? Icons.grid_4x4_rounded : Icons.grid_off_rounded, color: Colors.white, onTap: _toggleGrid),
                        GestureDetector(onTap: _attemptTakePhoto, child: _ShutterButton(isRecording: _isTakingPicture)),
                        _GlassIconButton(icon: Icons.flip_camera_ios_rounded, size: 50, onTap: _switchCamera),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatZoomLabel(double v) {
    if ((v - v.truncate()).abs() < 0.001) {
      return "${v.toStringAsFixed(0)}x";
    } else if ((v * 10 - (v * 10).truncate()).abs() < 0.001) {
      return "${v.toStringAsFixed(1)}x";
    } else {
      return "${v.toStringAsFixed(2)}x";
    }
  }

  Widget _buildZoomPresetRow() {
    if (_zoomPresets.isEmpty) return const SizedBox.shrink();
    final visible = _zoomPresets.take(4).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < visible.length; i++) ...[
            _zoomPresetChip(visible[i], selected: (_currentZoomLevel - visible[i]).abs() < 0.25, onTap: () {
              _onPresetTap(_zoomPresets.indexOf(visible[i]));
            }),
          ]
        ],
      ),
    );
  }

  Widget _zoomPresetChip(double value, {required bool selected, required VoidCallback onTap}) {
    final label = "${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}x";
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? Colors.white : Colors.white.withOpacity(0.12)),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildReviewUI(Color primaryColor) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: Image.file(File(_capturedFile!.path), fit: BoxFit.contain)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                height: 160,
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent]))),
          ),
          Positioned(
            bottom: 50, left: 40, right: 40,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _TextActionButton(icon: Icons.refresh_rounded, label: "Refă", onTap: () => setState(() => _capturedFile = null)),
              _TextActionButton(icon: Icons.check_circle_rounded, label: "Salvează", color: primaryColor, isPrimary: true, onTap: () => Navigator.pop(context, _capturedFile!.path)),
            ]),
          ),
        ],
      ),
    );
  }
}

// UI helper widgets below: Slider, Focus painter, buttons (unchanged from previous)
class _SplitTrackSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final bool showSun;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _SplitTrackSlider({required this.value, required this.min, required this.max, required this.showSun, required this.onChanged, required this.onChangeEnd});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(trackHeight: 1.5, thumbShape: const _MinimalSunThumbShape(), trackShape: _SplitTrackShape(showSun: showSun), overlayShape: SliderComponentShape.noOverlay, activeTrackColor: Colors.white, inactiveTrackColor: Colors.white.withOpacity(0.5), thumbColor: Colors.white),
      child: Slider(value: value, min: min, max: max, onChanged: onChanged, onChangeEnd: onChangeEnd),
    );
  }
}

class _SplitTrackShape extends SliderTrackShape {
  final bool showSun;
  const _SplitTrackShape({this.showSun = false});
  @override
  Rect getPreferredRect({required RenderBox parentBox, Offset offset = Offset.zero, required SliderThemeData sliderTheme, bool isEnabled = false, bool isDiscrete = false}) {
    final double trackHeight = sliderTheme.trackHeight!;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(PaintingContext context, Offset offset, {required RenderBox parentBox, required SliderThemeData sliderTheme, required Animation<double> enableAnimation, required TextDirection textDirection, required Offset thumbCenter, bool isEnabled = false, bool isDiscrete = false, Offset? secondaryOffset}) {
    final Canvas canvas = context.canvas;
    final Rect trackRect = getPreferredRect(parentBox: parentBox, offset: offset, sliderTheme: sliderTheme);
    final Paint paint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.0;
    if (!showSun) {
      canvas.drawLine(Offset(trackRect.left, trackRect.center.dy), Offset(trackRect.right, trackRect.center.dy), paint);
      return;
    }
    // Sun branch (unused)
    const double sunRadius = 6.0;
    const double sunPadding = 8.0;
    final double centerX = trackRect.center.dx;
    final double centerY = trackRect.center.dy;
    if (centerX - (sunRadius + sunPadding) > trackRect.left) canvas.drawLine(Offset(trackRect.left, trackRect.center.dy), Offset(centerX - (sunRadius + sunPadding), trackRect.center.dy), paint);
    if (centerX + (sunRadius + sunPadding) < trackRect.right) canvas.drawLine(Offset(centerX + (sunRadius + sunPadding), trackRect.center.dy), Offset(trackRect.right, trackRect.center.dy), paint);
    final Paint sunPaint = Paint()..color = Colors.yellow..style = PaintingStyle.fill;
    final Paint rayPaint = Paint()..color = Colors.yellow..strokeWidth = 1.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(centerX, centerY), sunRadius, sunPaint);
    for (int i = 0; i < 8; i++) {
      final double angle = i * (math.pi / 4);
      final double fromRadius = sunRadius + 2;
      final double toRadius = sunRadius + 8;
      final Offset from = Offset(centerX + math.cos(angle) * fromRadius, centerY + math.sin(angle) * fromRadius);
      final Offset to = Offset(centerX + math.cos(angle) * toRadius, centerY + math.sin(angle) * toRadius);
      canvas.drawLine(from, to, rayPaint);
    }
  }
}

class _MinimalSunThumbShape extends SliderComponentShape {
  const _MinimalSunThumbShape();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(20, 20);

  @override
  void paint(PaintingContext context, Offset center, {required Animation<double> activationAnimation, required Animation<double> enableAnimation, required bool isDiscrete, required TextPainter labelPainter, required RenderBox parentBox, required SliderThemeData sliderTheme, required TextDirection textDirection, required double value, required double textScaleFactor, required Size sizeWithOverflow}) {
    final Canvas canvas = context.canvas;
    canvas.drawCircle(center, 8.0, Paint()..color = Colors.black.withOpacity(0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawCircle(center, 7.0, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(center, 7.0, Paint()..color = Colors.black.withOpacity(0.05)..style = PaintingStyle.stroke..strokeWidth = 0.5);
  }
}

// Focus overlay painter
class _FocusOverlayPainter extends CustomPainter {
  final Offset focusPoint;
  final bool isLocked;
  final bool showInnerDot;
  _FocusOverlayPainter({required this.focusPoint, required this.isLocked, this.showInnerDot = true});

  @override
  void paint(Canvas canvas, Size size) {
    final color = isLocked ? Colors.yellow : Colors.white;
    final paint = Paint()..color = color.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawCircle(focusPoint, 35, paint);
    if (showInnerDot) {
      final Paint dotPaint = Paint()..color = (isLocked ? Colors.yellow : Colors.white)..style = PaintingStyle.fill;
      canvas.drawCircle(focusPoint, 4.0, dotPaint);
    }
    if (isLocked) {
      final paintBg = Paint()..color = Colors.yellow..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(focusPoint.dx, focusPoint.dy - 40), 9, paintBg);
      TextPainter textPainter = TextPainter(text: TextSpan(text: String.fromCharCode(Icons.lock_rounded.codePoint), style: TextStyle(fontSize: 11, fontFamily: Icons.lock_rounded.fontFamily, color: Colors.black)), textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(focusPoint.dx - 5.5, focusPoint.dy - 45.5));
    }
  }

  @override
  bool shouldRepaint(covariant _FocusOverlayPainter old) => old.focusPoint != focusPoint || old.isLocked != isLocked || old.showInnerDot != showInnerDot;
}

// Helper painters & UI widgets
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShutterButton extends StatelessWidget {
  final bool isRecording;
  const _ShutterButton({required this.isRecording});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 80,
      width: 80,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 5), color: Colors.white.withOpacity(0.2)),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isRecording ? 30 : 64,
          width: isRecording ? 30 : 64,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(isRecording ? 4 : 50)),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;
  const _GlassIconButton({required this.icon, required this.onTap, this.color = Colors.white, this.size = 44});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(width: size, height: size, color: Colors.black.withOpacity(0.3), child: Icon(icon, color: color, size: size * 0.55)),
      ),
    );
  }
}

class _TextActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isPrimary;
  const _TextActionButton({required this.icon, required this.label, required this.onTap, this.color = Colors.white, this.isPrimary = false});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isPrimary ? color : Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: isPrimary ? Colors.white : Colors.white, size: 32)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
