import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/dashboard_full_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/location_service.dart';
import '../scanner/scanner_screen.dart';
import '../auth/login_screen.dart';
import 'tabs/beranda_tab.dart';
import 'tabs/kehadiran_tab.dart';
import 'tabs/teman_tab.dart';
import 'tabs/profil_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  DashboardFullModel? _data;
  GeofenceResult? _geofenceResult;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.getDashboardFull();

    if (!mounted) return;

    if (res.success && res.data != null) {
      _data = res.data;

      // Check geofence
      if (_data!.geofencing != null) {
        LocationService.verifyGeofence(_data!.geofencing!).then((geoRes) {
          if (mounted) {
            setState(() => _geofenceResult = geoRes);
          }
        });
      }

      setState(() => _isLoading = false);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res.message;
      });
    }
  }

  void _openScanner() {
    if (_data == null || _data!.geofencing == null) {
      _showAppleToast('Konfigurasi presensi belum siap.');
      return;
    }

    Navigator.of(context)
        .push(
          CupertinoPageRoute(
            builder: (_) => ScannerScreen(
              geofenceConfig: _data!.geofencing!,
              sessionDetail: _data!.sesi,
            ),
          ),
        )
        .then((_) => _loadInitialData());
  }

  void _showAppleToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF1C1C1E),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Future<void> _handleLogout() async {
    await StorageService.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _confirmLogoutDialog() {
    HapticFeedback.mediumImpact();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          'Keluar dari Akun?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Anda harus masuk kembali menggunakan NISN untuk melakukan presensi.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _handleLogout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _getFirstName() {
    if (_data == null) return 'Siswa';
    final parts = _data!.user.nama.trim().split(' ');
    if (parts.isEmpty) return 'Siswa';
    final name = parts[0];
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const days = [
      'SENIN',
      'SELASA',
      'RABU',
      'KAMIS',
      'JUMAT',
      'SABTU',
      'MINGGU'
    ];
    const months = [
      'JANUARI',
      'FEBRUARI',
      'MARET',
      'APRIL',
      'MEI',
      'JUNI',
      'JULI',
      'AGUSTUS',
      'SEPTEMBER',
      'OKTOBER',
      'NOVEMBER',
      'DESEMBER'
    ];
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName';
  }

  Widget _buildTab() {
    if (_data == null) return const SizedBox.shrink();

    switch (_currentIndex) {
      case 0:
        return BerandaTab(
          key: const ValueKey('beranda'),
          data: _data!,
          geofenceResult: _geofenceResult,
          onOpenScanner: _openScanner,
          onOpenKehadiran: () => setState(() => _currentIndex = 1),
          onOpenTeman: () => setState(() => _currentIndex = 2),
          onProfileUpdated: (updatedUser) => _loadInitialData(),
        );
      case 1:
        return KehadiranTab(key: const ValueKey('kehadiran'), data: _data!);
      case 2:
        return TemanTab(key: const ValueKey('teman'), data: _data!);
      case 3:
        return ProfilTab(
          key: const ValueKey('profil'),
          data: _data!,
          onLogout: _confirmLogoutDialog,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS Grouped Background
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Stack(
            children: [
              // Main Tab View
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // ── iOS Native Header ──
                      _buildIOSHeader(),

                      // ── Tab Body with Smooth Transition ──
                      Expanded(
                        child: _isLoading
                            ? _buildSkeletonLoading()
                            : _errorMessage != null
                                ? _buildErrorState()
                                : RefreshIndicator(
                                    onRefresh: _loadInitialData,
                                    color: AppColors.primaryBlue,
                                    edgeOffset: 10,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                      child: _buildTab(),
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Apple Floating Frosted Glass Dock ──
              Positioned(
                left: 18,
                right: 18,
                bottom: 24,
                child: _buildFloatingDock(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  iOS NATIVE TOP BAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildIOSHeader() {
    final bool inRadius = _geofenceResult?.isInsideRadius ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F7),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Greeting & Date (Apple Large Title Subtitle)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getFormattedDate(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8E8E93),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_getGreeting()}, ${_getFirstName()} 👋',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── GPS Geofence Status Pill ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: inRadius
                  ? const Color(0xFF34C759).withOpacity(0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: inRadius
                    ? const Color(0xFF34C759).withOpacity(0.3)
                    : const Color(0xFFE5E5EA),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: inRadius
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF9500),
                    shape: BoxShape.circle,
                    boxShadow: inRadius
                        ? [
                            BoxShadow(
                              color: const Color(0xFF34C759).withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  inRadius ? 'Area Sekolah' : 'Cek Lokasi',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: inRadius
                        ? const Color(0xFF248A3D)
                        : const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Scanner Quick Action Button (Apple Tactile) ──
          GestureDetector(
            onTap: _openScanner,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.viewfinder,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  APPLE FROSTED GLASS DOCK (BOTTOM NAVIGATION)
  // ═══════════════════════════════════════════════════════════

  Widget _buildFloatingDock() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDockItem(0, 'Beranda', CupertinoIcons.house_fill,
                  CupertinoIcons.house),
              _buildDockItem(1, 'Kehadiran', CupertinoIcons.chart_pie_fill,
                  CupertinoIcons.chart_pie),
              _buildDockItem(2, 'Teman', CupertinoIcons.person_2_fill,
                  CupertinoIcons.person_2),
              _buildDockItem(3, 'Profil',
                  CupertinoIcons.person_crop_circle_fill,
                  CupertinoIcons.person_crop_circle),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .slideY(
          begin: 0.25,
          end: 0,
          duration: 500.ms,
          delay: 200.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildDockItem(
    int index,
    String label,
    IconData activeIcon,
    IconData inactiveIcon,
  ) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: isActive
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 9)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF007AFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              size: 20,
              color: isActive ? Colors.white : const Color(0xFF8E8E93),
            ),
            if (isActive) ...[
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SKELETON & ERROR STATES
  // ═══════════════════════════════════════════════════════════

  Widget _buildSkeletonLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: const Color(0xFFF2F2F7)),
          const SizedBox(height: 16),
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: const Color(0xFFF2F2F7)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                size: 28,
                color: Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan sistem',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF3C3C43),
              ),
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: _loadInitialData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
