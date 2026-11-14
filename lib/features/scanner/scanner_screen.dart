import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/device_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/models/session_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/telemetry_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/scan_queue_service.dart';
import 'package:image/image.dart' as img;

//  SCANNER SCREEN — Face ID scan experience
//  • Natural 1x Wide Angle View (No awkward digital zoom)
//  • Apple Face ID Setup 3D Radial Tick Dial (60 Sensory Rays)
//  • Dynamic TrueDepth Holographic Biometric Depth Mesh
//  • Auto-Recognition & Tactile Shutter Trigger
//  • Iconic Apple Face ID Verification HUD Modal
//  • Vector Morphing Face Glyph -> Spring Checkmark

enum ScanState { ready, processing, success, failed }
enum LivenessState { waitingFace, faceAligned, actionSuccess }

class ScannerScreen extends StatefulWidget {
  final GeofenceConfig geofenceConfig;
  final SessionDetail? sessionDetail;

  const ScannerScreen({
    super.key,
    required this.geofenceConfig,
    this.sessionDetail,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIdx = 0;
  bool _isCameraReady = false;
  String _cameraErrorDetail = '';

  ScanState _scanState = ScanState.ready;
  LivenessState _livenessState = LivenessState.waitingFace;
  double _actionProgress = 0.0; // 0.0 to 1.0

  String _livenessPrompt = 'Posisikan wajah di dalam lingkaran';
  String _scanErrorMessage = '';
  String _waktuScanSuccess = '';
  bool _scanQueuedOffline = false;
  bool _showShutterFlash = false;

  GeofenceResult? _geofenceResult;
  bool _isGpsValid = false;
  Timer? _gpsTimer;
  Timer? _autoAlignmentTimer;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _scanBeamController;
  late Animation<double> _scanBeamAnimation;

  late AnimationController _hudMorphController;
  late Animation<double> _hudMorphAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initGps();
    _initCamera();
  }

  void _initAnimations() {
    // 1. Subtle breathing pulse for Face ID Ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 2. Holographic depth scanning beam traversing the face
    _scanBeamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanBeamAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanBeamController, curve: Curves.easeInOut),
    );

    // 3. Apple Face ID HUD morph animation (Brackets snap & Checkmark pop)
    _hudMorphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _hudMorphAnimation = CurvedAnimation(
      parent: _hudMorphController,
      curve: Curves.elasticOut,
    );
  }

  Future<void> _initGps() async {
    if (!widget.geofenceConfig.active) {
      if (!mounted) return;
      setState(() {
        _isGpsValid = true;
      });
      return;
    }

    final result = await LocationService.verifyGeofence(widget.geofenceConfig);
    if (!mounted) return;
    setState(() {
      _geofenceResult = result;
      _isGpsValid = result.isInside && !result.isMocked;
      if (!_isGpsValid && result.errorMessage != null) {
        _livenessPrompt = result.errorMessage!;
      }
    });

    // Periodic GPS refresh every 10s
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!widget.geofenceConfig.active) return;
      final res = await LocationService.verifyGeofence(widget.geofenceConfig);
      if (mounted) {
        setState(() {
          _geofenceResult = res;
          _isGpsValid = res.isInside && !res.isMocked;
        });
      }
    });
  }

  Future<void> _initCamera() async {
    try {
      try {
        await Permission.camera.request();
      } catch (_) {}

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _scanState = ScanState.failed;
          _scanErrorMessage = 'Kamera tidak ditemukan di perangkat ini.';
        });
        return;
      }

      // Default to front-facing camera for Apple Face ID
      int frontIdx = _cameras!.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _selectedCameraIdx = frontIdx != -1 ? frontIdx : 0;

      await _setupCameraController(_cameras![_selectedCameraIdx]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanState = ScanState.failed;
          _scanErrorMessage = 'Gagal mengakses izin kamera perangkat.';
        });
      }
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    // Buang controller lama dulu agar stream kamera tidak tertinggal
    // (web: stream hidup -> NotReadableError saat init ulang).
    await _disposeCamera();

    // Web kadang melaporkan kamera "sibuk" sesaat; coba beberapa kali.
    const int maxAttempts = 4;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      // Use ResolutionPreset.high (1280x720 / 16:9) to eliminate unnatural 4:3 zoom cropping
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;

      try {
        await controller.initialize();
        // Reset zoom level to minimum 1.0x wide-angle
        try {
          final minZoom = await controller.getMinZoomLevel();
          await controller.setZoomLevel(minZoom);
        } catch (_) {
          // Zoom API not supported on all web platforms
        }

        if (!mounted) return;
        setState(() {
          _isCameraReady = true;
          _armScanner();
        });
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
        _scanState = ScanState.failed;
        _scanErrorMessage = 'Gagal menginisialisasi kamera: $_cameraErrorDetail';
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
    HapticFeedback.lightImpact();
    _autoAlignmentTimer?.cancel();
    setState(() => _isCameraReady = false);

    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras!.length;
    await _setupCameraController(_cameras![_selectedCameraIdx]);
  }

  void _armScanner() {
    _autoAlignmentTimer?.cancel();
    _scanState = ScanState.ready;
    _livenessState = LivenessState.waitingFace;
    _actionProgress = 0.0;
    _livenessPrompt = 'Posisikan wajah di dalam lingkaran';
    _hudMorphController.reset();
  }

  /// Apple Face ID Biometric Trigger on Shutter Tap
  void _onShutterPressed() {
    if (_scanState != ScanState.ready ||
        !_isCameraReady ||
        _cameraController == null) {
      return;
    }

    // Geofence enforcement if enabled by admin
    if (widget.geofenceConfig.active && !_isGpsValid) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _geofenceResult?.errorMessage ??
                'Presensi ditolak: Anda berada di luar radius resmi sekolah.',
          ),
          backgroundColor: const Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _autoAlignmentTimer?.cancel();
    HapticFeedback.selectionClick();
    setState(() {
      _livenessState = LivenessState.faceAligned;
      _livenessPrompt = 'Memindai Biometrik Wajah...';
      _actionProgress = 0.15;
    });

    // Face ID radial tick sweep: 10 steps x 35ms = 350ms
    const int steps = 10;
    int currentStep = 0;
    _autoAlignmentTimer =
        Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (!mounted || _scanState != ScanState.ready) {
        timer.cancel();
        return;
      }

      currentStep++;
      final progress = (0.15 + (currentStep / steps) * 0.85).clamp(0.0, 1.0);
      setState(() {
        _actionProgress = progress;
      });

      if (currentStep % 3 == 0) {
        HapticFeedback.lightImpact();
      }

      if (currentStep >= steps) {
        timer.cancel();
        _captureAndSubmit();
      }
    });
  }

  Future<void> _captureAndSubmit() async {
    if (_scanState == ScanState.processing ||
        !_isCameraReady ||
        _cameraController == null) {
      return;
    }

    // Geofence enforcement if enabled by admin
    if (widget.geofenceConfig.active && !_isGpsValid) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _geofenceResult?.errorMessage ??
                'Presensi ditolak: Anda berada di luar radius resmi sekolah.',
          ),
          backgroundColor: const Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Trigger visual Apple Shutter Flash & Haptics
    HapticFeedback.mediumImpact();
    setState(() {
      _showShutterFlash = true;
      _livenessState = LivenessState.actionSuccess;
      _actionProgress = 1.0;
      _livenessPrompt = 'Wajah Siap! Memverifikasi...';
    });

    await Future.delayed(const Duration(milliseconds: 140));
    if (mounted) {
      setState(() => _showShutterFlash = false);
    }

    setState(() {
      _scanState = ScanState.processing;
    });

    try {
      // 1. Capture picture from camera preview
      final xFile = await _cameraController!.takePicture();
      final bytes = await xFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // 2. Read GPS coordinates
      Position? pos;
      if (widget.geofenceConfig.active) {
        pos = _geofenceResult?.position ??
            await LocationService.getCurrentPosition();
      }
      final lat = pos?.latitude ?? widget.geofenceConfig.latitude;
      final lng = pos?.longitude ?? widget.geofenceConfig.longitude;
      final accuracy = pos?.accuracy ?? 10.0;
      final isMocked = (pos?.isMocked ?? false) ||
          await LocationService.isMockLocationNative();
      final gpsTimestampMs = pos?.timestamp.millisecondsSinceEpoch;

      // 3. Submit payload to Rust microservice API
      final deviceId = await DeviceService.getDeviceId();
      final res = await ApiService.submitFaceScan(
        imageBase64: base64Image,
        latitude: lat,
        longitude: lng,
        accuracy: accuracy,
        isMocked: isMocked,
        gpsTimestampMs: gpsTimestampMs,
        sesiId: widget.sessionDetail?.id,
        deviceId: deviceId,
      );

      if (!mounted) return;

      if (res.success) {
        // Double Apple Haptic Tick
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 120), () {
          HapticFeedback.mediumImpact();
        });

        _hudMorphController.forward();
        final waktu = res.data?['waktu_scan'] as String? ?? 'Tepat Waktu';
        setState(() {
          _scanState = ScanState.success;
          _waktuScanSuccess = waktu;
        });

        // Automatically pop back to dashboard after 1.8 seconds
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      } else if (res.offline && ScanQueueService.supportsOfflineQueue) {
        // B7. Tanpa koneksi: simpan lokal, kirim otomatis saat online kembali.
        var queuedImage = base64Image;
        try {
          final rawBytes = base64Decode(base64Image.split(',').last);
          final decoded = img.decodeImage(rawBytes);
          if (decoded != null) {
            final resized = img.copyResize(decoded, width: 720);
            queuedImage = 'data:image/jpeg;base64,'
                '${base64Encode(img.encodeJpg(resized, quality: 60))}';
          }
        } catch (_) {}

        await ScanQueueService.enqueue(
          imageBase64: queuedImage,
          latitude: lat,
          longitude: lng,
          accuracy: accuracy,
          isMocked: isMocked,
          gpsTimestampMs: gpsTimestampMs,
          sesiId: widget.sessionDetail?.id,
          deviceId: deviceId,
        );

        if (!mounted) return;
        HapticFeedback.mediumImpact();
        final pending = await ScanQueueService.pendingCount();
        setState(() {
          _scanState = ScanState.success;
          _scanQueuedOffline = true;
          _waktuScanSuccess = 'Tersimpan lokal • $pending menunggu';
        });
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _scanState = ScanState.failed;
          _scanErrorMessage = res.message;
        });
      }
    } catch (e, stack) {
      debugPrint('Error during capture/biometric submit: $e\n$stack');
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _scanState = ScanState.failed;
          _scanErrorMessage =
              'Gagal memproses gambar: ${e.toString().split('\n').first}';
        });
      }
    }
  }

  void _retryScan() {
    HapticFeedback.lightImpact();
    setState(() {
      _armScanner();
    });
  }

  @override
  void dispose() {
    _autoAlignmentTimer?.cancel();
    _gpsTimer?.cancel();
    _pulseController.dispose();
    _scanBeamController.dispose();
    _hudMorphController.dispose();
    _disposeCamera();
    super.dispose();
  }

  //  UI WIDGET TREE

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure Apple OLED Black
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Dynamic responsive diameter for Apple Face ID circle portal
          final circleDiameter =
              (constraints.maxWidth * 0.70).clamp(240.0, 290.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              //  1. Top Navigation Bar & Apple iOS Header
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      // iOS Navigation Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Glass Back / Close Button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E).withOpacity(0.85),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),

                          // GPS / Mode Geofence Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: !widget.geofenceConfig.active
                                  ? const Color(0xFF34C759).withOpacity(0.20)
                                  : (_isGpsValid
                                      ? const Color(0xFF34C759).withOpacity(0.20)
                                      : const Color(0xFFFF3B30).withOpacity(0.20)),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: !widget.geofenceConfig.active
                                    ? const Color(0xFF30D158).withOpacity(0.40)
                                    : (_isGpsValid
                                        ? const Color(0xFF30D158).withOpacity(0.40)
                                        : const Color(0xFFFF6961).withOpacity(0.40)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: !widget.geofenceConfig.active
                                        ? const Color(0xFF30D158)
                                        : (_isGpsValid
                                            ? const Color(0xFF30D158)
                                            : const Color(0xFFFF6961)),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  !widget.geofenceConfig.active
                                      ? 'Lokasi Bebas (Admin)'
                                      : (_isGpsValid ? 'GPS Terkunci' : 'Di Luar Area'),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Flip Camera Button
                          GestureDetector(
                            onTap: _switchCamera,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E).withOpacity(0.85),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                              child: const Icon(
                                Icons.flip_camera_ios_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Apple Face ID Header Title & Subtitle
                      Text(
                        'Face ID',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Posisikan wajah Anda di dalam lingkaran',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              //  2. Apple Face ID Center Biometric Portal
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // A. Apple Face ID 3D Radial Tick Dial (60 Sensory Rays)
                    AnimatedBuilder(
                      animation: Listenable.merge([_pulseAnimation, _scanBeamAnimation]),
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size(
                            circleDiameter + 70,
                            circleDiameter + 70,
                          ),
                          painter: _AppleFaceIdRadialTickPainter(
                            progress: _actionProgress,
                            livenessState: _livenessState,
                            pulseScale: _pulseAnimation.value,
                          ),
                        );
                      },
                    ),

                    // B. Clean Circular Camera Window (Natural 1x Wide Angle, NO Zoom Crop)
                    Container(
                      width: circleDiameter,
                      height: circleDiameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _livenessState == LivenessState.faceAligned
                                ? const Color(0xFF34C759).withOpacity(0.35)
                                : Colors.black.withOpacity(0.60),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Live Camera Feed
                            _buildCameraViewport(),

                            // TrueDepth Holographic Biometric Depth Mesh
                            AnimatedBuilder(
                              animation: _scanBeamAnimation,
                              builder: (context, _) {
                                return CustomPaint(
                                  painter: _BiometricMeshPainter(
                                    beamProgress: _scanBeamAnimation.value,
                                    progress: _actionProgress,
                                    isAligned: _livenessState ==
                                        LivenessState.faceAligned,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // C. Fine Inner Glass Ring
                    IgnorePointer(
                      child: Container(
                        width: circleDiameter,
                        height: circleDiameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _livenessState == LivenessState.faceAligned
                                ? const Color(0xFF30D158).withOpacity(0.70)
                                : Colors.white.withOpacity(0.30),
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              //  3. Bottom Apple Controls & Dynamic Status Capsule
              if (_scanState == ScanState.ready)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 34,
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Live Status Capsule (Dynamic Prompt + Percentage)
                        _buildAppleStatusCapsule(),

                        const SizedBox(height: 22),

                        // Apple-Style Shutter Button
                        GestureDetector(
                          onTap: _onShutterPressed,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3.5,
                              ),
                              color: Colors.white.withOpacity(0.12),
                            ),
                            padding: const EdgeInsets.all(5),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: _livenessState ==
                                          LivenessState.faceAligned
                                      ? [
                                          const Color(0xFF34C759),
                                          const Color(0xFF34C759)
                                        ]
                                      : [
                                          const Color(0xFF007AFF),
                                          const Color(0xFF007AFF)
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_livenessState ==
                                                LivenessState.faceAligned
                                            ? const Color(0xFF34C759)
                                            : const Color(0xFF007AFF))
                                        .withOpacity(0.45),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.face_unlock_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Posisikan seluruh wajah di dalam lingkaran lalu sentuh tombol untuk memindai',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              //  4. Shutter Flash Effect (140ms pure white flash)
              if (_showShutterFlash)
                Container(
                  color: Colors.white,
                ),

              //  5. Face ID system sheet modal overlays
              if (_scanState == ScanState.processing)
                _buildAppleFaceIdModal(
                  title: 'Memverifikasi Face ID',
                  subtitle: 'Mencocokkan biometrik ArcFace 512-D...',
                  isProcessing: true,
                ),

              if (_scanState == ScanState.success)
                _buildAppleFaceIdModal(
                  title: _scanQueuedOffline ? 'Tersimpan Offline' : 'Presensi Berhasil',
                  subtitle: _scanQueuedOffline
                      ? 'Presensi akan dikirim otomatis saat internet kembali ($_waktuScanSuccess)'
                      : (_waktuScanSuccess.isNotEmpty
                          ? 'Pukul $_waktuScanSuccess WIB • Tepat Waktu'
                          : 'Kehadiran telah tercatat di sistem'),
                  isSuccess: true,
                ),

              if (_scanState == ScanState.failed)
                _buildAppleFailedModal(),
            ],
          );
        },
      ),
    );
  }

  //  CAMERA VIEWPORT (Natural Wide Angle, 1:1 Aspect Fit)

  Widget _buildCameraViewport() {
    if (!_isCameraReady || _cameraController == null) {
      return Container(
        color: const Color(0xFF1C1C1E),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF007AFF),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    // Inside a 1:1 square/circle, FittedBox(fit: BoxFit.cover) preserves
    // the full horizontal sensor width (1x wide angle), resolving zoom crop!
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _cameraController!.value.previewSize?.height ?? 720,
        height: _cameraController!.value.previewSize?.width ?? 1280,
        child: _cameraController!.buildPreview(),
      ),
    );
  }

  //  DYNAMIC APPLE STATUS CAPSULE

  Widget _buildAppleStatusCapsule() {
    final percent = (_actionProgress * 100).toInt();
    final isAligned = _livenessState == LivenessState.faceAligned;
    final isComplete = percent >= 95;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(0.92),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isComplete
                  ? const Color(0xFF30D158).withOpacity(0.70)
                  : isAligned
                      ? const Color(0xFF007AFF).withOpacity(0.60)
                      : Colors.white.withOpacity(0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.40),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dynamic Glowing Dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isComplete
                      ? const Color(0xFF30D158)
                      : isAligned
                          ? const Color(0xFF007AFF)
                          : const Color(0xFFFFCC00),
                  boxShadow: [
                    BoxShadow(
                      color: (isComplete
                              ? const Color(0xFF30D158)
                              : isAligned
                                  ? const Color(0xFF007AFF)
                                  : const Color(0xFFFFCC00))
                          .withOpacity(0.70),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Prompt text
              Text(
                _livenessPrompt,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),

              if (isAligned) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? const Color(0xFF34C759).withOpacity(0.25)
                        : const Color(0xFF007AFF).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$percent%',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isComplete
                          ? const Color(0xFF30D158)
                          : const Color(0xFF007AFF),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  //  FACE ID HUD MODAL

  Widget _buildAppleFaceIdModal({
    required String title,
    required String subtitle,
    bool isProcessing = false,
    bool isSuccess = false,
  }) {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Center(
          child: ScaleTransition(
            scale: isSuccess ? _hudMorphAnimation : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 270,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E).withOpacity(0.94),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: isSuccess
                      ? const Color(0xFF30D158).withOpacity(0.50)
                      : Colors.white.withOpacity(0.18),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSuccess
                            ? const Color(0xFF34C759)
                            : const Color(0xFF007AFF))
                        .withOpacity(0.35),
                    blurRadius: 36,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Vector Apple Face ID Glyph (Brackets + Eyes/Nose/Smile or Checkmark)
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: AnimatedBuilder(
                      animation: _scanBeamAnimation,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _AppleFaceIdGlyphPainter(
                            isProcessing: isProcessing,
                            isSuccess: isSuccess,
                            beamProgress: _scanBeamAnimation.value,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSuccess
                          ? const Color(0xFFCDEFD8)
                          : const Color(0xFFAEAEB2),
                    ),
                  ),

                  if (isProcessing) ...[
                    const SizedBox(height: 18),
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppleFailedModal() {
    final msgLower = _scanErrorMessage.toLowerCase();
    final isDark = msgLower.contains('gelap') || msgLower.contains('pencahayaan');
    final isOverexposed = msgLower.contains('terang') || msgLower.contains('silau');
    final isPartial = msgLower.contains('utuh') ||
        msgLower.contains('terpotong') ||
        msgLower.contains('masker') ||
        msgLower.contains('mulut') ||
        msgLower.contains('dagu') ||
        msgLower.contains('dahi');
    final isNoFace = msgLower.contains('tidak ada wajah') ||
        msgLower.contains('tidak terdeteksi');

    String modalTitle = 'Wajah Tidak Cocok';
    IconData modalIcon = Icons.close_rounded;
    Color modalAccent = const Color(0xFFFF6961);
    Color modalBgGlow = const Color(0xFFFF3B30);

    if (isDark) {
      modalTitle = 'Pencahayaan Kurang';
      modalIcon = Icons.nightlight_round;
      modalAccent = const Color(0xFFFFCC00);
      modalBgGlow = const Color(0xFFFF9500);
    } else if (isOverexposed) {
      modalTitle = 'Pencahayaan Terlalu Silau';
      modalIcon = Icons.wb_sunny_rounded;
      modalAccent = const Color(0xFFFFCC00);
      modalBgGlow = const Color(0xFFFF9500);
    } else if (isPartial) {
      modalTitle = 'Wajah Tidak Utuh';
      modalIcon = Icons.face_retouching_off_rounded;
      modalAccent = const Color(0xFFFF9500);
      modalBgGlow = const Color(0xFFFF9500);
    } else if (isNoFace) {
      modalTitle = 'Wajah Tidak Terdeteksi';
      modalIcon = Icons.person_search_rounded;
      modalAccent = const Color(0xFFFF6961);
      modalBgGlow = const Color(0xFFFF3B30);
    }

    return Container(
      color: Colors.black.withOpacity(0.80),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Center(
          child: Container(
            width: 290,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withOpacity(0.95),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: modalAccent.withOpacity(0.40),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: modalBgGlow.withOpacity(0.30),
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
                    color: modalAccent.withOpacity(0.18),
                    border: Border.all(
                      color: modalAccent,
                      width: 2.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      modalIcon,
                      color: modalAccent,
                      size: 34,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  modalTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _scanErrorMessage.isNotEmpty
                      ? _scanErrorMessage
                      : 'Wajah tidak cocok dengan profil biometrik Anda. Pastikan pencahayaan cukup dan wajah terlihat jelas.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: const Color(0xFFFFEBEB),
                  ),
                ),

                const SizedBox(height: 22),

                // Apple Capsule Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _retryScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Coba Lagi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//  APPLE FACE ID 3D RADIAL TICK DIAL PAINTER (60 SENSORY RAYS)

class _AppleFaceIdRadialTickPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final LivenessState livenessState;
  final double pulseScale;

  _AppleFaceIdRadialTickPainter({
    required this.progress,
    required this.livenessState,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 50) / 2 * pulseScale;

    const int totalTicks = 60;
    final int activeTicks = (progress * totalTicks).round();

    final inactivePaint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;

    const double tickLen = 13.0;
    const double startAngle = -math.pi / 2; // Top 12 o'clock

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
        // Gradient from Apple Blue to Apple Emerald
        final t = i / totalTicks;
        final tickColor = Color.lerp(
          const Color(0xFF007AFF),
          const Color(0xFF30D158),
          t,
        )!;

        activePaint.color = tickColor;
        canvas.drawLine(p1, p2, activePaint);

        // Bright spark on leading active tick
        if (i == activeTicks - 1) {
          final glowPaint = Paint()
            ..color = const Color(0xFF30D158).withOpacity(0.80)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
          canvas.drawCircle(p2, 4.0, glowPaint);
        }
      } else {
        canvas.drawLine(p1, p2, inactivePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AppleFaceIdRadialTickPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.livenessState != livenessState ||
        oldDelegate.pulseScale != pulseScale;
  }
}

//  TRUEDEPTH HOLOGRAPHIC BIOMETRIC DEPTH MESH PAINTER

class _BiometricMeshPainter extends CustomPainter {
  final double beamProgress; // 0.0 to 1.0 (moving up/down)
  final double progress;
  final bool isAligned;

  _BiometricMeshPainter({
    required this.beamProgress,
    required this.progress,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Subtle Holographic Laser Scanning Beam
    final beamY = h * (0.15 + (beamProgress * 0.70));
    final beamRect = Rect.fromLTWH(w * 0.10, beamY - 1.5, w * 0.80, 3.0);

    final beamPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          isAligned
              ? const Color(0xFF30D158).withOpacity(0.70)
              : const Color(0xFF5AC8FA).withOpacity(0.55),
          Colors.transparent,
        ],
      ).createShader(beamRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(beamRect, const Radius.circular(2)),
      beamPaint,
    );

    // 2. Subtle TrueDepth Facial Landmark Feature Points
    if (isAligned) {
      final pointColor = const Color(0xFF30D158).withOpacity(0.65);
      final dotPaint = Paint()..color = pointColor;

      // Symmetric facial feature points (forehead, eyes, nose, cheeks, mouth, chin)
      final points = [
        Offset(w * 0.50, h * 0.28), // Forehead center
        Offset(w * 0.36, h * 0.40), // Left Eye
        Offset(w * 0.64, h * 0.40), // Right Eye
        Offset(w * 0.50, h * 0.52), // Nose Tip
        Offset(w * 0.30, h * 0.58), // Left Cheek
        Offset(w * 0.70, h * 0.58), // Right Cheek
        Offset(w * 0.42, h * 0.68), // Left Mouth Corner
        Offset(w * 0.58, h * 0.68), // Right Mouth Corner
        Offset(w * 0.50, h * 0.78), // Chin
      ];

      for (final p in points) {
        canvas.drawCircle(p, 2.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BiometricMeshPainter oldDelegate) {
    return oldDelegate.beamProgress != beamProgress ||
        oldDelegate.progress != progress ||
        oldDelegate.isAligned != isAligned;
  }
}

//  OFFICIAL APPLE FACE ID VECTOR GLYPH PAINTER

class _AppleFaceIdGlyphPainter extends CustomPainter {
  final bool isProcessing;
  final bool isSuccess;
  final double beamProgress;

  _AppleFaceIdGlyphPainter({
    required this.isProcessing,
    required this.isSuccess,
    required this.beamProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bracketColor = isSuccess ? const Color(0xFF30D158) : Colors.white;
    final bracketPaint = Paint()
      ..color = bracketColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    const double cornerLen = 16.0;
    const double radius = 8.0;

    //  1. Apple Face ID 4 Corner Brackets
    // Top-Left
    final tlPath = Path()
      ..moveTo(0, cornerLen)
      ..lineTo(0, radius)
      ..arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius))
      ..lineTo(cornerLen, 0);
    canvas.drawPath(tlPath, bracketPaint);

    // Top-Right
    final trPath = Path()
      ..moveTo(w - cornerLen, 0)
      ..lineTo(w - radius, 0)
      ..arcToPoint(Offset(w, radius), radius: const Radius.circular(radius))
      ..lineTo(w, cornerLen);
    canvas.drawPath(trPath, bracketPaint);

    // Bottom-Left
    final blPath = Path()
      ..moveTo(0, h - cornerLen)
      ..lineTo(0, h - radius)
      ..arcToPoint(Offset(radius, h), radius: const Radius.circular(radius))
      ..lineTo(cornerLen, h);
    canvas.drawPath(blPath, bracketPaint);

    // Bottom-Right
    final brPath = Path()
      ..moveTo(w - cornerLen, h)
      ..lineTo(w - radius, h)
      ..arcToPoint(Offset(w, h - radius), radius: const Radius.circular(radius))
      ..lineTo(w, h - cornerLen);
    canvas.drawPath(brPath, bracketPaint);

    //  2. Interior: Face Glyph OR Apple Checkmark
    if (isSuccess) {
      // Bold Apple Emerald Checkmark
      final checkPaint = Paint()
        ..color = const Color(0xFF30D158)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final checkPath = Path()
        ..moveTo(w * 0.28, h * 0.52)
        ..lineTo(w * 0.44, h * 0.68)
        ..lineTo(w * 0.74, h * 0.34);

      canvas.drawPath(checkPath, checkPaint);
    } else {
      // Face Features (Eyes, Nose, Smile)
      final featurePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;

      // Left Eye
      canvas.drawLine(
        Offset(w * 0.34, h * 0.35),
        Offset(w * 0.34, h * 0.46),
        featurePaint,
      );

      // Right Eye
      canvas.drawLine(
        Offset(w * 0.66, h * 0.35),
        Offset(w * 0.66, h * 0.46),
        featurePaint,
      );

      // Nose ('L' curve)
      final nosePath = Path()
        ..moveTo(w * 0.50, h * 0.36)
        ..lineTo(w * 0.50, h * 0.53)
        ..lineTo(w * 0.56, h * 0.53);
      canvas.drawPath(nosePath, featurePaint);

      // Smile Arc
      final smileRect = Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.62),
        width: w * 0.38,
        height: h * 0.22,
      );
      canvas.drawArc(smileRect, 0.2, math.pi - 0.4, false, featurePaint);

      // Scanning Beam
      if (isProcessing) {
        final beamY = h * (0.20 + (beamProgress * 0.60));
        final beamPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFF007AFF).withOpacity(0.80),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, beamY - 1, w, 2));

        canvas.drawLine(
          Offset(w * 0.15, beamY),
          Offset(w * 0.85, beamY),
          beamPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AppleFaceIdGlyphPainter oldDelegate) {
    return oldDelegate.isProcessing != isProcessing ||
        oldDelegate.isSuccess != isSuccess ||
        oldDelegate.beamProgress != beamProgress;
  }
}
