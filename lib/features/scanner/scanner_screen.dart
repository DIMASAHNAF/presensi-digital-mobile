import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/session_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/location_service.dart';

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

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIdx = 1; // Default to front-facing camera

  bool _isCameraReady = false;
  bool _isSubmitting = false;
  String _statusMessage = 'Arahkan wajah Anda ke dalam bingkai';

  GeofenceResult? _geofenceResult;
  bool _isGpsValid = false;
  Timer? _gpsTimer;

  late AnimationController _animController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initGps();
    _initCamera();
  }

  void _initAnimation() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initGps() async {
    final result = await LocationService.verifyGeofence(widget.geofenceConfig);
    if (!mounted) return;
    setState(() {
      _geofenceResult = result;
      _isGpsValid = result.isInside && !result.isMocked;
      if (!_isGpsValid && result.errorMessage != null) {
        _statusMessage = result.errorMessage!;
      }
    });

    // Periodic check
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
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
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _statusMessage = 'Kamera tidak ditemukan di perangkat ini.');
        return;
      }

      // Find front camera
      int frontIdx = _cameras!.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _selectedCameraIdx = frontIdx != -1 ? frontIdx : 0;

      await _setupCameraController(_cameras![_selectedCameraIdx]);
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Gagal mengakses izin kamera.');
      }
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.medium, // 640x480 - optimal for AI biometrics and network payload
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Gagal menginisialisasi kamera.');
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    setState(() => _isCameraReady = false);
    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras!.length;
    await _setupCameraController(_cameras![_selectedCameraIdx]);
  }

  Future<void> _captureAndSubmit() async {
    if (_isSubmitting || !_isCameraReady || _cameraController == null) return;

    // Check Geofence
    if (!_isGpsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_geofenceResult?.errorMessage ?? 'Presensi gagal: Di luar area sekolah.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = 'Memverifikasi Biometrik ArcFace 512-D...';
    });

    try {
      // 1. Take picture
      final xFile = await _cameraController!.takePicture();
      final bytes = await File(xFile.path).readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // 2. Obtain current GPS coords
      final pos = _geofenceResult?.position ?? await LocationService.getCurrentPosition();
      final lat = pos?.latitude ?? widget.geofenceConfig.latitude;
      final lng = pos?.longitude ?? widget.geofenceConfig.longitude;
      final accuracy = pos?.accuracy ?? 10.0;
      final isMocked = pos?.isMocked ?? false;

      // 3. Submit to Golang API
      final res = await ApiService.submitFaceScan(
        imageBase64: base64Image,
        latitude: lat,
        longitude: lng,
        accuracy: accuracy,
        isMocked: isMocked,
      );

      // Clean up temporary image
      try {
        await File(xFile.path).delete();
      } catch (_) {}

      if (!mounted) return;

      if (res.success) {
        _showSuccessDialog(res.message, res.data);
      } else {
        setState(() {
          _isSubmitting = false;
          _statusMessage = res.message;
        });
        _showErrorDialog(res.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _statusMessage = 'Gagal memproses gambar. Coba lagi.';
        });
      }
    }
  }

  void _showSuccessDialog(String message, Map<String, dynamic>? data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 18),
            Text(
              'Presensi Berhasil!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(true); // close scanner & return success
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali ke Beranda'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.dangerBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: AppColors.danger, size: 48),
            ),
            const SizedBox(height: 18),
            Text(
              'Verifikasi Gagal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Coba Lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _animController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Viewport
          if (_isCameraReady && _cameraController != null)
            Center(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // 2. Custom Apple FaceID Oval Cutout & HUD Overlay
          CustomPaint(
            painter: FaceScannerOverlayPainter(
              scanProgress: _scanAnimation.value,
              isGpsValid: _isGpsValid,
            ),
          ),

          // 3. Top Bar (Close Button, Camera Switch, GPS Badge)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_isGpsValid ? AppColors.success : AppColors.danger).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isGpsValid ? Icons.satellite_alt_rounded : Icons.location_off_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isGpsValid ? 'GPS Terkunci' : 'Di Luar Area',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                    onPressed: _switchCamera,
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Controls & Status Message
          Positioned(
            left: 20,
            right: 20,
            bottom: 36,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Text Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Capture Action Button
                  GestureDetector(
                    onTap: _isSubmitting ? null : _captureAndSubmit,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isGpsValid ? Colors.white : Colors.white.withOpacity(0.4),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isGpsValid ? AppColors.primaryBlue : Colors.grey,
                        ),
                        child: _isSubmitting
                            ? const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              )
                            : const Icon(Icons.camera_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FaceScannerOverlayPainter extends CustomPainter {
  final double scanProgress;
  final bool isGpsValid;

  FaceScannerOverlayPainter({
    required this.scanProgress,
    required this.isGpsValid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ovalWidth = size.width * 0.72;
    final ovalHeight = size.height * 0.44;
    final center = Offset(size.width / 2, size.height * 0.40);
    final rect = Rect.fromCenter(center: center, width: ovalWidth, height: ovalHeight);

    // 1. Semi-transparent dark background mask
    final bgPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final ovalPath = Path()..addOval(rect);
    final maskPath = Path.combine(PathOperation.difference, bgPath, ovalPath);

    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..style = PaintingStyle.fill;
    canvas.drawPath(maskPath, bgPaint);

    // 2. Oval outline border
    final borderPaint = Paint()
      ..color = isGpsValid ? const Color(0xFF38BDF8) : const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawOval(rect, borderPaint);

    // 3. Glowing scan line
    if (isGpsValid) {
      final lineY = rect.top + (rect.height * scanProgress);
      final scanLinePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF38BDF8).withOpacity(0.8),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(rect.left, lineY, rect.width, 2))
        ..strokeWidth = 2.5;

      canvas.drawLine(
        Offset(rect.left + 20, lineY),
        Offset(rect.right - 20, lineY),
        scanLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FaceScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress || oldDelegate.isGpsValid != isGpsValid;
  }
}

