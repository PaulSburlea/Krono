import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/utils/logger_service.dart';
import 'image_processor.dart';
import 'widgets/camera_preview_layer.dart';
import 'widgets/camera_review_view.dart';
import 'widgets/camera_ui_elements.dart';

/// A production-grade custom camera screen.
///
/// Features:
/// - Photo capture with optional timer.
/// - Zoom control (pinch-to-zoom and presets).
/// - Tap-to-focus and exposure adjustment.
/// - Front/Back camera switching.
/// - Grid overlay toggle.
/// - Volume button shutter trigger.
class CustomCameraScreen extends StatefulWidget {
  const CustomCameraScreen({super.key});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // --- Camera Controllers & Config ---
  CameraController? _controller;
  CameraDescription? _mainBackCamera;
  CameraDescription? _mainFrontCamera;

  // --- State Flags ---
  bool _isUsingFrontCamera = false;
  bool _isSwitching = false;
  bool _isFlashOn = false;
  bool _isTakingPicture = false;
  bool _isGridEnabled = false;
  bool _isProcessingImage = false;

  // --- Capture Data ---
  XFile? _capturedFile;
  Key? _reviewImageKey;

  // --- Timer State ---
  int _timerDuration = 0;
  int _currentCountdown = 0;
  bool _isCountingDown = false;
  Timer? _countdownTimer;

  // --- Zoom State ---
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoomLevel = 1.0;
  double _baseScale = 1.0;
  List<double> _zoomPresets = [];
  bool _showZoomLabel = false;
  Timer? _zoomLabelTimer;
  AnimationController? _zoomAnimationController;
  Animation<double>? _zoomAnimation;

  // --- Focus & Exposure State ---
  Offset? _focusPoint;
  bool _showFocusUI = false;
  bool _isFocusLocked = false;
  Timer? _focusTimer;
  Timer? _exposureTimer;
  double _currentExposureOffset = 0.0;
  double _uiExposureLimit = 1.0;

  AnimationController? _focusAnimationController;
  Animation<double>? _focusScaleAnimation;

  // --- UI Animations ---
  double _shutterOpacity = 0.0;

  // --- Hardware Events ---
  static const MethodChannel _volumeChannel =
  MethodChannel('com.yourapp.volume');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    ServicesBinding.instance.keyboard.addHandler(_onKey);
    _volumeChannel.setMethodCallHandler(_handleNativeMethodCall);

    _setNativeCameraState(true);

    _focusAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _focusScaleAnimation = Tween<double>(begin: 1.3, end: 1.0).animate(
      CurvedAnimation(
          parent: _focusAnimationController!, curve: Curves.easeOutBack),
    );

    _loadGridState();
    _initCamera();
  }

  @override
  void dispose() {
    _setNativeCameraState(false);

    WidgetsBinding.instance.removeObserver(this);
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    ServicesBinding.instance.keyboard.removeHandler(_onKey);
    _volumeChannel.setMethodCallHandler(null);

    _countdownTimer?.cancel();
    _zoomLabelTimer?.cancel();
    _focusTimer?.cancel();
    _exposureTimer?.cancel();
    _zoomAnimationController?.dispose();
    _focusAnimationController?.dispose();

    _controller?.dispose();
    super.dispose();
  }

  Future<void> _setNativeCameraState(bool isActive) async {
    try {
      await _volumeChannel.invokeMethod('setCameraActive', isActive);
    } catch (e) {
      debugPrint("Failed to set native camera state: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      Logger.debug('App inactive, disposing camera controller.');
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      Logger.debug('App resumed, re-initializing camera.');
      _initCamera();
    }
  }

  /// Loads the user's preference for the grid overlay.
  Future<void> _loadGridState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _isGridEnabled = prefs.getBool('isGridEnabled') ?? false);
  }

  /// Toggles the grid overlay and persists the preference.
  Future<void> _toggleGrid() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridEnabled = !_isGridEnabled;
    });
    await prefs.setBool('isGridEnabled', _isGridEnabled);
  }

  /// Initializes available cameras and selects the best starting camera.
  Future<void> _initCamera() async {
    try {
      Logger.info('Initializing camera system...');
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        Logger.error(
            'No cameras found on device.', Exception('No cameras'), StackTrace.current);
        _showErrorDialog("No cameras found on this device.");
        return;
      }

      _mainBackCamera = _selectPreferredBackCamera(cameras);
      try {
        _mainFrontCamera =
            cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
      } catch (_) {
        Logger.warning('No front camera found.');
        _mainFrontCamera = null;
      }

      if (_mainBackCamera != null) {
        await _startCamera(_mainBackCamera!);
        _isUsingFrontCamera = false;
      } else if (_mainFrontCamera != null) {
        await _startCamera(_mainFrontCamera!);
        _isUsingFrontCamera = true;
      }
    } on CameraException catch (e, stack) {
      _handleCameraException(e, stack);
    } catch (e, stack) {
      Logger.error('Unexpected error during camera init', e, stack);
    }
  }

  /// Handles platform-specific camera exceptions.
  void _handleCameraException(CameraException e, StackTrace stack) {
    Logger.error('CameraException: ${e.code}', e, stack);
    if (e.code == 'CameraAccessDenied' || e.code == 'permissionNotGranted') {
      _showPermissionDialog();
    } else {
      _showErrorDialog("Camera error: ${e.description}");
    }
  }

  /// Prompts the user to grant camera permissions via system settings.
  void _showPermissionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Camera Permission Required"),
        content:
        const Text("Krono needs camera access to capture your memories."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text("Settings")),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  /// Selects the best back camera, avoiding ultra-wide or macro lenses if possible.
  CameraDescription _selectPreferredBackCamera(List<CameraDescription> cams) {
    final backs =
    cams.where((c) => c.lensDirection == CameraLensDirection.back).toList();
    if (backs.isEmpty) return cams.first;

    // Filter out auxiliary lenses based on common naming conventions
    final regexAux =
    RegExp(r'ultra|wide|0\.5|macro|tele', caseSensitive: false);
    final mainCandidates =
    backs.where((c) => !regexAux.hasMatch(c.name.toLowerCase())).toList();

    if (mainCandidates.isNotEmpty) return mainCandidates.first;
    return backs.first;
  }

  /// Configures and starts the camera stream.
  Future<void> _startCamera(CameraDescription camera) async {
    final oldController = _controller;
    if (oldController != null) {
      await oldController.dispose();
    }

    Logger.info('Starting camera: ${camera.name} (${camera.lensDirection})');

    final newController = CameraController(
      camera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = newController;

    try {
      await newController.initialize();
      if (!mounted) return;

      // Apply initial settings
      await Future.wait([
        newController
            .setFlashMode(_isFlashOn ? FlashMode.always : FlashMode.off),
        newController.setExposureOffset(0.0),
      ]);

      // Configure Zoom
      _minAvailableZoom = await newController.getMinZoomLevel();
      _maxAvailableZoom = await newController.getMaxZoomLevel();
      _zoomPresets =
          _computeFixedZoomPresets(_minAvailableZoom, _maxAvailableZoom);
      _currentZoomLevel = _minAvailableZoom.clamp(1.0, _maxAvailableZoom);
      await newController.setZoomLevel(_currentZoomLevel);

      // Configure Exposure Limits
      final minExp = await newController.getMinExposureOffset();
      final maxExp = await newController.getMaxExposureOffset();
      _uiExposureLimit = math.min(minExp.abs(), maxExp.abs());
      if (_uiExposureLimit == 0) _uiExposureLimit = 1.0;

      // Auto-focus for front camera if supported
      if (camera.lensDirection == CameraLensDirection.front) {
        try {
          await newController.setFocusMode(FocusMode.auto);
        } catch (_) {}
      }

      setState(() => _isSwitching = false);
    } on CameraException catch (e, stack) {
      _handleCameraException(e, stack);
      setState(() => _isSwitching = false);
    } catch (e, stack) {
      Logger.error('Generic error starting camera', e, stack);
      setState(() => _isSwitching = false);
    }
  }

  /// Toggles between front and back cameras.
  void _switchCamera() async {
    if (_mainBackCamera == null || _mainFrontCamera == null) return;
    if (_isSwitching) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isSwitching = true;
      _controller = null;
      _isFocusLocked = false;
      _showFocusUI = false;
      _currentExposureOffset = 0.0;
    });

    // Small delay to allow UI to update before heavy camera operation
    await Future.delayed(const Duration(milliseconds: 50));

    if (_isUsingFrontCamera) {
      _isUsingFrontCamera = false;
      await _startCamera(_mainBackCamera!);
    } else {
      _isUsingFrontCamera = true;
      await _startCamera(_mainFrontCamera!);
    }
  }

  /// Initiates the capture flow, handling the timer if active.
  Future<void> _attemptTakePhoto() async {
    if (_isTakingPicture || _isCountingDown || _isProcessingImage) return;

    if (_timerDuration > 0) {
      Logger.info('Starting capture timer: $_timerDuration seconds');
      setState(() {
        _isCountingDown = true;
        _currentCountdown = _timerDuration;
      });
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return timer.cancel();
        if (_currentCountdown > 1) {
          setState(() {
            _currentCountdown--;
            HapticFeedback.selectionClick();
          });
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

  /// Captures the image, pauses preview, and processes the file.
  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    HapticFeedback.heavyImpact();

    try {
      setState(() {
        _isTakingPicture = true;
        _isProcessingImage = true;
      });

      Logger.info('Capturing image...');

      // ✅ Capturează imaginea
      final XFile image = await _controller!.takePicture();

      // ✅ INSTANT: Pause preview și arată efectul de shutter IMEDIAT
      await _controller!.pausePreview();

      // ✅ Efect vizual de shutter DUPĂ pause (nu înainte)
      if (mounted) setState(() => _shutterOpacity = 1.0);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _shutterOpacity = 0.0);
      });

      // ✅ Procesare în background - NU blochează UI-ul
      final processedPath = await compute(processAndSaveImage, {
        'path': image.path,
        'isFront': _isUsingFrontCamera,
        'aspect': 3 / 4,
        'mirror': _isUsingFrontCamera,
      });

      if (!mounted) return;

      setState(() {
        _capturedFile = XFile(processedPath ?? image.path);
        _isTakingPicture = false;
        _isProcessingImage = false;
        _reviewImageKey = ValueKey(DateTime.now().microsecondsSinceEpoch);
      });

      Logger.info('Image captured and processed successfully.');
    } catch (e, st) {
      Logger.error("Capture Error", e, st);
      _controller?.resumePreview();
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
          _isProcessingImage = false;
        });
      }
    }
  }

  // --- Zoom Logic ---

  void _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
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

  void _animateZoomTo(double target) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _zoomAnimationController?.dispose();
    _zoomAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    final start = _currentZoomLevel;
    _zoomAnimation = Tween<double>(begin: start, end: target).animate(
        CurvedAnimation(
            parent: _zoomAnimationController!, curve: Curves.easeOut));
    setState(() => _showZoomLabel = true);
    _startZoomLabelTimer();
    _zoomAnimationController!.addListener(() {
      _controller?.setZoomLevel(_zoomAnimation!.value);
      if (mounted) setState(() => _currentZoomLevel = _zoomAnimation!.value);
    });
    _zoomAnimationController!.forward();
  }

  // --- Focus & Exposure Logic ---

  void _onTapToFocus(Offset localPosition, BoxConstraints constraints) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Unlock if previously locked
    if (_isFocusLocked) {
      setState(() => _isFocusLocked = false);
      try {
        _controller!.setFocusMode(FocusMode.auto);
        _controller!.setExposureMode(ExposureMode.auto);
      } catch (_) {}
    }

    setState(() {
      _currentExposureOffset = 0.0;
      _focusPoint = localPosition;
      _showFocusUI = true;
    });

    _focusAnimationController?.reset();
    _focusAnimationController?.forward();

    try {
      _controller!.setExposureOffset(0.0);
    } catch (_) {}

    double nx = localPosition.dx / constraints.maxWidth;
    double ny = localPosition.dy / constraints.maxHeight;

    try {
      _controller!.setFocusPoint(Offset(nx, ny));
      _controller!.setExposurePoint(Offset(nx, ny));
    } catch (_) {}

    _startHideUITimers();
  }

  void _onLongPressFocus(Offset localPosition, BoxConstraints constraints) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    HapticFeedback.heavyImpact();

    double nx = localPosition.dx / constraints.maxWidth;
    double ny = localPosition.dy / constraints.maxHeight;

    setState(() {
      _focusPoint = localPosition;
      _showFocusUI = true;
      _isFocusLocked = true;
    });

    _focusAnimationController?.reset();
    _focusAnimationController?.forward();

    try {
      _controller!.setFocusMode(FocusMode.auto);
      _controller!.setExposureMode(ExposureMode.auto);
      _controller!.setFocusPoint(Offset(nx, ny));
      _controller!.setExposurePoint(Offset(nx, ny));
    } catch (_) {}

    // Lock after a short delay to allow initial focus
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || !_isFocusLocked) return;
      try {
        _controller!.setFocusMode(FocusMode.locked);
        _controller!.setExposureMode(ExposureMode.locked);
        Logger.debug('Focus and Exposure locked.');
      } catch (_) {}
    });

    _focusTimer?.cancel();
    _exposureTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // If a photo is captured, show the review screen
    if (_capturedFile != null) {
      return CameraReviewView(
        filePath: _capturedFile!.path,
        primaryColor: Theme.of(context).colorScheme.primary,
        isProcessing: _isProcessingImage,
        imageKey: _reviewImageKey,
        onRetake: () async {
          setState(() => _capturedFile = null);
          await _controller?.resumePreview();
        },
        onSave: () => Navigator.pop(context, _capturedFile!.path),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview & Interactive Layer
          CameraPreviewLayer(
            controller: _controller,
            isGridEnabled: _isGridEnabled,
            onScaleStart: (d) => _baseScale = _currentZoomLevel,
            onScaleUpdate: _handleScaleUpdate,
            onTapUp: _onTapToFocus,
            onLongPressStart: _onLongPressFocus,
            focusPoint: _focusPoint,
            showFocusUI: _showFocusUI,
            isFocusLocked: _isFocusLocked,
            focusScaleAnimation: _focusScaleAnimation,
            currentExposureOffset: _currentExposureOffset,
            uiExposureLimit: _uiExposureLimit,
            onExposureChanged: (v) {
              setState(() => _currentExposureOffset = v);
              _controller!.setExposureOffset(v);
              if (!_isFocusLocked) _startHideUITimers();
            },
          ),

          // 2. Shutter Flash Effect
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOutQuad,
              color: Colors.black.withValues(alpha: _shutterOpacity),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),

          // 3. Zoom Controls
          Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(child: _buildZoomPresetRow())),

          if (_showZoomLabel)
            Positioned(
                bottom: 200,
                left: 0,
                right: 0,
                child: Center(
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                            "${_currentZoomLevel.toStringAsFixed(1)}x",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))))),

          // 4. Countdown Overlay
          if (_isCountingDown)
            Center(
                child: Text("$_currentCountdown",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 120,
                        fontWeight: FontWeight.bold))),

          // 5. Main UI Controls (Top & Bottom Bars)
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GlassIconButton(
                              icon: Icons.close_rounded,
                              onTap: () => Navigator.pop(context)),
                          GlassIconButton(
                              icon: _timerDuration == 0
                                  ? Icons.timer_off_rounded
                                  : _timerDuration == 3
                                  ? Icons.timer_3_rounded
                                  : Icons.timer_10_rounded,
                              onTap: () => setState(() => _timerDuration =
                              (_timerDuration == 0
                                  ? 3
                                  : (_timerDuration == 3 ? 10 : 0)))),
                          GlassIconButton(
                              icon: _isFlashOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color:
                              _isFlashOn ? Colors.yellow : Colors.white,
                              onTap: () {
                                setState(() => _isFlashOn = !_isFlashOn);
                                if (_controller != null &&
                                    _controller!.value.isInitialized) {
                                  _controller!.setFlashMode(_isFlashOn
                                      ? FlashMode.always
                                      : FlashMode.off);
                                }
                              }),
                        ])),
                const Spacer(),
                // Bottom Bar
                Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GlassIconButton(
                              icon: _isGridEnabled
                                  ? Icons.grid_4x4_rounded
                                  : Icons.grid_off_rounded,
                              onTap: _toggleGrid),
                          GestureDetector(
                              onTap: _attemptTakePhoto,
                              child: ShutterButton(
                                  isRecording: _isTakingPicture)),
                          GlassIconButton(
                              icon: Icons.flip_camera_ios_rounded,
                              size: 50,
                              onTap: _switchCamera),
                        ])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  List<double> _computeFixedZoomPresets(double min, double max) =>
      [min, 2.0, 5.0].where((z) => z >= min && z <= max).toList();

  Widget _buildZoomPresetRow() {
    return Row(
        mainAxisSize: MainAxisSize.min,
        children: _zoomPresets.map((z) {
          final active = (z - _currentZoomLevel).abs() < 0.1;
          return Padding(
              padding: const EdgeInsets.all(4.0),
              child: GestureDetector(
                  onTap: () => _animateZoomTo(z),
                  child: CircleAvatar(
                      backgroundColor:
                      active ? Colors.white : Colors.black54,
                      radius: 18,
                      child: Text("${z.toInt()}x",
                          style: TextStyle(
                              fontSize: 10,
                              color: active ? Colors.black : Colors.white)))));
        }).toList());
  }

  void _startZoomLabelTimer() {
    _zoomLabelTimer?.cancel();
    _zoomLabelTimer = Timer(const Duration(seconds: 2),
            () => setState(() => _showZoomLabel = false));
  }

  void _startHideUITimers() {
    _exposureTimer?.cancel();
    _exposureTimer = Timer(const Duration(seconds: 4),
            () => setState(() => _showFocusUI = false));
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'volume') {
      Logger.debug('Volume button press detected, triggering capture.');
      _attemptTakePhoto();
    }
    return null;
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.audioVolumeUp ||
            event.logicalKey == LogicalKeyboardKey.audioVolumeDown)) {
      _attemptTakePhoto();
      return true;
    }
    return false;
  }
}