import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/dashboard_full_model.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/location_service.dart';
import '../dialogs/classmate_detail_dialog.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../widgets/jadwal_pelajaran_widget.dart';
import '../../../core/services/notification_service.dart';
import '../dialogs/notification_sheet.dart';
import '../../../core/theme/app_theme.dart';

//  BERANDA TAB
//  Hero, action hub, and service badges
//  Card carousel with status badges

class BerandaTab extends StatefulWidget {
  final DashboardFullModel data;
  final GeofenceResult? geofenceResult;
  final String currentTimeWIB;
  final VoidCallback onOpenScanner;
  final VoidCallback? onOpenEnrollment;
  final VoidCallback onOpenRekap;
  final VoidCallback onOpenKehadiran;
  final VoidCallback onOpenTeman;
  final VoidCallback? onOpenPanduan;
  final VoidCallback? onRefreshLocation;
  final ValueChanged<UserModel> onProfileUpdated;

  const BerandaTab({
    super.key,
    required this.data,
    required this.geofenceResult,
    required this.currentTimeWIB,
    required this.onOpenScanner,
    this.onOpenEnrollment,
    required this.onOpenRekap,
    required this.onOpenKehadiran,
    required this.onOpenTeman,
    this.onOpenPanduan,
    this.onRefreshLocation,
    required this.onProfileUpdated,
  });

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab>
    with TickerProviderStateMixin {
  late AnimationController _jumpController;
  late Animation<double> _jumpAnimation;
  late Animation<double> _shadowScaleAnimation;
  late Animation<double> _shadowOpacityAnimation;

  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    // Animasi lompat-lompat berulang (bouncing pin jump)
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    // Perpindahan vertikal (naik 24px lalu turun kembali secara ritmis)
    _jumpAnimation = Tween<double>(begin: 0.0, end: -24.0).animate(
      CurvedAnimation(
        parent: _jumpController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    // Bayangan di tanah mengecil saat pin terangkat ke udara
    _shadowScaleAnimation = Tween<double>(begin: 1.0, end: 0.35).animate(
      CurvedAnimation(
        parent: _jumpController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    // Bayangan di tanah memudar saat pin semakin tinggi
    _shadowOpacityAnimation = Tween<double>(begin: 0.45, end: 0.08).animate(
      CurvedAnimation(
        parent: _jumpController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    // Animasi gelombang radar pulsa continuous
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _jumpController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _openEditProfile() {
    HapticFeedback.lightImpact();
    EditProfileDialog.show(
      context,
      user: widget.data.user,
      onProfileUpdated: widget.onProfileUpdated,
    );
  }

  String _formatAvatarUrl(String? path) => ApiConstants.resolveStorageUrl(path);

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'SW';
  }

  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.data.user;
    final hasSesi = widget.data.hasSesi;
    final sudahHadir = widget.data.sudahHadir;
    final sesi = widget.data.sesi;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //  1. COMPACT GREETING HEADER
          _buildCompactGreetingHeader(user)
              .animate()
              .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 14),

          //  2. KARTU UTAMA PRESENSI & WIDGET PETA
          _buildPresensiCard(user, sesi, hasSesi, sudahHadir)
              .animate()
              .fadeIn(duration: 400.ms, delay: 50.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 50.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 14),

          //  3. 4-COLUMN QUICK ACTION BAR
          _buildQuickActionBar()
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms, curve: Curves.easeOutCubic),

          //  4. TEMAN SEKELAS HARI INI (HORIZONTAL STORY ROW)
          if (widget.data.temanSekelas.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildTemanSekelasStoryRow(user)
                .animate()
                .fadeIn(duration: 400.ms, delay: 120.ms, curve: Curves.easeOutCubic)
                .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 120.ms, curve: Curves.easeOutCubic),
          ],

          const SizedBox(height: 16),

          //  5. JADWAL PELAJARAN HARI INI
          JadwalPelajaranWidget(
            activeSession: sesi,
            namaKelas: user.kelas,
            sudahHadir: sudahHadir,
            jadwal: widget.data.jadwal,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 140.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 140.ms, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  //  1. COMPACT GREETING HEADER

  Widget _buildCompactGreetingHeader(UserModel user) {
    final avatarUrl = _formatAvatarUrl(user.avatar);
    final namaClean = _toTitleCase(user.nama);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color:  AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color:  AppColors.shadow.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Kiri: Avatar bulat dengan status ring (Tap to edit)
          GestureDetector(
            onTap: _openEditProfile,
            behavior: HitTestBehavior.opaque,
            child: Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:  AppColors.background,
                  border: Border.all(color:  AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              _getInitials(user.nama),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color:  AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _getInitials(user.nama),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color:  AppColors.primaryBlue,
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: user.isFaceEnrolled
                        ?  AppColors.success
                        :  AppColors.warning,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),

          const SizedBox(width: 12),

          // Tengah: Nama & Kelas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Halo, $namaClean ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color:  AppColors.primaryDark,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      user.kelas,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color:  AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 4,
                      height: 4,
                      decoration:  BoxDecoration(
                        color: AppColors.textQuaternary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: user.isFaceEnrolled
                            ?  AppColors.success
                            :  AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.isFaceEnrolled ? 'Face ID Aktif' : 'Belum Rekam',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: user.isFaceEnrolled
                            ?  AppColors.success
                            :  AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Kanan: Logo Sekolah Ringkas
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:  AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color:  AppColors.border),
            ),
            child: Image.asset(
              'assets/images/logo.webp',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>  Icon(
                Icons.school_rounded,
                size: 20,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // C14. Tombol notifikasi (kotak masuk).
          _NotificationBell(
            onTap: () {
              HapticFeedback.lightImpact();
              NotificationSheet.show(context);
            },
          ),
        ],
      ),
    );
  }

  //  2. KARTU UTAMA PRESENSI & WIDGET PETA

  Widget _buildPresensiCard(
    UserModel user,
    SessionDetail? sesi,
    bool hasSesi,
    bool sudahHadir,
  ) {
    final now = DateTime.now();
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final tglStr = '${hari[now.weekday - 1]}, ${now.day} ${bulan[now.month - 1]} ${now.year}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color:  AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color:  AppColors.shadow.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Sesi Presensi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: hasSesi
                          ? (sudahHadir
                              ?  AppColors.successBg
                              :  AppColors.infoBg)
                          :  AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasSesi
                            ? (sudahHadir
                                ?  AppColors.successBorder
                                :  AppColors.infoBorder)
                            :  AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: hasSesi
                                ? (sudahHadir
                                    ?  AppColors.success
                                    :  AppColors.primaryBlue)
                                :  AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hasSesi
                              ? (sudahHadir
                                  ? 'Sesi Sedang Berlangsung'
                                  : 'Sesi Presensi Aktif')
                              : 'Tidak Ada Sesi Aktif',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: hasSesi
                                ? (sudahHadir
                                    ?  AppColors.success
                                    :  AppColors.primaryBlue)
                                :  AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.kelas,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color:  AppColors.primaryDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    tglStr,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:  AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              // C15. Jam WIB realtime + hitung mundur sesi.
              _SessionClock(
                nowLabel: widget.currentTimeWIB,
                jamSelesai: sesi?.jamSelesai,
                hasSesi: hasSesi,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Widget Peta Presensi Interaktif dengan Animasi Radar Pulse
          _buildMapWidget(),

          const SizedBox(height: 14),

          // Tombol Aksi Utama Presensi
          if (!hasSesi) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color:  AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color:  AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color:  AppColors.infoBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color:  AppColors.infoBorder),
                    ),
                    child:  Icon(
                      CupertinoIcons.time,
                      size: 26,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum Ada Sesi Aktif',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color:  AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Menunggu guru pengampu membuka sesi presensi kelas hari ini.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.4,
                      color:  AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (sudahHadir) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color:  AppColors.successBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color:  AppColors.successBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sudah Presensi Hari Ini ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color:  AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!user.isFaceEnrolled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:  AppColors.warningBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color:  AppColors.warningBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:  AppColors.warningBorder,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:  Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      color: AppColors.warning,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wajib Rekam Wajah Terlebih Dahulu',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color:  AppColors.amberDeep,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Biometrik wajah belum terdaftar. Rekam wajah sekali untuk mulai presensi.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color:  AppColors.amberDeep,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: widget.onOpenEnrollment ?? widget.onOpenScanner,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color:  AppColors.warning,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:  AppColors.warning.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.camera_fill,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rekam Wajah Sekarang →',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: widget.onOpenScanner,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color:  AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:  AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.camera_fill,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Buka Kamera & Scan Wajah',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  //  2B. WIDGET PETA DENGAN ANIMASI PULSING RADAR

  Widget _buildMapWidget() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 148,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Visual Peta Kampus
            Image.asset(
              'assets/images/map_campus_v2.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/map_campus.png',
                fit: BoxFit.cover,
              ),
            ),

            // Pin Marker Sekolah di Tengah Peta dengan Animasi Lompat-Lompat & Radar Pulse
            Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Dual Radar Ripple Waves (Mekar Melebar Halus 60fps)
                    AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, _) {
                        final p1 = _rippleController.value;
                        final p2 = (_rippleController.value + 0.5) % 1.0;

                        final scale1 = 0.6 + (p1 * 2.0); // 0.6 to 2.6
                        final opacity1 = (1.0 - p1).clamp(0.0, 1.0) * 0.45;

                        final scale2 = 0.6 + (p2 * 2.0); // 0.6 to 2.6
                        final opacity2 = (1.0 - p2).clamp(0.0, 1.0) * 0.35;

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: scale1,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:  AppColors.primaryBlue.withOpacity(opacity1 * 0.35),
                                  border: Border.all(
                                    color:  AppColors.primaryBlue.withOpacity(opacity1),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: scale2,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:  AppColors.primaryBlue.withOpacity(opacity2 * 0.35),
                                  border: Border.all(
                                    color:  AppColors.primaryBlue.withOpacity(opacity2),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // 2. Bayangan Kontak di Tanah (Mengecil & Memudar saat Pin Melompat)
                    AnimatedBuilder(
                      animation: _jumpController,
                      builder: (context, _) {
                        return Transform.translate(
                          offset: const Offset(0, 18),
                          child: Transform.scale(
                            scaleX: _shadowScaleAnimation.value,
                            scaleY: _shadowScaleAnimation.value * 0.65,
                            child: Container(
                              width: 26,
                              height: 9,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(_shadowOpacityAnimation.value),
                                borderRadius: const BorderRadius.all(Radius.elliptical(26, 9)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(_shadowOpacityAnimation.value),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // 3. Pin Sekolah yang Lompat-Lompat Naik Turun (Bouncing Pin Icon)
                    AnimatedBuilder(
                      animation: _jumpController,
                      builder: (context, _) {
                        return Transform.translate(
                          offset: Offset(0, _jumpAnimation.value),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  gradient:  LinearGradient(
                                    colors: [AppColors.primaryBlue,  AppColors.primaryBlue],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color:  AppColors.primaryBlue.withOpacity(0.55),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  size: 17,
                                  color: Colors.white,
                                ),
                              ),
                              CustomPaint(
                                size: const Size(8, 4),
                                painter: _PinArrowPainter(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Floating Badge Atas-Tengah: Status Geofence Valid / Warning
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: _buildMapStatusBadge(),
              ),
            ),

            // Floating Badge Kiri-Bawah: Info Radius Sekolah
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.shield_fill,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'SMKN 1 Beringin • Radius 110m',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating Button Kanan-Bawah: Refresh Lokasi GPS
            if (widget.onRefreshLocation != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onRefreshLocation!();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child:  Icon(
                      CupertinoIcons.location_fill,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapStatusBadge() {
    final geo = widget.geofenceResult;

    if (geo == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color:  AppColors.infoBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Mengunci Titik GPS...',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color:  AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      );
    }

    if (geo.isMocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color:  AppColors.dangerBg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(
              CupertinoIcons.clear_circled_solid,
              size: 11,
              color: AppColors.danger,
            ),
            const SizedBox(width: 5),
            Text(
              'Fake GPS Terdeteksi',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color:  AppColors.danger,
              ),
            ),
          ],
        ),
      );
    }

    if (geo.errorMessage != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color:  AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(
              CupertinoIcons.location,
              size: 11,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              'GPS Belum Akurat',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color:  AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (geo.isInside) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color:  AppColors.successBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(
              CupertinoIcons.checkmark_alt_circle_fill,
              size: 11,
              color: AppColors.success,
            ),
            const SizedBox(width: 5),
            Text(
              'Area Valid • ${geo.distanceMeters.toStringAsFixed(0)}m',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color:  AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color:  AppColors.warningBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
           Icon(
            CupertinoIcons.location_solid,
            size: 11,
            color: AppColors.warning,
          ),
          const SizedBox(width: 5),
          Text(
            'Di Luar Area • ${geo.distanceMeters.toStringAsFixed(0)}m',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color:  AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  //  3. 4-COLUMN QUICK ACTION BAR (Sesuai Desain Asli)

  Widget _buildQuickActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color:  AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color:  AppColors.shadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickActionItem(
            icon: CupertinoIcons.calendar_today,
            label: 'Kehadiran',
            bgColor:  AppColors.infoBg, // soft blue-50
            iconColor:  AppColors.primaryBlue, // blue-600
            onTap: widget.onOpenKehadiran,
          ),
          _buildQuickActionItem(
            icon: CupertinoIcons.person_2_fill,
            label: 'Teman',
            bgColor:  AppColors.indigoBg, // soft indigo-50
            iconColor:  AppColors.primaryIndigo, // indigo-600
            onTap: widget.onOpenTeman,
          ),
          _buildQuickActionItem(
            icon: CupertinoIcons.location_solid,
            label: 'Cek Lokasi',
            bgColor:  AppColors.successBg, // soft emerald-50
            iconColor:  AppColors.success, // emerald-600
            onTap: () {
              if (widget.onRefreshLocation != null) {
                widget.onRefreshLocation!();
              }
            },
          ),
          _buildQuickActionItem(
            icon: CupertinoIcons.book_fill,
            label: 'Panduan',
            bgColor:  AppColors.warningBg, // soft amber-50
            iconColor:  AppColors.warning, // amber-600
            onTap: () {
              if (widget.onOpenPanduan != null) {
                widget.onOpenPanduan!();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 21, color: iconColor),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color:  AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  //  4. TEMAN SEKELAS HARI INI (HORIZONTAL STORY ROW)

  Widget _buildTemanSekelasStoryRow(UserModel user) {
    final list = widget.data.temanSekelas;
    if (list.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color:  AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Teman Sekelas (N)" + "Lihat Semua ->"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color:  AppColors.infoBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:  Icon(
                        CupertinoIcons.person_2_fill,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    RichText(
                      text: TextSpan(
                        text: 'Teman Sekelas ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color:  AppColors.primaryDark,
                        ),
                        children: [
                          TextSpan(
                            text: '(${list.length})',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color:  AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onOpenTeman();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Semua',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color:  AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 2),
                       Icon(
                        CupertinoIcons.chevron_right,
                        size: 11,
                        color: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Horizontal Story Row
          SizedBox(
            height: 90,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: list.length + 1, // +1 for "Profilku"
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Profilku story circle
                  return GestureDetector(
                    onTap: _openEditProfile,
                    child: SizedBox(
                      width: 68,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:  AppColors.infoBg,
                              border: Border.all(
                                color:  AppColors.primaryBlue,
                                width: 1.5,
                              ),
                            ),
                            child:  Center(
                              child: Icon(
                                CupertinoIcons.add,
                                color: AppColors.primaryBlue,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Profilku',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color:  AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final friend = list[index - 1];
                final isHadir = friend.statusHariIni.toLowerCase() == 'hadir';
                final isIzin = friend.statusHariIni.toLowerCase() == 'izin';
                final isSakit = friend.statusHariIni.toLowerCase() == 'sakit';
                final avatarUrl = _formatAvatarUrl(friend.avatar);
                final shortName = friend.nama.trim().split(' ').first;

                Color ringColor;
                Color dotColor;
                if (isHadir) {
                  ringColor =  AppColors.success;
                  dotColor =  AppColors.success;
                } else if (isIzin) {
                  ringColor =  AppColors.warning;
                  dotColor =  AppColors.warning;
                } else if (isSakit) {
                  ringColor =  AppColors.info;
                  dotColor =  AppColors.info;
                } else {
                  ringColor =  AppColors.textQuaternary;
                  dotColor =  AppColors.textMuted;
                }

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ClassmateDetailDialog.show(
                      context,
                      classmate: friend,
                      kelasNama: user.kelas,
                    );
                  },
                  child: SizedBox(
                    width: 68,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ringColor,
                                  width: isHadir ? 2.5 : 1.5,
                                ),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: ClipOval(
                                child: avatarUrl.isNotEmpty
                                    ? Image.network(
                                        avatarUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _buildFriendFallback(friend.nama),
                                      )
                                    : _buildFriendFallback(friend.nama),
                              ),
                            ),
                            Positioned(
                              bottom: 1,
                              right: 1,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _toTitleCase(shortName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:  AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendFallback(String name) {
    final initials = _getInitials(name);
    return Container(
      color:  AppColors.infoBg,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color:  AppColors.primaryBlue,
        ),
      ),
    );
  }
}

class _PinArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =  AppColors.primaryBlue
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


/// C14. Lonceng notifikasi dengan titik indikator.
class _NotificationBell extends StatefulWidget {
  final VoidCallback onTap;
  const _NotificationBell({required this.onTap});

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final n = await NotificationService.unreadCount();
    if (mounted) setState(() => _unread = n);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        widget.onTap();
        await Future.delayed(const Duration(milliseconds: 2500));
        _check();
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child:  Icon(
              CupertinoIcons.bell_fill,
              size: 18,
              color: AppColors.primaryBlue,
            ),
          ),
          if (_unread > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: const BorderRadius.all(Radius.circular(9)),
                ),
                child: Text(
                  _unread > 9 ? '9+' : '$_unread',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


/// C15. Jam WIB realtime + hitung mundur ke penutupan sesi.
class _SessionClock extends StatelessWidget {
  final String nowLabel;
  final String? jamSelesai;
  final bool hasSesi;

  const _SessionClock({
    required this.nowLabel,
    this.jamSelesai,
    required this.hasSesi,
  });

  /// Menit tersisa sampai jam selesai (HH:mm). Null bila tak valid / sudah lewat.
  int? _minutesLeft() {
    final js = jamSelesai;
    if (js == null || js.isEmpty) return null;
    final parts = js.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final now = DateTime.now().toUtc().add(const Duration(hours: 7)); // WIB
    final end = DateTime(now.year, now.month, now.day, h, m);
    final diff = end.difference(now).inMinutes;
    return diff >= 0 ? diff : null;
  }

  @override
  Widget build(BuildContext context) {
    final left = hasSesi ? _minutesLeft() : null;
    final closingSoon = left != null && left <= 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          nowLabel.isEmpty ? '--:--:--' : nowLabel,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
        if (left != null) ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: closingSoon ? AppColors.dangerBg : AppColors.warningBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              left <= 0 ? 'Sesi ditutup' : 'Tutup dalam $left mnt',
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: closingSoon ? AppColors.danger : AppColors.warning,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
