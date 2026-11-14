import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/dashboard_full_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/scan_queue_service.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../scanner/scanner_screen.dart';
import '../enrollment/enroll_wajah_screen.dart';
import 'dialogs/izin_sakit_dialog.dart';
import 'dialogs/rekap_kehadiran_dialog.dart';
import 'tabs/beranda_tab.dart';
import 'tabs/kehadiran_tab.dart';
import 'tabs/teman_tab.dart';
import 'tabs/profil_tab.dart';

//  DASHBOARD SCREEN — Portal Siswa SMKN 1 Beringin
//  Top navbar and sliding bottom bar

class DashboardScreen extends StatefulWidget {
  final DashboardFullModel? initialData;
  const DashboardScreen({super.key, this.initialData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  DashboardFullModel? _data;
  GeofenceResult? _geofenceResult;

  bool _isLoading = true;
  String? _errorMessage;
  late Timer _clockTimer;
  Timer? _pollTimer;
  bool _isPolling = false;
  int _pendingScans = 0;
  String _currentTimeWIB = '';

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    // Realtime: poll sesi-aktif tiap 5 detik (mirror presensi web).
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollSession());
    if (widget.initialData != null) {
      _data = widget.initialData;
      _isLoading = false;
      if (_data!.geofencing != null) {
        LocationService.verifyGeofence(_data!.geofencing!).then((geoRes) {
          if (mounted) setState(() => _geofenceResult = geoRes);
        });
      }
    } else {
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _refreshPendingScans() async {
    final n = await ScanQueueService.pendingCount();
    if (mounted && n != _pendingScans) setState(() => _pendingScans = n);
  }

  void _updateClock() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7)); // WIB (UTC+7)
    final formatted = DateFormat('HH:mm:ss').format(now);
    if (mounted) {
      setState(() {
        _currentTimeWIB = '$formatted WIB';
      });
      _refreshPendingScans();
    }
  }

  /// Polling ringan `/siswa/sesi-aktif` - update sesi & geofence tanpa reload penuh.
  Future<void> _pollSession() async {
    if (_isPolling || _data == null) return;
    _isPolling = true;
    try {
      final res = await ApiService.getActiveSession();
      if (mounted && res.success && res.data != null) {
        final polled = _data!.applySessionPoll(res.data!);
        setState(() => _data = polled);
        if (polled.geofencing != null) {
          final geoRes = await LocationService.verifyGeofence(polled.geofencing!);
          if (mounted) setState(() => _geofenceResult = geoRes);
        }
      }
    } finally {
      _isPolling = false;
    }
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

  void _openEnrollment() {
    HapticFeedback.lightImpact();
    Navigator.of(context)
        .push(
          CupertinoPageRoute(
            builder: (_) => const EnrollWajahScreen(),
          ),
        )
        .then((_) => _loadInitialData());
  }

  void _openScanner() {
    if (_data == null) {
      _showToast('Data presensi belum siap.');
      return;
    }

    // Deteksi Wajah Belum Terdaftar: langsung arahkan ke Face ID Setup
    if (!_data!.user.isFaceEnrolled) {
      HapticFeedback.heavyImpact();
      _showToast(' Wajah belum terdaftar. Silakan rekam biometrik Face ID terlebih dahulu.');
      _openEnrollment();
      return;
    }

    if (_data!.geofencing == null) {
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

  void _openIzinSakitModal() async {
    if (_data == null) return;
    HapticFeedback.lightImpact();
    final res = await IzinSakitDialog.show(
      context,
      namaSiswa: _data!.user.nama,
      kelasSiswa: _data!.user.kelas,
    );
    if (res == true) {
      _loadInitialData();
    }
  }

  void _openRekapModal() {
    if (_data == null) return;
    HapticFeedback.lightImpact();
    RekapKehadiranDialog.show(context, data: _data!);
  }

  Future<void> _refreshLocation() async {
    if (_data == null || _data!.geofencing == null) return;
    HapticFeedback.mediumImpact();
    _showToast(' Sedang membaca sensor koordinat GPS...');
    final geoRes = await LocationService.verifyGeofence(_data!.geofencing!);
    if (mounted) {
      setState(() => _geofenceResult = geoRes);
      _showToast(geoRes.isInside
          ? ' Lokasi valid: ${geoRes.distanceMeters.toStringAsFixed(0)}m dari sekolah (Aman)'
          : ' Di luar radius: ${geoRes.distanceMeters > 2000 ? '>2km' : '${geoRes.distanceMeters.toStringAsFixed(0)}m'} (Maks 110m)');
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: AppColors.primaryDeep,
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
      backgroundColor:  AppColors.background, // Native Slate-50 Canvas
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
        child: SafeArea(
          top: true,
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
            //  1. Top Navbar Header (Shown on other tabs, hidden on Beranda where Hero Header exists)
            if (_currentIndex != 0) _buildTopBrandHeader(),

            //  2. Tab Content Body
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  BerandaTab(
                    data: _data!,
                    geofenceResult: _geofenceResult,
                    currentTimeWIB: _currentTimeWIB,
                    onOpenScanner: _openScanner,
                    onOpenEnrollment: _openEnrollment,
                    onOpenIzinSakit: _openIzinSakitModal,
                    onOpenRekap: _openRekapModal,
                    onOpenKehadiran: () => setState(() => _currentIndex = 1),
                    onOpenTeman: () => setState(() => _currentIndex = 2),
                    onOpenPanduan: _showPanduanDialog,
                    onRefreshLocation: _refreshLocation,
                    onProfileUpdated: _handleProfileUpdated,
                  ),
                  KehadiranTab(
                    data: _data!,
                    onOpenRekap: _openRekapModal,
                  ),
                  TemanTab(data: _data!),
                  ProfilTab(
                    data: _data!,
                    onOpenEnrollment: _openEnrollment,
                    onProfileUpdated: _handleProfileUpdated,
                    onLogout: _confirmLogout,
                  ),
                ],
              ),
            ),
          ],
        ),

        if (_pendingScans > 0)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildPendingBanner(),
          ),
        //  3. Floating Navigation Bar
        _buildWebSlidingBottomBar(),
      ],
    );
  }

  //  TOP NAVBAR HEADER (Matching Web Portal Photo Exactly)

  Widget _buildPendingBanner() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final sent = await ScanQueueService.syncPending();
        await _refreshPendingScans();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sent > 0
                  ? '$sent presensi offline berhasil dikirim.'
                  : 'Belum bisa terhubung. Akan dicoba lagi otomatis.',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: AppColors.primaryDeep,
            duration: const Duration(seconds: 3),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color:  AppColors.warningBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color:  AppColors.warning.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
             Icon(CupertinoIcons.cloud_upload,
                size: 18, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$_pendingScans presensi menunggu dikirim',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color:  AppColors.amberDeep,
                ),
              ),
            ),
            Text(
              'Kirim',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color:  AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildTopBrandHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration:  BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // School Logo Container
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color:  AppColors.border),
            ),
            child: Image.asset(
              'assets/images/logo.webp',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>  Icon(
                Icons.school_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // School Brand & Portal Siswa
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SMKN 1 BERINGIN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color:  AppColors.primaryDark,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Portal Siswa',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color:  AppColors.primaryBlue,
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 20,
            color:  AppColors.border,
          ),
          const SizedBox(width: 8),

          // Kolaborasi Sumut Berkah Logo
          Image.asset(
            'assets/images/logo-kolaborasi.webp',
            height: 22,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),

          const Spacer(),

          //  Actions Right: hanya logo & brand (panduan/toggle/logout dipindah ke Profil).
        ],
      ),
    )
      .animate()
      .fadeIn(duration: 300.ms)
      .slideY(begin: -0.3, end: 0);
  }

//  Floating navigation bar

  static const List<({String title, IconData activeIcon, IconData inactiveIcon})>
      _navItems = [
    (
      title: 'Beranda',
      activeIcon: CupertinoIcons.house_fill,
      inactiveIcon: CupertinoIcons.house,
    ),
    (
      title: 'Kehadiran',
      activeIcon: CupertinoIcons.calendar_today,
      inactiveIcon: CupertinoIcons.calendar,
    ),
    (
      title: 'Teman',
      activeIcon: CupertinoIcons.person_2_fill,
      inactiveIcon: CupertinoIcons.person_2,
    ),
    (
      title: 'Profil',
      activeIcon: CupertinoIcons.person_fill,
      inactiveIcon: CupertinoIcons.person,
    ),
  ];

  Widget _buildWebSlidingBottomBar() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset > 0 ? bottomInset + 8 : 16),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.96),
              border:  Border(
                top: BorderSide(
                  color: AppColors.border,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = _currentIndex == index;

                return GestureDetector(
                  onTap: () {
                    if (_currentIndex != index) {
                      HapticFeedback.selectionClick();
                      setState(() => _currentIndex = index);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.inactiveIcon,
                          size: 22,
                          color: isSelected
                              ?  AppColors.primaryBlue
                              :  AppColors.textMuted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ?  AppColors.primaryBlue
                                :  AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    final topPadding = MediaQuery.of(context).padding.top;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Hero Header Shimmer
          Container(
            height: 250.0 + topPadding,
            decoration:  BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDeep, AppColors.primaryDeep],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: EdgeInsets.fromLTRB(18, topPadding + 16, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 160,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 110,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Signature Floating Card Shimmer (Session Card with Map Box)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color:  AppColors.shadow.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 110,
                          height: 22,
                          decoration: BoxDecoration(
                            color:  AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 14,
                          decoration: BoxDecoration(
                            color:  AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: 140,
                      height: 24,
                      decoration: BoxDecoration(
                        color:  AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 14,
                      decoration: BoxDecoration(
                        color:  AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Map Placeholder Container
                    Container(
                      height: 145,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:  AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Service Badges Row Shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) => Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration:  BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 44,
                    height: 10,
                    decoration: BoxDecoration(
                      color:  AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              )),
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.55));
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(CupertinoIcons.exclamationmark_triangle_fill,
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
