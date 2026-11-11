import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/models/dashboard_full_model.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/location_service.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../widgets/jadwal_pelajaran_widget.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  BERANDA TAB — World-Class Mobile UX (Inspired by Wanderly Reference)
//  Immersive Scenery Hero • Floating Action Hub • 4 Circular Service Badges
//  Card Carousel with Star Status • Zero AI-Slop • Pure Craft
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class BerandaTab extends StatefulWidget {
  final DashboardFullModel data;
  final GeofenceResult? geofenceResult;
  final String currentTimeWIB;
  final VoidCallback onOpenScanner;
  final VoidCallback? onOpenEnrollment;
  final VoidCallback onOpenIzinSakit;
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
    required this.onOpenIzinSakit,
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
  static const String _storageBase =
      'https://presensi.smknegeri1beringin.sch.id/storage/';

  void _openEditProfile() {
    HapticFeedback.lightImpact();
    EditProfileDialog.show(
      context,
      user: widget.data.user,
      onProfileUpdated: widget.onProfileUpdated,
    );
  }

  String _formatAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$_storageBase$cleanPath';
  }

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
          // ── 1. COMPACT GREETING HEADER (Gaya Bank Jago) ──
          _buildCompactGreetingHeader(user)
              .animate()
              .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 14),

          // ── 2. KARTU UTAMA PRESENSI & WIDGET PETA (Gaya Mekari Talenta) ──
          _buildPresensiMekariCard(user, sesi, hasSesi, sudahHadir)
              .animate()
              .fadeIn(duration: 400.ms, delay: 50.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 50.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 14),

          // ── 3. 4-COLUMN QUICK ACTION BAR ──
          _buildQuickActionBar()
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          // ── 4. JADWAL PELAJARAN HARI INI ──
          JadwalPelajaranWidget(
            activeSession: sesi,
            namaKelas: user.kelas,
            sudahHadir: sudahHadir,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 140.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 140.ms, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  1. COMPACT GREETING HEADER (Gaya Bank Jago)
  // ═══════════════════════════════════════════════════════════

  Widget _buildCompactGreetingHeader(UserModel user) {
    final avatarUrl = _formatAvatarUrl(user.avatar);
    final namaClean = _toTitleCase(user.nama);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
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
                  color: const Color(0xFFF1F5F9),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                color: const Color(0xFF2563EB),
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
                              color: const Color(0xFF2563EB),
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
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
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
                        'Halo, $namaClean 👋',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
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
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: user.isFaceEnrolled
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
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
                            ? const Color(0xFF10B981)
                            : const Color(0xFFD97706),
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Image.asset(
              'assets/images/logo.webp',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.school_rounded,
                size: 20,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  2. KARTU UTAMA PRESENSI & WIDGET PETA (Gaya Mekari Talenta)
  // ═══════════════════════════════════════════════════════════

  Widget _buildPresensiMekariCard(
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
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
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFEFF6FF))
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasSesi
                            ? (sudahHadir
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFFBFDBFE))
                            : const Color(0xFFE2E8F0),
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
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF2563EB))
                                : const Color(0xFF94A3B8),
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
                                    ? const Color(0xFF047857)
                                    : const Color(0xFF1D4ED8))
                                : const Color(0xFF64748B),
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
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    tglStr,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  CupertinoIcons.hourglass,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Widget Peta Presensi Interaktif dengan Animasi Radar Pulse
          _buildMapWidget(),

          const SizedBox(height: 14),

          // Tombol Aksi Utama Presensi (Gaya Mekari Talenta)
          if (!hasSesi) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.hourglass,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Menunggu Sesi Presensi Dibuka',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (sudahHadir) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    size: 18,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sudah Presensi Hari Ini ✓',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: widget.onOpenScanner,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
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

  // ═══════════════════════════════════════════════════════════
  //  2B. WIDGET PETA DENGAN ANIMASI PULSING RADAR (Gaya Mekari Talenta)
  // ═══════════════════════════════════════════════════════════

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

            // Pin Marker Sekolah di Tengah Peta dengan Animasi Radar Pulse
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse Ripple Ring 1 (Continuous Wave)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2563EB).withOpacity(0.35),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(2.4, 2.4),
                        duration: 1600.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeOut(duration: 1600.ms, curve: Curves.easeOut),

                  // Pulse Ripple Ring 2 (Delayed Secondary Wave)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2563EB).withOpacity(0.25),
                    ),
                  )
                      .animate(
                        onPlay: (c) => c.repeat(),
                        delay: 800.ms,
                      )
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(2.4, 2.4),
                        duration: 1600.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeOut(duration: 1600.ms, curve: Curves.easeOut),

                  // Pin Sekolah Inti
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
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
                    const Icon(
                      CupertinoIcons.shield_fill,
                      size: 12,
                      color: Color(0xFF34D399),
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
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.location_fill,
                      size: 16,
                      color: Color(0xFF2563EB),
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
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFBFDBFE)),
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
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Mengunci Titik GPS...',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2563EB),
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
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFFECDD3)),
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
            const Icon(
              CupertinoIcons.clear_circled_solid,
              size: 11,
              color: Color(0xFFE11D48),
            ),
            const SizedBox(width: 5),
            Text(
              'Fake GPS Terdeteksi',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFE11D48),
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
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
            const Icon(
              CupertinoIcons.location,
              size: 11,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              'GPS Belum Akurat',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
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
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFF86EFAC)),
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
            const Icon(
              CupertinoIcons.checkmark_alt_circle_fill,
              size: 11,
              color: Color(0xFF16A34A),
            ),
            const SizedBox(width: 5),
            Text(
              'Area Valid • ${geo.distanceMeters.toStringAsFixed(0)}m',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFFDE68A)),
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
          const Icon(
            CupertinoIcons.location_solid,
            size: 11,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 5),
          Text(
            'Di Luar Area • ${geo.distanceMeters.toStringAsFixed(0)}m',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  3. 4-COLUMN QUICK ACTION BAR (Sesuai Desain Asli)
  // ═══════════════════════════════════════════════════════════

  Widget _buildQuickActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
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
            bgColor: const Color(0xFFEFF6FF), // soft blue-50
            iconColor: const Color(0xFF2563EB), // blue-600
            onTap: widget.onOpenKehadiran,
          ),
          _buildQuickActionItem(
            icon: CupertinoIcons.person_2_fill,
            label: 'Teman',
            bgColor: const Color(0xFFEEF2FF), // soft indigo-50
            iconColor: const Color(0xFF4F46E5), // indigo-600
            onTap: widget.onOpenTeman,
          ),
          _buildQuickActionItem(
            icon: CupertinoIcons.location_solid,
            label: 'Cek Lokasi',
            bgColor: const Color(0xFFECFDF5), // soft emerald-50
            iconColor: const Color(0xFF059669), // emerald-600
            onTap: () {
              if (widget.onRefreshLocation != null) {
                widget.onRefreshLocation!();
              }
            },
          ),
          _buildQuickActionItem(
            icon: CupertinoIcons.book_fill,
            label: 'Panduan',
            bgColor: const Color(0xFFFFFBEB), // soft amber-50
            iconColor: const Color(0xFFD97706), // amber-600
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
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
