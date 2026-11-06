import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/user_model.dart';
import '../../core/models/session_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/location_service.dart';
import '../scanner/scanner_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  UserModel? _user;
  ActiveSessionResponse? _sessionResp;
  GeofenceResult? _geofenceResult;

  bool _isLoading = true;
  bool _isCheckingGps = false;
  Timer? _gpsTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    // 1. Load user profile
    final userRes = await ApiService.getProfile();
    if (userRes.success && userRes.data != null) {
      _user = userRes.data;
    } else {
      _user = StorageService.getUser();
    }

    // 2. Load active session
    await _refreshSession();

    setState(() => _isLoading = false);

    // 3. Periodic GPS geofence check every 15 seconds
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _sessionResp?.geofencing != null) {
        _checkGeofence();
      }
    });
  }

  Future<void> _refreshSession() async {
    final sessRes = await ApiService.getActiveSession();
    if (sessRes.success && sessRes.data != null) {
      _sessionResp = sessRes.data;
      if (_sessionResp!.geofencing != null) {
        await _checkGeofence();
      }
    }
  }

  Future<void> _checkGeofence() async {
    if (_sessionResp?.geofencing == null) return;
    setState(() => _isCheckingGps = true);
    final result = await LocationService.verifyGeofence(_sessionResp!.geofencing!);
    if (mounted) {
      setState(() {
        _geofenceResult = result;
        _isCheckingGps = false;
      });
    }
  }

  void _openScanner() async {
    if (_sessionResp?.geofencing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfigurasi geofencing sekolah belum siap.')),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ScannerScreen(
          geofenceConfig: _sessionResp!.geofencing!,
          sessionDetail: _sessionResp!.sesi,
        ),
      ),
    );

    if (result == true) {
      // Refresh session after successful attendance scan
      await _loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 1) {
      return HistoryScreen(onBack: () => setState(() => _currentIndex = 0));
    }
    if (_currentIndex == 2) {
      return ProfileScreen(
        user: _user,
        onBack: () => setState(() => _currentIndex = 0),
        onLogout: () async {
          await StorageService.clear();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 20,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                color: AppColors.surfaceMuted,
              ),
              clipBehavior: Clip.antiAlias,
              child: _user?.avatar != null && _user!.avatar!.isNotEmpty
                  ? Image.network(
                      'https://presensi.smknegeri1beringin.sch.id/storage/${_user!.avatar}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        color: AppColors.primaryBlue,
                        size: 22,
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryBlue,
                      size: 22,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _user?.name ?? 'Siswa SMKN 1 Beringin',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  Text(
                    '${_user?.kelasNama ?? "Kelas Siswa"} • NISN ${_user?.nisn ?? "-"}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: _loadInitialData,
            tooltip: 'Perbarui Data',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              color: AppColors.primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Live Geofencing Status Radar Pill
                    _buildGeofenceCard(),
                    const SizedBox(height: 16),

                    // 2. Active Session Card
                    _buildSessionCard(),
                    const SizedBox(height: 20),

                    // 3. Main Action: Biometric Scan Button
                    _buildScanActionButton(),
                    const SizedBox(height: 24),

                    // 4. Today's Attendance Detail Card
                    _buildTodayStatusCard(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          elevation: 0,
          onTap: (idx) => setState(() => _currentIndex = idx),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeofenceCard() {
    final isInside = _geofenceResult?.isInside ?? false;
    final isMocked = _geofenceResult?.isMocked ?? false;
    final dist = _geofenceResult?.distanceMeters ?? 0.0;

    Color bg;
    Color border;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;

    if (_isCheckingGps) {
      bg = AppColors.background;
      border = AppColors.border;
      textColor = AppColors.textSecondary;
      icon = Icons.gps_not_fixed_rounded;
      title = 'Memeriksa Satelit GPS...';
      subtitle = 'Menghubungkan ke sensor lokasi perangkat';
    } else if (isMocked) {
      bg = AppColors.dangerBg;
      border = AppColors.dangerBorder;
      textColor = AppColors.danger;
      icon = Icons.warning_amber_rounded;
      title = 'Lokasi Palsu / Fake GPS Terdeteksi';
      subtitle = 'Nonaktifkan aplikasi mock location di Pengaturan Android';
    } else if (isInside) {
      bg = AppColors.successBg;
      border = AppColors.successBorder;
      textColor = AppColors.success;
      icon = Icons.check_circle_rounded;
      title = 'Di Dalam Radius Sekolah';
      subtitle = 'Area SMK Negeri 1 Beringin • Sinyal GPS Terkunci';
    } else {
      bg = AppColors.warningBg;
      border = AppColors.warningBorder;
      textColor = AppColors.warning;
      icon = Icons.location_off_rounded;
      title = 'Di Luar Area Presensi';
      subtitle = dist < 5000
          ? 'Jarak ke sekolah: ${dist.toStringAsFixed(0)}m • Presensi ditolak di luar radius'
          : 'Anda berada jauh dari sekolah • Presensi hanya berlaku di lingkungan sekolah';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.my_location_rounded, size: 18, color: AppColors.textSecondary),
            onPressed: _checkGeofence,
            tooltip: 'Kalibrasi GPS',
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard() {
    final sess = _sessionResp?.sesi;
    final hasSesi = _sessionResp?.hasSesi ?? false;

    if (!hasSesi || sess == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.event_busy_rounded, color: AppColors.textMuted, size: 36),
            const SizedBox(height: 10),
            Text(
              'Tidak Ada Sesi Presensi Aktif',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Belum ada guru mata pelajaran atau walikelas yang membuka sesi presensi untuk kelas Anda saat ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SESI AKTIF HARI INI',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(DateTime.now()),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            sess.jamPelajaran,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_pin_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Guru Pengajar: ${sess.guruNama}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanActionButton() {
    final sudahHadir = _sessionResp?.sudahHadir ?? false;
    final hasSesi = _sessionResp?.hasSesi ?? false;
    final info = _sessionResp?.presensiInfo;

    if (sudahHadir) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.successBorder, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              'Presensi Berhasil Dicatat!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tercatat masuk pada ${info?.waktuScan ?? "-"} WIB'
              '${(info?.lateMinutes ?? 0) > 0 ? " (Terlambat ${info!.lateMinutes} menit)" : " (Tepat Waktu)"}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (!hasSesi) ? null : _openScanner,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_rounded, size: 24),
            const SizedBox(width: 12),
            Text(
              hasSesi ? 'Pindai Wajah Sekarang' : 'Sesi Belum Tersedia',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard() {
    final info = _sessionResp?.presensiInfo;
    final sudahHadir = _sessionResp?.sudahHadir ?? false;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Kehadiran Anda',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Status Hari Ini',
                  value: sudahHadir ? 'Hadir' : 'Belum Presensi',
                  valueColor: sudahHadir ? AppColors.success : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Jam Rekam',
                  value: info?.waktuScan ?? '--:--',
                  valueColor: AppColors.textMain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Keterlambatan',
                  value: (info?.lateMinutes ?? 0) > 0 ? '${info!.lateMinutes} mnt' : '0 mnt',
                  valueColor: (info?.lateMinutes ?? 0) > 0 ? AppColors.warning : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
