import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/device_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/api_service.dart';
import '../../core/services/telemetry_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/web_face_detector.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';

class EnrollWajahScreen extends StatefulWidget {
  final bool isOnboarding;
  final Future<ApiResponse> Function(List<String> images)? onSubmitExternal;
  const EnrollWajahScreen({super.key, this.isOnboarding = false, this.onSubmitExternal});

  @override
  State<EnrollWajahScreen> createState() => _EnrollWajahScreenState();
}

enum EnrollState { ready, capturing, processing, success, failed }

class _EnrollWajahScreenState extends State<EnrollWajahScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIdx = 0;
  bool _isCameraReady = false;
  String _cameraErrorDetail = '';

  EnrollState _enrollState = EnrollState.ready;
  String _errorMessage = '';
  bool _showShutterFlash = false;

  final List<String> _capturedImages = [];
  int _currentStep = 0; // 0 to 4 (5 total angles)

  // Real-time Face & Pose Tracking
  bool _isFaceDetected = false;
  bool _isPoseMatching = false;
  String _dynamicFeedback = '';

  // Auto-capture hold progress
  Timer? _autoCaptureTimer;
  double _stepHoldProgress = 0.0; // 0.0 to 1.0

  late AnimationController _pulseController;
  late AnimationController _glyphSuccessController;

  static const List<Map<String, String>> _stepsInfo = [
    {
      'title': 'Hadap Lurus ke Depan',
      'hint': 'Posisikan seluruh wajah tepat di tengah lingkaran',
      'instruction': 'Tatap kamera santai dengan ekspresi natural',
    },
    {
      'title': 'Tolehkan Sedikit ke Kiri',
      'hint': 'Putar kepala perlahan ke arah kiri Anda',
      'instruction': 'Sudut sekitar 20-30 derajat dari tengah',
    },
    {
      'title': 'Tolehkan Sedikit ke Kanan',
      'hint': 'Putar kepala perlahan ke arah kanan Anda',
      'instruction': 'Sudut sekitar 20-30 derajat dari tengah',
    },
    {
      'title': 'Tersenyum Santai',
      'hint': 'Tunjukkan senyuman wajar ke kamera',
      'instruction': 'Membantu sistem mengenali variasi ekspresi',
    },
    {
      'title': 'Hadap Lurus untuk Mengunci',
      'hint': 'Tatap kembali ke tengah lingkaran kamera',
      'instruction': 'Foto final untuk mengunci biometrik 512-D',
    },
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _glyphSuccessController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    if (mounted) {
      setState(() {
        _isCameraReady = false;
        _errorMessage = '';
        _dynamicFeedback = 'Menyiapkan kamera biometrik...';
      });
    }

    try {
      try {
        final permStatus = await Permission.camera.request();
        if (permStatus.isPermanentlyDenied) {
          if (mounted) {
            setState(() {
              _enrollState = EnrollState.failed;
              _errorMessage =
                  'Izin kamera diblokir secara permanen. Silakan aktifkan izin kamera melalui setelan situs/perangkat.';
            });
          }
          return;
        }
      } catch (_) {
        // Fallback for platforms where permission_handler is not fully supported
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _enrollState = EnrollState.failed;
          _errorMessage = 'Tidak ada sensor kamera yang terdeteksi di perangkat.';
        });
        return;
      }

      int frontIdx = _cameras!.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _selectedCameraIdx = frontIdx != -1 ? frontIdx : 0;

      await _setupCameraController(_cameras![_selectedCameraIdx]);
      // Initialize AI face detector on web
      await WebFaceDetector.init();
    } catch (e) {
      if (mounted) {
        final errText = e.toString();
        setState(() {
          _enrollState = EnrollState.failed;
          if (errText.contains('CameraAccessDenied') ||
              errText.toLowerCase().contains('denied') ||
              errText.toLowerCase().contains('permission')) {
            _errorMessage =
                'Izin kamera belum diaktifkan atau diblokir oleh peramban (Chrome/Safari).';
          } else {
            _errorMessage = 'Gagal mengakses kamera: $e';
          }
        });
      }
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    // Buang controller lama dulu supaya stream kamera tidak tertinggal.
    // Di web, stream yang masih hidup membuat getUserMedia berikutnya gagal
    // dengan NotReadableError (cameraNotReadable) saat init ulang.
    await _disposeCamera();

    // Web kadang melaporkan kamera "sibuk" sesaat (NotReadableError) karena
    // driver/peramban belum melepas stream. Coba beberapa kali dengan jeda.
    const int maxAttempts = 4;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _cameraController = controller;

      try {
        await controller.initialize();
        try {
          await controller.setZoomLevel(await controller.getMinZoomLevel());
        } catch (_) {}

        if (mounted) {
          setState(() {
            _isCameraReady = true;
            _enrollState = EnrollState.ready;
            _dynamicFeedback = 'Posisikan wajah Anda di dalam lingkaran';
          });
          _startAutoCaptureTimer();
        }
        return;
      } catch (e) {
        _cameraErrorDetail = e.toString();
        TelemetryService.report('camera', e);
        try {
          await controller.dispose();
        } catch (_) {}
        _cameraController = null;
        if (attempt < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 350 * attempt));
        }
      }
    }

    if (mounted) {
      setState(() {
        _enrollState = EnrollState.failed;
        _errorMessage = 'Gagal inisialisasi kamera: $_cameraErrorDetail';
      });
    }
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    _autoCaptureTimer?.cancel();
    HapticFeedback.lightImpact();
    setState(() => _isCameraReady = false);

    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras!.length;
    await _setupCameraController(_cameras![_selectedCameraIdx]);
  }

  void _startAutoCaptureTimer() {
    _autoCaptureTimer?.cancel();
    if (!_isCameraReady ||
        _cameraController == null ||
        _enrollState != EnrollState.ready ||
        _currentStep >= 5) {
      return;
    }

    _stepHoldProgress = 0.0;
    _isFaceDetected = false;
    _isPoseMatching = false;
    const intervalMs = 80;

    _autoCaptureTimer =
        Timer.periodic(const Duration(milliseconds: intervalMs), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_enrollState != EnrollState.ready) {
        timer.cancel();
        return;
      }

      final face = await WebFaceDetector.detect();

      if (face.isSupported) {
        if (!face.detected) {
          // No face in camera! Never advance the timer or snap empty background
          if (mounted) {
            setState(() {
              _isFaceDetected = false;
              _isPoseMatching = false;
              _stepHoldProgress = math.max(0.0, _stepHoldProgress - 0.15);
              _dynamicFeedback = 'Wajah belum terdeteksi. Posisikan wajah di lingkaran';
            });
          }
          return;
        }

        // Face is detected! Verify if pose matches current step
        bool matches = false;
        String feedback = '';

        switch (_currentStep) {
          case 0: // Hadap lurus
            matches = face.yaw.abs() < 0.28;
            feedback = matches
                ? 'Pose Lurus Pas • Tahan Posisi...'
                : 'Hadap lurus ke kamera';
            break;
          case 1: // Toleh sedikit ke kiri
            matches = face.yaw.abs() > 0.08;
            feedback = matches
                ? 'Sudut Toleh Terdeteksi • Tahan...'
                : 'Tolehkan kepala sedikit ke kiri Anda';
            break;
          case 2: // Toleh sedikit ke kanan
            matches = face.yaw.abs() > 0.08;
            feedback = matches
                ? 'Sudut Toleh Terdeteksi • Tahan...'
                : 'Tolehkan kepala sedikit ke kanan Anda';
            break;
          case 3: // Senyum santai
            matches = face.smile > 0.14 || face.yaw.abs() < 0.25;
            feedback = matches
                ? 'Senyum Terdeteksi • Tahan...'
                : 'Tersenyumlah wajar ke arah kamera';
            break;
          case 4: // Kunci lurus final
            matches = face.yaw.abs() < 0.25;
            feedback = matches
                ? 'Mengunci Biometrik Face ID...'
                : 'Tatap lurus kembali ke tengah lingkaran';
            break;
        }

        if (mounted) {
          setState(() {
            _isFaceDetected = true;
            _isPoseMatching = matches;
            _dynamicFeedback = feedback;
            if (matches) {
              // Rapid 550ms auto-capture when pose aligns
              _stepHoldProgress =
                  (_stepHoldProgress + (intervalMs / 550)).clamp(0.0, 1.0);
            } else {
              _stepHoldProgress = math.max(0.0, _stepHoldProgress - 0.08);
            }
          });
        }
      } else {
        // When AI face detector is loading or not active, DO NOT auto-snap blindly!
        if (mounted) {
          setState(() {
            _isFaceDetected = false;
            _isPoseMatching = false;
            _stepHoldProgress = 0.0;
            _dynamicFeedback =
                'Arahkan wajah sesuai panduan lalu ketuk tombol foto di bawah';
          });
        }
      }

      if (_stepHoldProgress >= 1.0) {
        timer.cancel();
        _captureAngle();
      }
    });
  }

  void _captureAngleManual() {
    _autoCaptureTimer?.cancel();
    _captureAngle();
  }

  Future<void> _captureAngle() async {
    if (!_isCameraReady ||
        _cameraController == null ||
        _enrollState == EnrollState.processing ||
        _enrollState == EnrollState.capturing) {
      return;
    }

    _autoCaptureTimer?.cancel();
    HapticFeedback.mediumImpact();

    setState(() {
      _showShutterFlash = true;
      _enrollState = EnrollState.capturing;
    });

    try {
      final xFile = await _cameraController!.takePicture();
      final bytes = await xFile.readAsBytes();
      final rawB64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final compressedB64 = await _compressPhoto(bytes, rawB64);

      _capturedImages.add(compressedB64);

      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() => _showShutterFlash = false);
      }

      if (_currentStep < 4) {
        setState(() {
          _currentStep++;
          _stepHoldProgress = 0.0;
          _enrollState = EnrollState.ready;
          _dynamicFeedback = 'Menyiapkan sudut foto berikutnya...';
        });
        HapticFeedback.selectionClick();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && _enrollState == EnrollState.ready) {
            _startAutoCaptureTimer();
          }
        });
      } else {
        // All 5 angles captured! Process enrollment
        _submitEnrollment();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _showShutterFlash = false;
          _enrollState = EnrollState.ready;
          _stepHoldProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
        _startAutoCaptureTimer();
      }
    }
  }

  Future<String> _compressPhoto(Uint8List bytes, String rawB64) async {
    try {
      if (kIsWeb) {
        return await WebFaceDetector.compressImage(rawB64, maxDim: 360, quality: 0.65);
      } else {
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final resized = img.copyResize(decoded, width: 360);
          final jpgBytes = img.encodeJpg(resized, quality: 65);
          return 'data:image/jpeg;base64,${base64Encode(jpgBytes)}';
        }
      }
    } catch (_) {}
    return rawB64;
  }

  Future<void> _submitEnrollment() async {
    _autoCaptureTimer?.cancel();
    setState(() {
      _enrollState = EnrollState.processing;
    });

    try {
      final res = widget.onSubmitExternal != null
          ? await widget.onSubmitExternal!(_capturedImages)
          : await ApiService.enrollFace(
              faceImagesBase64: _capturedImages,
              deviceId: await DeviceService.getDeviceId(),
            );

      if (res.success) {
        HapticFeedback.heavyImpact();
        _glyphSuccessController.forward();

        if (widget.onSubmitExternal == null) {
          final currentUser = StorageService.getUser();
          if (currentUser != null) {
            await StorageService.saveUser(
              currentUser.copyWith(isFaceEnrolled: true),
            );
          }
        }

        setState(() {
          _enrollState = EnrollState.success;
        });

        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) {
            if (widget.onSubmitExternal != null) {
              Navigator.of(context).pop(true);
            } else if (widget.isOnboarding) {
              Navigator.of(context).pushAndRemoveUntil(
                CupertinoPageRoute(builder: (_) => const DashboardScreen()),
                (route) => false,
              );
            } else {
              Navigator.of(context).pop(true);
            }
          }
        });
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _enrollState = EnrollState.failed;
          _errorMessage = res.message;
        });
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _enrollState = EnrollState.failed;
          _errorMessage = 'Gagal menyimpan wajah: $e';
        });
      }
    }
  }

  void _resetAndRetry() {
    _autoCaptureTimer?.cancel();
    HapticFeedback.lightImpact();
    setState(() {
      _capturedImages.clear();
      _currentStep = 0;
      _stepHoldProgress = 0.0;
      _isFaceDetected = false;
      _isPoseMatching = false;
      _enrollState = EnrollState.ready;
      _errorMessage = '';
    });
    if (!_isCameraReady || _cameraController == null) {
      _initCamera();
    } else {
      _startAutoCaptureTimer();
    }
  }

  @override
  void dispose() {
    _autoCaptureTimer?.cancel();
    _pulseController.dispose();
    _glyphSuccessController.dispose();
    _disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curStepData = _stepsInfo[_currentStep.clamp(0, 4)];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxH = constraints.maxHeight;
            final double maxW = constraints.maxWidth;
            // Proportional circle size for small and large screens
            final double circleSize =
                (maxH * 0.35).clamp(170.0, (maxW * 0.64).clamp(180.0, 250.0));

            return Stack(
              fit: StackFit.expand,
              children: [
                // Main Flow in a Single Non-Overlapping Column
                Column(
                  children: [
                    // 1. Top Header Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Button
                          GestureDetector(
                            onTap: () async {
                              _autoCaptureTimer?.cancel();
                              HapticFeedback.lightImpact();
                              if (widget.isOnboarding) {
                                final nav = Navigator.of(context);
                                final logout = await showCupertinoDialog<bool>(
                                  context: context,
                                  builder: (ctx) => CupertinoAlertDialog(
                                    title: const Text('Batalkan Pendaftaran Wajah?'),
                                    content: const Text(
                                      'Perekaman wajah wajib dilakukan agar Anda dapat melakukan presensi kehadiran di sekolah.',
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        child: const Text('Lanjutkan Rekam'),
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                      ),
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('Keluar Akun'),
                                      ),
                                    ],
                                  ),
                                );
                                if (logout == true) {
                                  await StorageService.clear();
                                  nav.pushAndRemoveUntil(
                                    CupertinoPageRoute(
                                        builder: (_) => const LoginScreen()),
                                    (route) => false,
                                  );
                                } else if (mounted) {
                                  _startAutoCaptureTimer();
                                }
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF1C1C1E).withOpacity(0.85),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),

                          // Pill Title
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                    const Color(0xFF1C1C1E).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    const Color(0xFF30D158).withOpacity(0.40),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.face_retouching_natural_rounded,
                                  color: Color(0xFF30D158),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.isOnboarding
                                      ? 'Langkah 2: Rekam Wajah'
                                      : 'Face ID Setup',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Camera Flip Button
                          GestureDetector(
                            onTap: _switchCamera,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF1C1C1E).withOpacity(0.85),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.flip_camera_ios_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Step Title & Subtitle
                    const SizedBox(height: 4),
                    Text(
                      'Perekaman Wajah Biometrik',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Foto ${_currentStep + 1} dari 5: ${curStepData['title']}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF30D158),
                      ),
                    ),

                    const Spacer(),

                    // 3. Central circular Face ID viewport
                    Center(
                      child: SizedBox(
                        width: circleSize + 56,
                        height: circleSize + 56,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 60 Radial Ticks Ring
                            CustomPaint(
                              size: Size(circleSize + 56, circleSize + 56),
                              painter: _EnrollRadialTicksPainter(
                                completedSteps: _capturedImages.length,
                                totalSteps: 5,
                                stepProgress: _stepHoldProgress,
                                isSuccess: _enrollState == EnrollState.success,
                              ),
                            ),

                            // Central circular camera viewport
                            ClipOval(
                              child: Container(
                                width: circleSize,
                                height: circleSize,
                                color: Colors.black,
                                child: _buildCameraViewport(circleSize),
                              ),
                            ),

                            // Dynamic Status Glow Ring Over Viewport
                            IgnorePointer(
                              child: Container(
                                width: circleSize,
                                height: circleSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _enrollState == EnrollState.success
                                        ? const Color(0xFF30D158)
                                        : (_isPoseMatching
                                            ? const Color(0xFF30D158)
                                            : (_isFaceDetected
                                                ? const Color(0xFF007AFF)
                                                : Colors.white.withOpacity(0.32))),
                                    width: 3.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isPoseMatching
                                              ? const Color(0xFF30D158)
                                              : Colors.black)
                                          .withOpacity(0.40),
                                      blurRadius: 24,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Shutter Flash
                            if (_showShutterFlash)
                              Container(
                                width: circleSize,
                                height: circleSize,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),

                            // Success Overlay Checkmark
                            if (_enrollState == EnrollState.success)
                              Container(
                                width: circleSize,
                                height: circleSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.75),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: const Color(0xFF30D158),
                                    size: circleSize * 0.42,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // 4. Directional Guide Pill with Real-Time Face AI Feedback
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _isPoseMatching
                                ? const Color(0xFF30D158).withOpacity(0.55)
                                : (_isFaceDetected
                                    ? const Color(0xFF007AFF).withOpacity(0.40)
                                    : Colors.white.withOpacity(0.12)),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Progress Bar Line
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: _stepHoldProgress.clamp(0.0, 1.0),
                                backgroundColor: Colors.white.withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _isPoseMatching
                                      ? const Color(0xFF30D158)
                                      : const Color(0xFF007AFF),
                                ),
                                minHeight: 4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isPoseMatching
                                        ? const Color(0xFF30D158)
                                        : (_isFaceDetected
                                            ? const Color(0xFF007AFF)
                                            : const Color(0xFFFF3B30)),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Flexible(
                                  child: Text(
                                    curStepData['hint']!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _dynamicFeedback.isNotEmpty
                                  ? _dynamicFeedback
                                  : curStepData['instruction']!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _isPoseMatching
                                    ? const Color(0xFF30D158)
                                    : (_isFaceDetected
                                        ? const Color(0xFF99CCFF)
                                        : const Color(0xFFFF9E9A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 5. 5-Step Capsule Segmented Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (idx) {
                        final isDone = _capturedImages.length > idx;
                        final isCurrent = _currentStep == idx;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3.5),
                          height: 5.5,
                          width: isDone ? 32 : (isCurrent ? 24 : 12),
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFF30D158)
                                : (isCurrent
                                    ? Colors.white.withOpacity(0.80)
                                    : Colors.white.withOpacity(0.20)),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: isDone
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF30D158)
                                          .withOpacity(0.50),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 12),

                    // 6. Manual Shutter Button + Processing Spinner
                    if (_enrollState == EnrollState.ready ||
                        _enrollState == EnrollState.capturing)
                      GestureDetector(
                        onTap: _captureAngleManual,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3.2,
                            ),
                            color: Colors.white.withOpacity(0.12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF34C759),
                                  Color(0xFF34C759),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x6610B981),
                                  blurRadius: 14,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (_enrollState == EnrollState.processing)
                      Column(
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: Color(0xFF30D158),
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Menyimpan Biometrik Wajah ke Server AI...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF30D158),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 6),
                    Text(
                      'Otomatis terfoto saat menatap panduan, atau ketuk tombol di atas',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: Colors.white.withOpacity(0.50),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),

                //  7. Error Modal Overlay
                if (_enrollState == EnrollState.failed)
                  Builder(
                    builder: (context) {
                      final isPermError = _errorMessage
                              .toLowerCase()
                              .contains('izin') ||
                          _errorMessage.contains('CameraAccessDenied') ||
                          _errorMessage.toLowerCase().contains('denied') ||
                          _errorMessage.toLowerCase().contains('permission');

                      return Container(
                        color: Colors.black.withOpacity(0.85),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Center(
                            child: Container(
                              width: 320,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 26),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E).withOpacity(0.96),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: isPermError
                                      ? const Color(0xFFFF9500).withOpacity(0.50)
                                      : const Color(0xFFFF6961).withOpacity(0.40),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isPermError
                                        ? const Color(0xFFFF9500).withOpacity(0.25)
                                        : const Color(0xFFFF3B30).withOpacity(0.30),
                                    blurRadius: 36,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isPermError
                                          ? const Color(0xFFFF9500)
                                              .withOpacity(0.18)
                                          : const Color(0xFFFF3B30)
                                              .withOpacity(0.18),
                                      border: Border.all(
                                        color: isPermError
                                            ? const Color(0xFFFFCC00)
                                            : const Color(0xFFFF6961),
                                        width: 2.2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isPermError
                                            ? Icons.videocam_off_rounded
                                            : Icons.close_rounded,
                                        color: isPermError
                                            ? const Color(0xFFFFCC00)
                                            : const Color(0xFFFF6961),
                                        size: 34,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    isPermError
                                        ? 'Izin Kamera Diperlukan'
                                        : 'Pendaftaran Gagal',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _errorMessage.isNotEmpty
                                        ? _errorMessage
                                        : 'Gagal memproses biometrik wajah. Pastikan pencahayaan cukup dan wajah terlihat jelas.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: isPermError
                                          ? const Color(0xFFFFECC2)
                                          : const Color(0xFFFFEBEB),
                                    ),
                                  ),
                                  if (isPermError) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.12),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.tune_rounded,
                                                  size: 14,
                                                  color: Color(0xFF007AFF)),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Cara Buka Izin di Chrome / Safari:',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '1. Klik ikon Setelan Situs (tune ) di sebelah kiri URL presensi.\n'
                                            '2. Pada baris "Kamera", ubah ke "Izinkan" (Allow).\n'
                                            '3. Ketuk tombol di bawah untuk menyambungkan ulang.',
                                            style: GoogleFonts.inter(
                                              fontSize: 10.5,
                                              height: 1.45,
                                              color: const Color(0xFFC7C7CC),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _resetAndRetry,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        isPermError
                                            ? 'Coba Hubungkan Kamera Lagi'
                                            : 'Ulangi Perekaman',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isPermError) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text(
                                        'Kembali ke Beranda',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFAEAEB2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCameraViewport(double size) {
    if (!_isCameraReady || _cameraController == null) {
      return Container(
        width: size,
        height: size,
        color: const Color(0xFF1C1C1E),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF30D158),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final previewSize = _cameraController!.value.previewSize;
    final double pw = previewSize != null
        ? math.min(previewSize.width, previewSize.height)
        : 720.0;
    final double ph = previewSize != null
        ? math.max(previewSize.width, previewSize.height)
        : 1280.0;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: pw,
            height: ph,
            child: _cameraController!.buildPreview(),
          ),
        ),
      ),
    );
  }
}

/// 60 Radial Ticks Custom Painter for Enrollment with Dynamic Progress
class _EnrollRadialTicksPainter extends CustomPainter {
  final int completedSteps;
  final int totalSteps;
  final double stepProgress; // 0.0 to 1.0 within the current step
  final bool isSuccess;

  _EnrollRadialTicksPainter({
    required this.completedSteps,
    required this.totalSteps,
    this.stepProgress = 0.0,
    required this.isSuccess,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 44) / 2;

    const int totalTicks = 60;
    // Each step accounts for 12 ticks
    final double ticksCompleted =
        (completedSteps * 12.0) + (stepProgress * 12.0);
    final int activeTicks =
        isSuccess ? 60 : ticksCompleted.clamp(0.0, 60.0).round();

    final inactivePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = const Color(0xFF30D158)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const double tickLen = 12.0;
    const double startAngle = -math.pi / 2;

    for (int i = 0; i < totalTicks; i++) {
      final angle = startAngle + (i * (2 * math.pi / totalTicks));
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);

      final p1 = Offset(cx + (radius * cosA), cy + (radius * sinA));
      final p2 = Offset(
        cx + ((radius + tickLen) * cosA),
        cy + ((radius + tickLen) * sinA),
      );

      if (i < activeTicks) {
        canvas.drawLine(p1, p2, activePaint);
      } else {
        canvas.drawLine(p1, p2, inactivePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EnrollRadialTicksPainter oldDelegate) {
    return oldDelegate.completedSteps != completedSteps ||
        oldDelegate.stepProgress != stepProgress ||
        oldDelegate.isSuccess != isSuccess;
  }
}
