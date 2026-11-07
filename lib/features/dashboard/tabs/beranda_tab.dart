import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/dashboard_full_model.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/location_service.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../dialogs/classmate_detail_dialog.dart';
import '../widgets/jadwal_pelajaran_widget.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  BERANDA TAB — 100% Authentic Apple iOS 18 Design Language
//  Dynamic Island Live Activity • Apple Health Ring • Apple Wallet Pass
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class BerandaTab extends StatefulWidget {
  final DashboardFullModel data;
  final GeofenceResult? geofenceResult;
  final String currentTimeWIB;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenStudentCard;
  final VoidCallback onOpenIzinSakit;
  final VoidCallback onOpenRekap;
  final VoidCallback onOpenKehadiran;
  final VoidCallback onOpenTeman;
  final ValueChanged<UserModel> onProfileUpdated;

  const BerandaTab({
    super.key,
    required this.data,
    required this.geofenceResult,
    required this.currentTimeWIB,
    required this.onOpenScanner,
    required this.onOpenStudentCard,
    required this.onOpenIzinSakit,
    required this.onOpenRekap,
    required this.onOpenKehadiran,
    required this.onOpenTeman,
    required this.onProfileUpdated,
  });

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  static const String _storageBase =
      'https://presensi.smknegeri1beringin.sch.id/storage/';

  bool _isPwaDismissed = false;

  void _openEditProfile() {
    HapticFeedback.lightImpact();
    EditProfileDialog.show(
      context,
      user: widget.data.user,
      onProfileUpdated: widget.onProfileUpdated,
    );
  }

  void _launchWebsite(String url) async {
    final cleanUrl = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.parse(cleanUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _downloadApk() async {
    final uri = Uri.parse('https://presensi.smknegeri1beringin.sch.id/apk/presensi-smkn1beringin.apk');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.data.user;
    final stats = widget.data.stats;
    final hasSesi = widget.data.hasSesi;
    final sudahHadir = widget.data.sudahHadir;
    final sesi = widget.data.sesi;
    final classmates = widget.data.temanSekelas;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(left: 18, right: 18, top: 12, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          //  1. APPLE DYNAMIC ISLAND / LIVE ACTIVITY PRESENSI CARD
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          if (hasSesi && sesi != null)
            _buildLiveActivityCard(sesi, sudahHadir)
                .animate()
                .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
                .scale(
                  begin: const Offset(0.97, 0.97),
                  end: const Offset(1, 1),
                  duration: 450.ms,
                  curve: Curves.easeOutBack,
                )
          else
            _buildNoSessionCard()
                .animate()
                .fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          //  2. APPLE iOS 18 CONTROL CENTER QUICK ACTION TILES
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          _buildControlCenterQuickActions()
              .animate()
              .fadeIn(duration: 400.ms, delay: 60.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 60.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          //  3. DIGITAL STUDENT ID PASS (APPLE WALLET STYLE)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          _buildDigitalStudentPass(user, stats)
              .animate()
              .fadeIn(duration: 400.ms, delay: 120.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 120.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          //  4. APPLE HEALTH / ACTIVITY RING STATS
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          _buildAppleHealthRingCard(stats)
              .animate()
              .fadeIn(duration: 400.ms, delay: 180.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 180.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          //  5. CLASSMATES STRIP (APPLE CONTACTS STYLE)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          _buildClassmatesStrip(classmates, user)
              .animate()
              .fadeIn(duration: 400.ms, delay: 240.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 240.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          //  6. JADWAL PELAJARAN (APPLE REMINDERS / CALENDAR STYLE)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          JadwalPelajaranWidget(
            activeSession: sesi,
            namaKelas: user.kelas,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 300.ms, curve: Curves.easeOutCubic),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          //  7. PWA / APK INSTALL BANNER (APPLE NOTIFICATION STYLE)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          if (!_isPwaDismissed) ...[
            const SizedBox(height: 16),
            _buildAppleInstallNotification()
                .animate()
                .fadeIn(duration: 400.ms, delay: 340.ms, curve: Curves.easeOutCubic),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  1. APPLE LIVE ACTIVITY / DYNAMIC ISLAND PRESENSI
  // ═══════════════════════════════════════════════════════════

  Widget _buildLiveActivityCard(SessionDetail sesi, bool sudahHadir) {
    final inRadius = widget.geofenceResult?.isInsideRadius ?? false;
    final distance = widget.geofenceResult?.distanceMeters ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C1017),
            Color(0xFF131A26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.12),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top Row: Status Radar & Sesi ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pulsing live capsule
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF34C759).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Radar pulse dot
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34C759),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF34C759),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SESI SEDANG BERLANGSUNG',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF34C759),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Time badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.clock_fill,
                      size: 11,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${sesi.jamMulai} - ${sesi.jamSelesai} WIB',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFC7C7CC),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Middle: Class & Subject Name ──
          Text(
            sesi.namaKelas,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sesi.guruNama.isNotEmpty
                ? 'Guru Pengajar: ${sesi.guruNama}'
                : (sesi.keterangan.isNotEmpty ? sesi.keterangan : 'Presensi Kehadiran Siswa SMKN 1 Beringin'),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8E8E93),
            ),
          ),

          const SizedBox(height: 20),

          // ── Action / Status Area ──
          if (sudahHadir)
            // Apple Success Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF34C759).withOpacity(0.35),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF34C759),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Presensi Terverifikasi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Kehadiran Anda sudah tercatat pada sesi ini.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF34C759),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            // Apple Tactile Action Button: Scan Wajah Sekarang
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onOpenScanner();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF007AFF),
                      Color(0xFF5856D6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.viewfinder,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Presensi Wajah Sekarang',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 14),

          // ── Bottom Geofence Indicator ──
          Row(
            children: [
              Icon(
                CupertinoIcons.location_fill,
                size: 13,
                color: inRadius
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF9500),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  inRadius
                      ? 'Radius GPS Valid (~${distance.toStringAsFixed(0)}m dari sekolah)'
                      : 'Memverifikasi radius lokasi GPS sekolah...',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: inRadius
                        ? const Color(0xFF34C759)
                        : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoSessionCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.moon_stars_fill,
              color: Color(0xFF007AFF),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tidak Ada Sesi Aktif',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jadwal presensi berikutnya akan muncul saat sesi dibuka.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  2. APPLE iOS 18 CONTROL CENTER QUICK ACTION TILES
  // ═══════════════════════════════════════════════════════════

  Widget _buildControlCenterQuickActions() {
    return Row(
      children: [
        _buildActionTile(
          icon: CupertinoIcons.camera_viewfinder,
          label: 'Scan Wajah',
          gradientColors: [const Color(0xFF007AFF), const Color(0xFF0051B3)],
          onTap: widget.onOpenScanner,
        ),
        const SizedBox(width: 10),
        _buildActionTile(
          icon: CupertinoIcons.qrcode,
          label: 'QR ID Siswa',
          gradientColors: [const Color(0xFF5856D6), const Color(0xFF3634A3)],
          onTap: widget.onOpenStudentCard,
        ),
        const SizedBox(width: 10),
        _buildActionTile(
          icon: CupertinoIcons.doc_plaintext,
          label: 'Izin / Sakit',
          gradientColors: [const Color(0xFFFF9500), const Color(0xFFCC7700)],
          onTap: widget.onOpenIzinSakit,
        ),
        const SizedBox(width: 10),
        _buildActionTile(
          icon: CupertinoIcons.chart_bar_alt_fill,
          label: 'Rekap',
          gradientColors: [const Color(0xFF30B0C7), const Color(0xFF008299)],
          onTap: widget.onOpenRekap,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1C1E),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  3. DIGITAL STUDENT ID PASS (APPLE WALLET STYLE)
  // ═══════════════════════════════════════════════════════════

  Widget _buildDigitalStudentPass(UserModel user, StatsModel stats) {
    final hasBanner = user.banner != null && user.banner!.isNotEmpty;
    final hasWebsite = user.website != null && user.website!.isNotEmpty;
    final websiteUrl = hasWebsite ? user.website! : 'dimas.tiksmkn1beringin.my.id';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cover Banner Header with Glass Badges ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: hasBanner
                    ? Image.network(
                        '$_storageBase${user.banner}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      )
                    : null,
              ),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),

              // Top Bar over Cover: Face ID Pill & Edit Profile Pill
              Positioned(
                top: 10,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Face ID Aktif Glass Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34C759),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Face ID Aktif • ${widget.currentTimeWIB.isNotEmpty ? widget.currentTimeWIB : "WIB"}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Edit Profil Button
                    GestureDetector(
                      onTap: _openEditProfile,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.pencil, size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Edit Profil',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Avatar + Kehadiran Badge
              Positioned(
                bottom: -28,
                left: 18,
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: user.avatar != null && user.avatar!.isNotEmpty
                            ? Image.network(
                                '$_storageBase${user.avatar}',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildAvatarFallback(user.nama),
                              )
                            : _buildAvatarFallback(user.nama),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Kehadiran 75% Badge on Right
              Positioned(
                bottom: 8,
                right: 14,
                child: GestureDetector(
                  onTap: widget.onOpenKehadiran,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'KEHADIRAN ',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF8E8E93),
                          ),
                        ),
                        Text(
                          '${stats.persentase.toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF34C759),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(CupertinoIcons.chevron_right, size: 11, color: Color(0xFF8E8E93)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 34),

          // ── Student Identity Info ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.nama.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, size: 17, color: Color(0xFF007AFF)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username} • SMKN 1 Beringin',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),

                // Clickable Website Link
                GestureDetector(
                  onTap: () => _launchWebsite(websiteUrl),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.link, size: 12, color: Color(0xFF007AFF)),
                      const SizedBox(width: 4),
                      Text(
                        websiteUrl,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF007AFF),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Apple Wallet Metadata Bento Cards: KELAS & NISN ──
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(CupertinoIcons.building_2_fill, size: 16, color: Color(0xFF007AFF)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'KELAS',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF94A3B8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    user.kelas,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5856D6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(CupertinoIcons.creditcard_fill, size: 16, color: Color(0xFF5856D6)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NISN',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF94A3B8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    user.nisn,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Callout Bio & Atur
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lengkapi bio profil & tautan sosial media kamu!',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _openEditProfile,
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          'Atur →',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Apple Wallet QR Pass Button
                GestureDetector(
                  onTap: widget.onOpenStudentCard,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.qrcode, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Buka Kartu ID Pelajar Digital (QR)',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join()
        : 'S';
    return Container(
      color: const Color(0xFFE2E8F0),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF007AFF),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  4. APPLE HEALTH / ACTIVITY RING STATS
  // ═══════════════════════════════════════════════════════════

  Widget _buildAppleHealthRingCard(StatsModel stats) {
    final rate = stats.persentase.clamp(0, 100).toDouble();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onOpenKehadiran();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Header Row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.chart_pie_fill,
                      size: 16,
                      color: Color(0xFF007AFF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'RINGKASAN KEHADIRAN',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF8E8E93),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Detail',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF007AFF),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      size: 12,
                      color: Color(0xFF007AFF),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Middle: Ring & Large Rate Indicator ──
            Row(
              children: [
                // Custom Circular Activity Ring
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: rate / 100.0,
                        strokeWidth: 7.5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: const Color(0xFFE5E5EA),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF34C759),
                        ),
                      ),
                      Text(
                        '${rate.toStringAsFixed(0)}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rate >= 80
                            ? 'Sangat Baik 🌟'
                            : rate >= 60
                                ? 'Cukup Baik 👍'
                                : 'Perlu Ditingkatkan ⚠️',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tingkat kehadiran Anda di SMKN 1 Beringin semester ini.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF8E8E93),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFF2F2F7)),
            const SizedBox(height: 14),

            // ── 4 iOS Bento Stat Mini Widgets ──
            Row(
              children: [
                _buildStatPill('Hadir', '${stats.hadir}', const Color(0xFF34C759), const Color(0xFFE8F8ED)),
                const SizedBox(width: 8),
                _buildStatPill('Izin', '${stats.izin}', const Color(0xFFFF9500), const Color(0xFFFFF4E6)),
                const SizedBox(width: 8),
                _buildStatPill('Sakit', '${stats.sakit}', const Color(0xFF5856D6), const Color(0xFFF2F1FD)),
                const SizedBox(width: 8),
                _buildStatPill('Alpa', '${stats.alpa}', const Color(0xFFFF3B30), const Color(0xFFFFEBEB)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  5. CLASSMATES STRIP (APPLE CONTACTS STYLE)
  // ═══════════════════════════════════════════════════════════

  Widget _buildClassmatesStrip(List<ClassmateModel> classmates, UserModel currentUser) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.person_2_fill,
                    size: 16,
                    color: Color(0xFF007AFF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TEMAN SEKELAS HARI INI',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8E8E93),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${classmates.length}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF007AFF),
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: widget.onOpenTeman,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Text(
                      'Lihat Semua',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF007AFF),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      size: 12,
                      color: Color(0xFF007AFF),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (classmates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Belum ada data teman sekelas yang tercatat hari ini.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8E8E93)),
                textAlign: TextAlign.center,
              ),
            )
          else
            SizedBox(
              height: 94,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: classmates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final friend = classmates[index];
                  final isHadir = friend.statusHariIni.toLowerCase() == 'hadir';

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ClassmateDetailDialog.show(context, classmate: friend, kelasNama: currentUser.kelas);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 58,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isHadir ? const Color(0xFF34C759) : const Color(0xFFE5E5EA),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 23,
                              backgroundColor: const Color(0xFFF2F2F7),
                              backgroundImage: friend.avatar != null && friend.avatar!.isNotEmpty
                                  ? NetworkImage('$_storageBase${friend.avatar}')
                                  : null,
                              child: friend.avatar == null || friend.avatar!.isEmpty
                                  ? Text(
                                      friend.initials,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isHadir ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            friend.nama.split(' ').first,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C1C1E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            isHadir ? (friend.jamAbsen ?? 'Hadir') : 'Belum',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: isHadir ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
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

  // ═══════════════════════════════════════════════════════════
  //  7. PWA / APK INSTALL BANNER (APPLE NOTIFICATION STYLE)
  // ═══════════════════════════════════════════════════════════

  Widget _buildAppleInstallNotification() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(CupertinoIcons.device_phone_portrait, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pasang Aplikasi Native HP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lebih cepat & praktis tanpa perlu buka browser setiap hari.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _downloadApk,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Pasang',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _isPwaDismissed = true),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(CupertinoIcons.xmark, size: 14, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }
}
