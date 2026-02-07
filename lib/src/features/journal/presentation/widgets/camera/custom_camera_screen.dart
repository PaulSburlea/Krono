import 'dart:async';
import 'dart:io';
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
  CameraDescription? _ultraWideBackCamera; // ✅ NEW: Ultra-wide camera

  // --- State Flags ---
  bool _initializingCamera = false;
  bool _isUsingFrontCamera = false;
  bool _isSwitching = false;
  bool _isFlashOn = false;
  bool _isTakingPicture = false;
  bool _isGridEnabled = false;
  bool _isProcessingImage = false;
  bool _isDisposed = false;
  bool _permissionDenied = false;
  bool _hasShownPermissionDialog = false;
  bool _frontCameraSupportsFlash = false;

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
  bool _isOnUltraWide = false; // ✅ Track if currently on ultra-wide camera

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

  // ✅ NEW: Selfie flash simulation
  double _selfieFlashOpacity = 0.0;

  // --- Hardware Events ---
  static const MethodChannel _volumeChannel = MethodChannel('com.yourapp.volume');

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    ServicesBinding.instance.keyboard.addHandler(_onKey);
    _volumeChannel.setMethodCallHandler(_handleNativeMethodCall);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _setNativeCameraState(true);

    _focusAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _focusScaleAnimation = Tween<double>(begin: 1.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _focusAnimationController!,
        curve: Curves.easeOutBack,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureOrientationForDevice();
    });

    _loadGridState();
    _loadTimerState();
    _initCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;

    _setNativeCameraState(false);
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    ServicesBinding.instance.keyboard.removeHandler(_onKey);
    _volumeChannel.setMethodCallHandler(null);

    _countdownTimer?.cancel();
    _zoomLabelTimer?.cancel();
    _focusTimer?.cancel();
    _exposureTimer?.cancel();

    _zoomAnimationController?.dispose();
    _focusAnimationController?.dispose();

    _disposeController(_controller);
    _controller = null;

    super.dispose();
  }

  // ==================== ORIENTATION MANAGEMENT ====================

  void _configureOrientationForDevice() {
    if (!mounted) return;
    final data = MediaQuery.of(context);
    final isTablet = data.size.shortestSide >= 600;

    if (isTablet) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Future<void> _resetOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      Logger.warning('Failed to reset orientation: $e');
    }
  }

  Future<void> _exitCamera([String? capturedPath]) async {
    await _resetOrientation();
    if (!mounted) return;
    Navigator.of(context).pop(capturedPath);
  }

  // ==================== LIFECYCLE MANAGEMENT ====================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    if (state == AppLifecycleState.inactive) {
      Logger.debug('App inactive, disposing camera controller.');
      _disposeControllerSafely();
    } else if (state == AppLifecycleState.resumed) {
      Logger.debug('App resumed.');
      if (_permissionDenied) {
        Logger.warning('Permission denied, not re-initializing camera.');
        return;
      }
      if (_controller == null && !_initializingCamera) {
        _initCamera();
      }
    }
  }

  Future<void> _setNativeCameraState(bool isActive) async {
    try {
      await _volumeChannel.invokeMethod('setCameraActive', isActive);
    } catch (e) {
      Logger.warning("Failed to set native camera state: $e");
    }
  }

  // ==================== PREFERENCES ====================

  Future<void> _loadGridState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _isGridEnabled = prefs.getBool('isGridEnabled') ?? false);
  }

  Future<void> _toggleGrid() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isGridEnabled = !_isGridEnabled);
    await prefs.setBool('isGridEnabled', _isGridEnabled);
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _timerDuration = prefs.getInt('cameraTimerDuration') ?? 0);
  }

  Future<void> _toggleTimer() async {
    final prefs = await SharedPreferences.getInstance();

    // Cycle: 0 → 2 → 5 → 10 → 0
    int nextDuration;
    if (_timerDuration == 0) {
      nextDuration = 2;
    } else if (_timerDuration == 2) {
      nextDuration = 5;
    } else if (_timerDuration == 5) {
      nextDuration = 10;
    } else {
      nextDuration = 0;
    }

    setState(() => _timerDuration = nextDuration);
    await prefs.setInt('cameraTimerDuration', nextDuration);
  }

  // ==================== CAMERA INITIALIZATION ====================

  Future<void> _initCamera() async {
    if (_isDisposed || _initializingCamera || _permissionDenied) return;

    _initializingCamera = true;

    try {
      Logger.info('Checking camera permission...');
      final permissionStatus = await Permission.camera.status;

      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        Logger.warning('Camera permission not granted: $permissionStatus');
        final result = await Permission.camera.request();

        if (result.isDenied || result.isPermanentlyDenied) {
          Logger.info('Camera permission denied by user.');
          if (mounted) {
            setState(() => _permissionDenied = true);
            if (!_hasShownPermissionDialog) {
              _hasShownPermissionDialog = true;
              _showPermissionDeniedDialog();
            }
          }
          return;
        }
      }

      Logger.info('Camera permission granted, initializing cameras...');
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        Logger.error('No cameras found on device.', Exception('No cameras'), StackTrace.current);
        _showErrorDialog("No cameras found on this device.");
        if (mounted) setState(() => _permissionDenied = true);
        return;
      }

      _mainBackCamera = _selectPreferredBackCamera(cameras);

      // ✅ SIMPLE & ROBUST: Last back camera in list is usually ultra-wide (0.5x)
      final backCameras = cameras.where((c) => c.lensDirection == CameraLensDirection.back).toList();
      if (backCameras.length > 1) {
        // Last back camera = ultra-wide, first = main
        _ultraWideBackCamera = backCameras.last;
        Logger.info('✅ Ultra-wide detected (last in list): ${_ultraWideBackCamera?.name}');

        // Log all back cameras for debugging
        for (var i = 0; i < backCameras.length; i++) {
          Logger.info('Back camera[$i]: ${backCameras[i].name}');
        }
      } else {
        _ultraWideBackCamera = null;
        Logger.info('Only one back camera found, no ultra-wide available.');
      }

      try {
        _mainFrontCamera = cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
        );
      } catch (_) {
        Logger.warning('No front camera found.');
        _mainFrontCamera = null;
      }

      if (_mainBackCamera != null) {
        await _startCamera(_mainBackCamera!);
        if (mounted) setState(() => _isUsingFrontCamera = false);
      } else if (_mainFrontCamera != null) {
        await _startCamera(_mainFrontCamera!);
        if (mounted) setState(() => _isUsingFrontCamera = true);
      }

      if (mounted) setState(() => _permissionDenied = false);

    } on CameraException catch (e, stack) {
      _handleCameraException(e, stack);
    } catch (e, stack) {
      Logger.error('Unexpected error during camera init', e, stack);
      if (e.toString().toLowerCase().contains('permission')) {
        if (mounted) setState(() => _permissionDenied = true);
      }
    } finally {
      _initializingCamera = false;
    }
  }

  void _handleCameraException(CameraException e, StackTrace stack) {
    Logger.error('CameraException: ${e.code}', e, stack);
    if (e.code == 'CameraAccessDenied' ||
        e.code == 'permissionNotGranted' ||
        e.code == 'CameraAccessDeniedWithoutPrompt') {
      if (mounted) {
        setState(() => _permissionDenied = true);
        if (!_hasShownPermissionDialog) {
          _hasShownPermissionDialog = true;
          _showPermissionDeniedDialog();
        }
      }
    } else {
      _showErrorDialog("Camera error: ${e.description}");
    }
  }

  CameraDescription _selectPreferredBackCamera(List<CameraDescription> cams) {
    final backs = cams.where((c) => c.lensDirection == CameraLensDirection.back).toList();
    if (backs.isEmpty) return cams.first;

    // ✅ First back camera in list is usually the main camera
    // We'll also exclude telephoto/macro if they somehow end up first
    final regexAux = RegExp(r'macro|tele', caseSensitive: false);
    final mainCandidates = backs.where((c) => !regexAux.hasMatch(c.name.toLowerCase())).toList();
    return mainCandidates.isNotEmpty ? mainCandidates.first : backs.first;
  }

  // ==================== CAMERA CONTROLLER MANAGEMENT ====================

  Future<void> _startCamera(CameraDescription camera) async {
    if (_isDisposed) return;

    if (_controller != null) {
      await _disposeControllerSafely();
    }

    Logger.info('Starting camera: ${camera.name} (${camera.lensDirection})');

    final controller = CameraController(
      camera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();

      if (_isDisposed || !mounted) {
        _disposeController(controller);
        return;
      }

      if (mounted) setState(() => _controller = controller);
      await _configureCameraSettings(controller, camera);
      if (mounted) setState(() => _isSwitching = false);

    } on CameraException catch (e, stack) {
      if (_isDisposed || !mounted) return;
      _handleCameraException(e, stack);
      if (mounted) setState(() => _isSwitching = false);
    } catch (e, stack) {
      if (_isDisposed || !mounted) return;
      Logger.error('Generic error starting camera', e, stack);
      if (mounted) setState(() => _isSwitching = false);
    }
  }

  Future<void> _configureCameraSettings(CameraController controller, CameraDescription camera) async {
    // ✅ Check if front camera supports flash
    _frontCameraSupportsFlash = false;
    if (camera.lensDirection == CameraLensDirection.front) {
      try {
        // Try to enable flash - if it fails, front camera doesn't support it
        await controller.setFlashMode(FlashMode.torch);
        await controller.setFlashMode(FlashMode.off);
        _frontCameraSupportsFlash = true;
        Logger.info('Front camera supports flash');
      } catch (e) {
        _frontCameraSupportsFlash = false;
        Logger.info('Front camera does not support flash');
      }
    }

    try {
      await controller.setFlashMode(_isFlashOn ? FlashMode.always : FlashMode.off);
    } catch (e) {
      Logger.warning('Failed to set flash mode: $e');
      if (mounted) setState(() => _isFlashOn = false);
    }

    if (!_isDisposed && mounted && controller.value.isInitialized) {
      try {
        await controller.setExposureOffset(0.0);
        if (mounted) {
          setState(() => _currentExposureOffset = 0.0);
        }
      } catch (e) {
        Logger.warning('Failed to set initial exposure offset: $e');
      }
    }

    if (_isDisposed || !mounted) return;

    try {
      _minAvailableZoom = await controller.getMinZoomLevel();
      _maxAvailableZoom = await controller.getMaxZoomLevel();
    } catch (e) {
      Logger.warning('Failed to get zoom limits: $e');
      _minAvailableZoom = 1.0;
      _maxAvailableZoom = 1.0;
    }

    // ✅ IMPROVED: Smart zoom presets with ultra-wide support
    _zoomPresets = _computeSmartZoomPresets(_minAvailableZoom, _maxAvailableZoom);
    _currentZoomLevel = _currentZoomLevel.clamp(_minAvailableZoom, _maxAvailableZoom);

    try {
      await controller.setZoomLevel(_currentZoomLevel);
    } catch (e) {
      Logger.warning('Failed to set zoom level: $e');
    }

    if (_isDisposed || !mounted) return;

    try {
      final minExp = await controller.getMinExposureOffset();
      final maxExp = await controller.getMaxExposureOffset();
      _uiExposureLimit = math.min(minExp.abs(), maxExp.abs());
      if (_uiExposureLimit == 0) _uiExposureLimit = 1.0;
    } catch (e) {
      Logger.warning('Failed to get exposure limits: $e');
    }

    if (camera.lensDirection == CameraLensDirection.front) {
      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (e) {
        Logger.warning('Failed to set focus mode: $e');
      }
    }
  }

  Future<void> _disposeControllerSafely() async {
    final c = _controller;
    if (c == null) return;

    if (mounted) {
      setState(() {
        _controller = null;
      });
    }

    try {
      await c.dispose();
    } catch (e) {
      Logger.warning('Failed to dispose controller: $e');
    }
  }

  void _disposeController(CameraController? controller) {
    if (controller == null) return;
    try {
      controller.dispose();
    } catch (e) {
      Logger.warning('Error disposing controller: $e');
    }
  }

  // ==================== CAMERA OPERATIONS ====================

  Future<void> _switchCamera() async {
    if (_mainBackCamera == null || _mainFrontCamera == null) return;
    if (_isSwitching) return;

    HapticFeedback.lightImpact();

    if (mounted) {
      setState(() {
        _isSwitching = true;
        _isFocusLocked = false;
        _showFocusUI = false;
        _currentExposureOffset = 0.0;
        _isOnUltraWide = false; // ✅ Reset ultra-wide flag
      });
    }

    await _disposeControllerSafely();
    await Future.delayed(const Duration(milliseconds: 100));

    if (_isUsingFrontCamera) {
      _isUsingFrontCamera = false;
      await _startCamera(_mainBackCamera!);
    } else {
      _isUsingFrontCamera = true;
      await _startCamera(_mainFrontCamera!);
    }
  }

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

  Future<void> _takePicture() async {
    if (_isDisposed || _controller == null || !_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }

    HapticFeedback.heavyImpact();

    try {
      setState(() {
        _isTakingPicture = true;
        _isProcessingImage = true;
      });

      // ✅ IMPROVED: Selfie flash simulation - show bright white screen
      if (_isUsingFrontCamera && _isFlashOn) {
        setState(() => _selfieFlashOpacity = 1.0);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      Logger.info('Capturing image...');
      final XFile image = await _controller!.takePicture();

      if (_isDisposed || !mounted) return;

      try {
        await _controller?.pausePreview();
      } catch (e) {
        Logger.warning('Failed to pause preview: $e');
      }

      if (_isDisposed || !mounted) return;

      // Hide selfie flash
      if (_isUsingFrontCamera && _isFlashOn) {
        setState(() => _selfieFlashOpacity = 0.0);
      }

      setState(() => _shutterOpacity = 1.0);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_isDisposed || !mounted) return;
        setState(() => _shutterOpacity = 0.0);
      });

      final processedPath = await compute(processAndSaveImage, {
        'path': image.path,
        'isFront': _isUsingFrontCamera,
        'aspect': 3 / 4,
        'mirror': _isUsingFrontCamera,
      });

      if (_isDisposed || !mounted) return;

      if (processedPath != null) {
        final provider = FileImage(File(processedPath));
        await provider.evict();
      }

      setState(() {
        _capturedFile = XFile(processedPath ?? image.path);
        _isTakingPicture = false;
        _isProcessingImage = false;
        _reviewImageKey = ValueKey(DateTime.now().microsecondsSinceEpoch);
      });

      Logger.info('Image captured and processed successfully.');

    } catch (e, st) {
      Logger.error("Capture Error", e, st);
      if (_isDisposed) return;

      // Hide selfie flash on error
      if (mounted) {
        setState(() => _selfieFlashOpacity = 0.0);
      }

      try {
        await _controller?.resumePreview();
      } catch (resumeError) {
        Logger.warning('Failed to resume preview: $resumeError');
      }
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
          _isProcessingImage = false;
        });
      }
    }
  }

  // ==================== ZOOM LOGIC ====================

  void _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (_isDisposed || _controller == null || !_controller!.value.isInitialized) return;

    double scale = _baseScale * details.scale;

    // ✅ SMOOTH AUTO-SWITCH: Handle camera switching based on zoom level
    if (_ultraWideBackCamera != null && !_isUsingFrontCamera && !_isSwitching) {
      // Switch from ultra-wide to main when zooming in
      // On ultra-wide: physical zoom 1.0 = virtual 0.5x, so 1.4 physical ≈ 0.7x virtual
      if (_isOnUltraWide && scale > 1.3) {
        // Switch to main camera at approximately same field of view
        await _switchToMainCameraSmooth(0.7);
        return;
      }

      // Switch from main to ultra-wide when zooming out below 0.9x
      if (!_isOnUltraWide && scale < 0.9) {
        await _switchToUltraWideSmooth();
        return;
      }
    }

    scale = scale.clamp(_minAvailableZoom, _maxAvailableZoom);

    if ((scale - _currentZoomLevel).abs() > 0.01) {
      setState(() {
        _currentZoomLevel = scale;
        _showZoomLabel = true;
      });
      _startZoomLabelTimer();

      try {
        await _controller!.setZoomLevel(scale);
      } catch (e) {
        Logger.warning('Failed to set zoom level: $e');
      }
    }
  }

  // ✅ Smooth switch to main camera
  Future<void> _switchToMainCameraSmooth(double targetZoom) async {
    if (_isSwitching || _mainBackCamera == null) return;

    setState(() => _isSwitching = true);
    HapticFeedback.lightImpact();

    await _disposeControllerSafely();
    await Future.delayed(const Duration(milliseconds: 80));
    await _startCamera(_mainBackCamera!);

    if (mounted && _controller != null) {
      setState(() => _isOnUltraWide = false);
      // Clamp to valid range for main camera
      final clampedZoom = targetZoom.clamp(_minAvailableZoom, _maxAvailableZoom);
      _currentZoomLevel = clampedZoom;
      try {
        await _controller!.setZoomLevel(clampedZoom);
      } catch (e) {
        Logger.warning('Failed to set initial zoom on main camera: $e');
      }
    }
  }

  // ✅ Smooth switch to ultra-wide camera
  Future<void> _switchToUltraWideSmooth() async {
    if (_isSwitching || _ultraWideBackCamera == null) return;

    setState(() => _isSwitching = true);
    HapticFeedback.lightImpact();

    await _disposeControllerSafely();
    await Future.delayed(const Duration(milliseconds: 80));
    await _startCamera(_ultraWideBackCamera!);

    if (mounted && _controller != null) {
      setState(() => _isOnUltraWide = true);
      _currentZoomLevel = _minAvailableZoom;
      try {
        await _controller!.setZoomLevel(_minAvailableZoom);
      } catch (e) {
        Logger.warning('Failed to set zoom on ultra-wide: $e');
      }
    }
  }

  void _animateZoomTo(double target) {
    if (_isDisposed || _controller == null || !_controller!.value.isInitialized) return;

    _zoomAnimationController?.dispose();

    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final start = _currentZoomLevel;
    _zoomAnimation = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _zoomAnimationController!, curve: Curves.easeOut),
    );

    setState(() => _showZoomLabel = true);
    _startZoomLabelTimer();

    _zoomAnimationController!.addListener(() {
      if (_isDisposed || _controller == null) return;
      try {
        _controller?.setZoomLevel(_zoomAnimation!.value);
      } catch (e) {
        Logger.warning('Failed to animate zoom: $e');
      }
      if (mounted) setState(() => _currentZoomLevel = _zoomAnimation!.value);
    });

    _zoomAnimationController!.forward();
  }

  void _startZoomLabelTimer() {
    _zoomLabelTimer?.cancel();
    _zoomLabelTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showZoomLabel = false);
    });
  }

  // ✅ IMPROVED: Smart zoom presets with physical camera switching
  List<double> _computeSmartZoomPresets(double min, double max) {
    final List<double> presets = [];

    // ✅ Add ultra-wide preset (0.5x) if ultra-wide camera exists
    if (_ultraWideBackCamera != null && !_isUsingFrontCamera) {
      presets.add(0.5);
    }

    // Always add 1.0x (main camera)
    presets.add(1.0);

    // Add 2x if available
    if (max >= 2.0) {
      presets.add(2.0);
    }

    // Add higher zoom based on max capabilities
    if (max >= 10.0) {
      presets.add(10.0);
    } else if (max >= 8.0) {
      presets.add(8.0);
    } else if (max >= 5.0) {
      presets.add(5.0);
    }

    // Remove duplicates and sort
    return presets.toSet().toList()..sort();
  }

  // ✅ NEW: Handle zoom with camera switching for ultra-wide
  Future<void> _handleZoomPreset(double targetZoom) async {
    if (_isDisposed || _isSwitching) return;

    // ✅ If target is 0.5x and we have ultra-wide camera, switch to it
    if (targetZoom == 0.5 && _ultraWideBackCamera != null && !_isUsingFrontCamera) {
      if (_isOnUltraWide) {
        // Already on ultra-wide, just adjust zoom to min
        _animateZoomTo(_minAvailableZoom);
        return;
      }

      HapticFeedback.lightImpact();
      setState(() => _isSwitching = true);

      await _disposeControllerSafely();
      await Future.delayed(const Duration(milliseconds: 100));
      await _startCamera(_ultraWideBackCamera!);

      // Set zoom to minimum for ultra-wide effect
      if (mounted && _controller != null) {
        setState(() => _isOnUltraWide = true);
        _animateZoomTo(_minAvailableZoom);
      }
      return;
    }

    // ✅ If target is 1.0x or higher, ensure we're on main camera
    if (targetZoom >= 1.0 && !_isUsingFrontCamera) {
      if (_isOnUltraWide) {
        // Currently on ultra-wide, switch back to main
        HapticFeedback.lightImpact();
        setState(() => _isSwitching = true);

        await _disposeControllerSafely();
        await Future.delayed(const Duration(milliseconds: 100));
        await _startCamera(_mainBackCamera!);

        if (!mounted || _controller == null) return;
        setState(() => _isOnUltraWide = false);
      }
    }

    // Now animate to target zoom level
    _animateZoomTo(targetZoom.clamp(_minAvailableZoom, _maxAvailableZoom));
  }

  // ==================== FOCUS & EXPOSURE LOGIC ====================

  void _onTapToFocus(Offset localPosition, BoxConstraints constraints) {
    if (_isDisposed || _controller == null || !_controller!.value.isInitialized) return;

    if (_isFocusLocked) {
      setState(() => _isFocusLocked = false);
      try {
        _controller!.setFocusMode(FocusMode.auto);
        _controller!.setExposureMode(ExposureMode.auto);
      } catch (e) {
        Logger.warning('Failed to unlock focus: $e');
      }
    }

    setState(() {
      _currentExposureOffset = 0.0;
      _focusPoint = localPosition;
      _showFocusUI = true;
    });

    _focusAnimationController?.reset();
    _focusAnimationController?.forward();

    _setExposureOffsetSilently(0.0);

    final nx = localPosition.dx / constraints.maxWidth;
    final ny = localPosition.dy / constraints.maxHeight;

    try {
      _controller!.setFocusPoint(Offset(nx, ny));
      _controller!.setExposurePoint(Offset(nx, ny));
    } catch (e) {
      Logger.warning('Failed to set focus/exposure point: $e');
    }

    _startHideUITimers();
  }

  void _onLongPressFocus(Offset localPosition, BoxConstraints constraints) {
    if (_isDisposed || _controller == null || !_controller!.value.isInitialized) return;

    HapticFeedback.heavyImpact();

    final nx = localPosition.dx / constraints.maxWidth;
    final ny = localPosition.dy / constraints.maxHeight;

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
    } catch (e) {
      Logger.warning('Failed to set focus on long press: $e');
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (_isDisposed || !mounted || !_isFocusLocked || _controller == null) return;
      try {
        _controller!.setFocusMode(FocusMode.locked);
        _controller!.setExposureMode(ExposureMode.locked);
        Logger.debug('Focus and Exposure locked.');
      } catch (e) {
        Logger.warning('Failed to lock focus: $e');
      }
    });

    _focusTimer?.cancel();
    _exposureTimer?.cancel();
  }

  void _startHideUITimers() {
    _exposureTimer?.cancel();
    _exposureTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showFocusUI = false);
    });
  }

  void _setExposureOffsetSilently(double value) {
    if (_isDisposed ||
        _controller == null ||
        !_controller!.value.isInitialized ||
        _isSwitching) {
      return;
    }

    runZonedGuarded(() async {
      try {
        await _controller!.setExposureOffset(value);
      } catch (_) {
        // Ignorăm complet - erorile sunt normale când camera e ocupată
      }
    }, (error, stack) {
      // Zone error handler - suprimate complet
    });
  }

  // ==================== DIALOGS ====================

  void _showPermissionDeniedDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Camera Permission Required"),
        content: const Text(
          "Krono needs camera access to capture your memories. "
              "Please grant camera permission in Settings.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _exitCamera();
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final navigator = Navigator.of(context, rootNavigator: true);
              final opened = await openAppSettings();

              if (!opened) {
                if (mounted) {
                  await _resetOrientation();
                  navigator.pop();
                }
              } else {
                Future.delayed(const Duration(milliseconds: 500), () async {
                  if (!mounted || _isDisposed) return;
                  final status = await Permission.camera.status;
                  if (status.isGranted) {
                    if (mounted) {
                      setState(() {
                        _permissionDenied = false;
                        _hasShownPermissionDialog = false;
                      });
                      _initCamera();
                    }
                  } else {
                    if (mounted) {
                      await _resetOrientation();
                      navigator.pop();
                    }
                  }
                });
              }
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Close',
          textColor: Colors.white,
          onPressed: () async {
            if (mounted) {
              await _resetOrientation();
              navigator.pop();
            }
          },
        ),
      ),
    );
  }

  // ==================== HARDWARE EVENTS ====================

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

  // ✅ Get timer display widget (icon or custom text)
  Widget _getTimerDisplay() {
    if (_timerDuration == 0) {
      return const Icon(Icons.timer_off_rounded, color: Colors.white, size: 24);
    }

    // Custom text display for 2s, 5s, 10s
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: Text(
        '${_timerDuration}s',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied && _controller == null) {
      return _buildPermissionDeniedUI();
    }

    if (_capturedFile != null) {
      return _buildReviewScreen();
    }

    return _buildCameraUI();
  }

  Widget _buildPermissionDeniedUI() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, size: 80, color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(height: 24),
                const Text('Camera Permission Required', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text('Krono needs camera access to capture your memories.', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final opened = await openAppSettings();
                    if (!opened && mounted) {
                      await _resetOrientation();
                      navigator.pop();
                    }
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _exitCamera,
                  child: const Text('Go Back', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewScreen() {
    return CameraReviewView(
      filePath: _capturedFile!.path,
      primaryColor: Theme.of(context).colorScheme.primary,
      isProcessing: _isProcessingImage,
      imageKey: _reviewImageKey,
      onRetake: () async {
        setState(() => _capturedFile = null);
        try {
          await _controller?.resumePreview();
        } catch (e) {
          Logger.warning('Failed to resume preview on retake: $e');
        }
      },
      onSave: () async {
        await _exitCamera(_capturedFile!.path);
      },
    );
  }

  Widget _buildCameraUI() {
    final screenWidth = MediaQuery.of(context).size.width;
    final previewHeight = screenWidth / (3 / 4);
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    // Position zoom controls between preview and shutter
    final zoomControlsBottom = safeBottom + 120;

    // ✅ Calculate preview bottom position for zoom label
    final screenHeight = MediaQuery.of(context).size.height;
    final previewBottom = (screenHeight - previewHeight) / 2 + previewHeight * 0.95;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
              _setExposureOffsetSilently(v);
              if (!_isFocusLocked) _startHideUITimers();
            },
          ),

          // ✅ Selfie flash overlay - bright white screen
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              color: Colors.white.withValues(alpha: _selfieFlashOpacity),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOutQuad,
              color: Colors.black.withValues(alpha: _shutterOpacity),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          Positioned(
            bottom: zoomControlsBottom,
            left: 0,
            right: 0,
            child: Center(child: _buildZoomPresetRow()),
          ),

          // ✅ MOVED: Zoom label now inside preview at bottom
          if (_showZoomLabel)
            Positioned(
              top: previewBottom - 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    // ✅ Show 0.5x when on ultra-wide, actual zoom otherwise
                    _isOnUltraWide
                        ? "0.5x"
                        : "${_currentZoomLevel.toStringAsFixed(1)}x",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

          if (_isCountingDown)
            Center(child: Text("$_currentCountdown", style: const TextStyle(color: Colors.white, fontSize: 120, fontWeight: FontWeight.bold))),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GlassIconButton(icon: Icons.close_rounded, onTap: _exitCamera),
                      GestureDetector(
                        onTap: _toggleTimer,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 44,
                            height: 44,
                            color: Colors.black.withValues(alpha: 0.3),
                            child: _getTimerDisplay(),
                          ),
                        ),
                      ),
                      // Show flash only if supported
                      if (_isUsingFrontCamera && !_frontCameraSupportsFlash)
                        const SizedBox(width: 44)
                      else
                        GlassIconButton(
                          icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _isFlashOn ? Colors.yellow : Colors.white,
                          onTap: () {
                            setState(() => _isFlashOn = !_isFlashOn);
                            if (_controller != null && _controller!.value.isInitialized) {
                              try {
                                _controller!.setFlashMode(_isFlashOn ? FlashMode.always : FlashMode.off);
                              } catch (e) {
                                Logger.warning('Failed to toggle flash: $e');
                                if (mounted) setState(() => _isFlashOn = false);
                              }
                            }
                          },
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                // ✅ FIXED: Perfectly centered shutter button using Stack
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: SizedBox(
                    height: 80,
                    child: Stack(
                      children: [
                        // Left button
                        Positioned(
                          left: 40,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: GlassIconButton(
                              icon: _isGridEnabled ? Icons.grid_4x4_rounded : Icons.grid_off_rounded,
                              onTap: _toggleGrid,
                            ),
                          ),
                        ),
                        // Center shutter button - perfectly centered
                        Center(
                          child: GestureDetector(
                            onTap: _attemptTakePhoto,
                            child: ShutterButton(isRecording: _isTakingPicture),
                          ),
                        ),
                        // Right button
                        Positioned(
                          right: 40,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: GlassIconButton(
                              icon: Icons.flip_camera_ios_rounded,
                              size: 50,
                              onTap: _switchCamera,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomPresetRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: _zoomPresets.map((z) {
        // ✅ FIXED: Mutually exclusive active states
        bool active;
        if (z == 0.5 && _ultraWideBackCamera != null) {
          // 0.5x button is active only when on ultra-wide
          active = _isOnUltraWide;
        } else if (z == 1.0) {
          // 1.0x button is active only when on main camera at ~1x zoom
          active = !_isOnUltraWide && (_currentZoomLevel - 1.0).abs() < 0.15;
        } else {
          // Other zoom levels (2x, 5x, 10x) - normal check
          active = !_isOnUltraWide && (z - _currentZoomLevel).abs() < 0.15;
        }

        // ✅ Format zoom level properly (0.5x, 1x, 2x, etc.)
        String label;
        if (z < 1.0) {
          label = "${z.toStringAsFixed(1)}x";
        } else {
          label = "${z.toInt()}x";
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: GestureDetector(
            onTap: () => _handleZoomPreset(z),
            child: CircleAvatar(
              backgroundColor: active ? Colors.white : Colors.black54,
              radius: 18,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: active ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}