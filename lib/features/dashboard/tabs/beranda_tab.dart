import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/dashboard_full_model.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/location_service.dart';
import '../dialogs/classmate_detail_dialog.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../widgets/campus_map_widget.dart';
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
  final ValueListenable<GeofenceResult?>? geofenceListenable;
  final bool isRefreshingLocation;
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
    this.geofenceListenable,
    this.isRefreshingLocation = false,
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

class _BerandaTabState extends State<BerandaTab> {

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        children: [
          // Avatar (Tap to edit profile)
          GestureDetector(
            onTap: _openEditProfile,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.9),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                _getInitials(user.nama),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _getInitials(user.nama),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryBlue,
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
                          ? AppColors.success
                          : AppColors.warning,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Greeting & class subtitle (overflow-safe)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Halo, $namaClean',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                    letterSpacing: -0.35,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.kelas,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '•',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textQuaternary,
                        ),
                      ),
                    ),
                    Text(
                      user.isFaceEnrolled ? 'Face ID Aktif' : 'Belum Rekam',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: user.isFaceEnrolled
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Clean circular iOS Notification button
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
      decoration: AppColors.cardDecoration(radius: 22, elevated: true),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Sesi Presensi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: hasSesi
                            ? (sudahHadir ? AppColors.successBg : AppColors.infoBg)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(100),
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
                                      ? AppColors.success
                                      : AppColors.primaryBlue)
                                  : AppColors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              hasSesi
                                  ? (sudahHadir ? 'Presensi Selesai' : 'Sesi Aktif')
                                  : 'Belum Ada Sesi',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: hasSesi
                                    ? (sudahHadir
                                        ? AppColors.success
                                        : AppColors.primaryBlue)
                                    : AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.kelas,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMain,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tglStr,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Jam WIB realtime + hitung mundur sesi.
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
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(14),
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
                    'Sudah Presensi Hari Ini',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!user.isFaceEnrolled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wajib Rekam Wajah Terlebih Dahulu',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amberDeep,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rekam biometrik wajah sekali untuk mulai presensi.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.amberDeep,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(14),
                onPressed: widget.onOpenEnrollment ?? widget.onOpenScanner,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.viewfinder,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rekam Wajah Sekarang',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 48,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(14),
                onPressed: widget.onOpenScanner,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.viewfinder,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scan Wajah Presensi',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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

  Future<void> _openGoogleMaps() async {
    final geoCfg = widget.data.geofencing;
    final lat = geoCfg?.latitude ?? 3.586138;
    final lng = geoCfg?.longitude ?? 98.881361;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _handleMapBadgeTap() async {
    HapticFeedback.lightImpact();
    final issue = widget.geofenceResult?.issue ?? LocationIssue.none;
    if (issue == LocationIssue.serviceDisabled) {
      await LocationService.openLocationSettings();
      return;
    }
    if (issue == LocationIssue.permissionDeniedForever) {
      await LocationService.openAppSettings();
      return;
    }
    if (widget.onRefreshLocation != null) {
      widget.onRefreshLocation!();
    }
  }

  //  2B. WIDGET PETA INTERAKTIF (FlutterMap + Polygon/Radius + Live GPS + Fullscreen)

  Widget _buildMapWidget() {
    return CampusMapWidget(
      geofencing: widget.data.geofencing,
      geofenceResult: widget.geofenceResult,
      geofenceListenable: widget.geofenceListenable,
      isRefreshingLocation: widget.isRefreshingLocation,
      onRefreshLocation: widget.onRefreshLocation,
      onBadgeTap: _handleMapBadgeTap,
      onOpenGoogleMaps: _openGoogleMaps,
    );
  }

  //  3. 4-COLUMN QUICK ACTION BAR (Zero Izin button, balanced Apple squircles)

  Widget _buildQuickActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: AppColors.cardDecoration(radius: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionItem(
              icon: CupertinoIcons.calendar_today,
              label: 'Kehadiran',
              bgColor: AppColors.primaryBlue.withOpacity(0.11),
              iconColor: AppColors.primaryBlue,
              onTap: widget.onOpenKehadiran,
            ),
          ),
          Expanded(
            child: _buildQuickActionItem(
              icon: CupertinoIcons.person_2_fill,
              label: 'Teman',
              bgColor: AppColors.primaryIndigo.withOpacity(0.11),
              iconColor: AppColors.primaryIndigo,
              onTap: widget.onOpenTeman,
            ),
          ),
          Expanded(
            child: _buildQuickActionItem(
              icon: CupertinoIcons.location_solid,
              label: 'Cek Lokasi',
              bgColor: AppColors.success.withOpacity(0.12),
              iconColor: AppColors.success,
              onTap: () {
                if (widget.onRefreshLocation != null) {
                  widget.onRefreshLocation!();
                }
              },
            ),
          ),
          Expanded(
            child: _buildQuickActionItem(
              icon: CupertinoIcons.book_fill,
              label: 'Panduan',
              bgColor: AppColors.warning.withOpacity(0.12),
              iconColor: AppColors.warning,
              onTap: () {
                if (widget.onOpenPanduan != null) {
                  widget.onOpenPanduan!();
                }
              },
            ),
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
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
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.border.withOpacity(0.8),
                width: 0.8,
              ),
            ),
            child: Icon(
              CupertinoIcons.bell,
              size: 18,
              color: AppColors.textMain,
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
