import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/dashboard_full_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../scanner/scanner_screen.dart';
import 'dialogs/student_id_fullscreen_dialog.dart';
import 'dialogs/izin_sakit_dialog.dart';
import 'dialogs/rekap_kehadiran_dialog.dart';
import 'tabs/beranda_tab.dart';
import 'tabs/kehadiran_tab.dart';
import 'tabs/teman_tab.dart';
import 'tabs/profil_tab.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  DASHBOARD SCREEN — 100% Authentic Apple iOS 18 Design Language
//  Apple Large Title Navigation Header • macOS/iOS Floating Glass Dock
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  int? _hoveredIndex;
  DashboardFullModel? _data;
  GeofenceResult? _geofenceResult;

  bool _isLoading = true;
  String? _errorMessage;
  late Timer _clockTimer;
  String _currentTimeWIB = '';

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateClock());
    _loadInitialData();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7)); // WIB (UTC+7)
    final formatted = DateFormat('HH:mm').format(now);
    if (mounted) {
      setState(() {
        _currentTimeWIB = '$formatted WIB';
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().toUtc().add(const Duration(hours: 7)).hour;
    if (hour >= 5 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _getFormattedDate() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ];
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final dayName = days[now.weekday % 7];
    final monthName = months[now.month];
    return '${dayName.toUpperCase()}, ${now.day} ${monthName.toUpperCase()} ${now.year}';
  }

  String _getFirstName() {
    if (_data == null) return 'Siswa';
    final parts = _data!.user.nama.trim().split(' ');
    if (parts.isEmpty) return 'Siswa';
    final first = parts[0];
    return first[0].toUpperCase() + first.substring(1).toLowerCase();
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
      _showToast('Konfigurasi presensi belum siap.');
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

  void _openStudentCardModal() {
    if (_data == null) return;
    HapticFeedback.lightImpact();
    StudentIdFullscreenDialog.show(context, user: _data!.user);
  }

  void _openIzinSakitModal() {
    if (_data == null) return;
    HapticFeedback.lightImpact();
    IzinSakitDialog.show(
      context,
      namaSiswa: _data!.user.nama,
      kelasSiswa: _data!.user.kelas,
    );
  }

  void _openRekapModal() {
    if (_data == null) return;
    HapticFeedback.lightImpact();
    RekapKehadiranDialog.show(context, data: _data!);
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF1C1C1E),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  void _handleProfileUpdated(UserModel updatedUser) {
    if (_data != null) {
      setState(() {
        _data = _data!.copyWith(user: updatedUser);
      });
    }
  }

  void _showPanduanDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          'Buku Panduan Presensi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Aturan Resmi Presensi SMKN 1 Beringin:\n\n'
            '1. Presensi pagi dimulai pukul 06.30 - 07.30 WIB (Tepat Waktu).\n'
            '2. Setelah pukul 07.30 WIB siswa tercatat TERLAMBAT dan notifikasi otomatis dikirim ke WhatsApp orang tua.\n'
            '3. Wajib berada dalam radius 110 meter area sekolah saat verifikasi wajah biometrik.\n'
            '4. Fake GPS / Mock Location dilarang keras dan otomatis ditolak sistem.',
            textAlign: TextAlign.left,
            style: GoogleFonts.inter(fontSize: 12.5, height: 1.4),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          'Keluar dari Akun',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Presensi Siswa?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await StorageService.clear();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                CupertinoPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Authentic Apple iOS System Canvas
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? _buildSkeletonLoading()
              : _errorMessage != null
                  ? _buildErrorState()
                  : _buildMainContent(),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_data == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Apple Native iOS 18 Large Title Header ──
            _buildIOSHeader(),

            // ── 2. Tab Content Body ──
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  BerandaTab(
                    data: _data!,
                    geofenceResult: _geofenceResult,
                    currentTimeWIB: _currentTimeWIB,
                    onOpenScanner: _openScanner,
                    onOpenStudentCard: _openStudentCardModal,
                    onOpenIzinSakit: _openIzinSakitModal,
                    onOpenRekap: _openRekapModal,
                    onOpenKehadiran: () => setState(() => _currentIndex = 1),
                    onOpenTeman: () => setState(() => _currentIndex = 2),
                    onProfileUpdated: _handleProfileUpdated,
                  ),
                  KehadiranTab(data: _data!),
                  TemanTab(data: _data!),
                  ProfilTab(
                    data: _data!,
                    onProfileUpdated: _handleProfileUpdated,
                    onLogout: _confirmLogout,
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── 3. Apple macOS/iOS Animated Floating Glass Dock ──
        Positioned(
          left: 18,
          right: 18,
          bottom: MediaQuery.of(context).padding.bottom > 0
              ? MediaQuery.of(context).padding.bottom + 12
              : 20,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _buildFloatingDock(),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  APPLE NATIVE iOS 18 LARGE TITLE HEADER
  // ═══════════════════════════════════════════════════════════

  Widget _buildIOSHeader() {
    final bool inRadius = _geofenceResult?.isInsideRadius ?? false;
    final double distance = _geofenceResult?.distanceMeters ?? 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F7),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1: Subtitle Date & Apple Glass Control Buttons ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Date Subtitle
              Expanded(
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.webp',
                      height: 18,
                      errorBuilder: (_, __, ___) => const Icon(
                        CupertinoIcons.building_2_fill,
                        size: 14,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getFormattedDate(),
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8E8E93),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Apple Glass Control: Buku Panduan ──
              GestureDetector(
                onTap: _showPanduanDialog,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.book_fill, size: 12, color: Color(0xFF007AFF)),
                      const SizedBox(width: 4),
                      Text(
                        'Panduan',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF007AFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ── Apple Glass Control: Logout ──
              GestureDetector(
                onTap: _confirmLogout,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.square_arrow_right,
                      size: 13,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Row 2: Apple Large Title & GPS Geofence Pill ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${_getGreeting()}, ${_getFirstName()} 👋',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF000000),
                    letterSpacing: -0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // ── GPS Geofence Status Pill ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: inRadius
                      ? const Color(0xFF34C759).withOpacity(0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: inRadius
                        ? const Color(0xFF34C759).withOpacity(0.3)
                        : const Color(0xFFE5E5EA),
                    width: 0.8,
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
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      inRadius
                          ? 'Radius Valid (${distance.toStringAsFixed(0)}m)'
                          : 'Cek Lokasi GPS',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: inRadius
                            ? const Color(0xFF34C759)
                            : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  APPLE macOS/iOS ANIMATED FLOATING GLASS DOCK
  // ═══════════════════════════════════════════════════════════

  static const List<({String title, IconData activeIcon, IconData inactiveIcon})>
      _dockNavItems = [
    (
      title: 'Beranda',
      activeIcon: CupertinoIcons.house_fill,
      inactiveIcon: CupertinoIcons.house,
    ),
    (
      title: 'Kehadiran',
      activeIcon: CupertinoIcons.chart_pie_fill,
      inactiveIcon: CupertinoIcons.chart_pie,
    ),
    (
      title: 'Teman',
      activeIcon: CupertinoIcons.person_2_fill,
      inactiveIcon: CupertinoIcons.person_2,
    ),
    (
      title: 'Profil',
      activeIcon: CupertinoIcons.person_crop_circle_fill,
      inactiveIcon: CupertinoIcons.person_crop_circle,
    ),
  ];

  Widget _buildFloatingDock() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.90),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.85),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              const hPadding = 6.0;
              const vPadding = 6.0;
              final availableWidth = totalWidth - (hPadding * 2);
              final itemWidth = availableWidth / _dockNavItems.length;
              final itemHeight = constraints.maxHeight - (vPadding * 2);
              final pillLeft = hPadding + (_currentIndex * itemWidth);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── 1. APPLE-STYLE SLIDING ACTIVE BOX (Spring Physics) ──
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    left: pillLeft + 3.0,
                    top: vPadding + 2.0,
                    width: itemWidth - 6.0,
                    height: itemHeight - 4.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE5E5EA),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── 2. APPLE-STYLE SLIDING ACTIVE DOT (macOS Dock Style) ──
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    left: pillLeft + (itemWidth / 2) - 2.5,
                    bottom: vPadding + 3.0,
                    width: 5,
                    height: 5,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF007AFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // ── 3. DOCK ITEMS (Magnification & Tooltips) ──
                  Row(
                    children: List.generate(_dockNavItems.length, (index) {
                      final item = _dockNavItems[index];
                      return SizedBox(
                        width: itemWidth,
                        height: constraints.maxHeight,
                        child: _buildDockItem(index, item),
                      );
                    }),
                  ),
                ],
              );
            },
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
    ({String title, IconData activeIcon, IconData inactiveIcon}) item,
  ) {
    final isActive = _currentIndex == index;
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (_currentIndex != index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Floating Tooltip on Hover (macOS Dock Style)
            if (isHovered)
              Positioned(
                top: -36,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C1C1E),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),

            // Scaling Icon & Label (macOS Hover Magnification)
            AnimatedScale(
              scale: isHovered ? 1.15 : (isActive ? 1.05 : 1.0),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? item.activeIcon : item.inactiveIcon,
                    size: isActive ? 22 : 21,
                    color: isActive ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 5), // Space for sliding active dot
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return const Center(
      child: CupertinoActivityIndicator(color: AppColors.primaryBlue, radius: 14),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle_fill,
                color: AppColors.warning, size: 48),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Data',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Terjadi kesalahan sistem.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadInitialData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
