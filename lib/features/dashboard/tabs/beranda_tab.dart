import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/models/dashboard_full_model.dart';
import '../../../core/models/session_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/location_service.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../dialogs/classmate_detail_dialog.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  BERANDA TAB — 100% Authentic Apple iOS 18 HIG Design System
//  Hero Student Pass • Apple Dynamic Island • Activity Rings
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class BerandaTab extends StatefulWidget {
  final DashboardFullModel data;
  final GeofenceResult? geofenceResult;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenKehadiran;
  final VoidCallback onOpenTeman;
  final ValueChanged<UserModel> onProfileUpdated;

  const BerandaTab({
    super.key,
    required this.data,
    required this.geofenceResult,
    required this.onOpenScanner,
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

  void _openEditProfile() {
    HapticFeedback.lightImpact();
    EditProfileDialog.show(
      context,
      user: widget.data.user,
      onProfileUpdated: widget.onProfileUpdated,
    );
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
      padding: const EdgeInsets.only(left: 18, right: 18, top: 4, bottom: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          //  1. HERO: DIGITAL STUDENT PASS (APPLE WALLET / HIG PASS)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          _buildDigitalStudentPass(user, stats)
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
              .slideY(
                begin: 0.04,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 16),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          //  2. APPLE LIVE ACTIVITY / DYNAMIC ISLAND PRESENSI
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          if (hasSesi && sesi != null)
            _buildLiveActivityCard(sesi, sudahHadir)
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms, curve: Curves.easeOutCubic)
                .scale(
                  begin: const Offset(0.97, 0.97),
                  end: const Offset(1, 1),
                  duration: 450.ms,
                  delay: 100.ms,
                  curve: Curves.easeOutBack,
                )
          else
            _buildNoSessionCard()
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 16),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          //  3. APPLE HEALTH / ACTIVITY RING STATS (NO AI SLOP)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          _buildAppleHealthRingCard(stats)
              .animate()
              .fadeIn(duration: 400.ms, delay: 180.ms, curve: Curves.easeOutCubic)
              .slideY(
                begin: 0.04,
                end: 0,
                duration: 400.ms,
                delay: 180.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 18),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          //  4. CLASSMATES STRIP (APPLE CONTACTS STYLE)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          _buildClassmatesStrip(classmates, user)
              .animate()
              .fadeIn(duration: 400.ms, delay: 240.ms, curve: Curves.easeOutCubic)
              .slideY(
                begin: 0.04,
                end: 0,
                duration: 400.ms,
                delay: 240.ms,
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  1. HERO: DIGITAL STUDENT PASS (APPLE WALLET HIG)
  // ═══════════════════════════════════════════════════════════

  Widget _buildDigitalStudentPass(UserModel user, StatsModel stats) {
    final hasBanner = user.banner != null && user.banner!.isNotEmpty;
    final rate = stats.persentase.clamp(0.0, 100.0);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cover Banner Header ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 116,
                width: double.infinity,
                child: hasBanner
                    ? Image.network(
                        '$_storageBase${user.banner}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildBannerFallback(),
                      )
                    : _buildBannerFallback(),
              ),
              Container(
                height: 116,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
              ),

              // Status Bar on Banner (Face ID + Clock)
              Positioned(
                top: 12,
                left: 14,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: BoxDecoration(
                              color: user.isFaceEnrolled
                                  ? const Color(0xFF34C759)
                                  : const Color(0xFFFF9500),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            user.isFaceEnrolled
                                ? 'Face ID Aktif'
                                : 'Belum Rekam Wajah',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '•  ${DateFormat('HH:mm').format(DateTime.now())} WIB',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Edit Profile Button on Banner
              Positioned(
                top: 12,
                right: 14,
                child: GestureDetector(
                  onTap: _openEditProfile,
                  behavior: HitTestBehavior.opaque,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.pencil,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Profile Body with Overlapping Avatar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar + Kehadiran Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Floating Avatar overlapping banner
                    Transform.translate(
                      offset: const Offset(0, -32),
                      child: Stack(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: (user.avatar != null &&
                                      user.avatar!.isNotEmpty)
                                  ? Image.network(
                                      '$_storageBase${user.avatar}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildAvatarFallback(user),
                                    )
                                  : _buildAvatarFallback(user),
                            ),
                          ),
                          if (user.isFaceEnrolled)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34C759),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2.5),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Kehadiran Pill (Matching User's Original HIG screen)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onOpenKehadiran();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E5EA)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'KEHADIRAN',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF8E8E93),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '${rate.toStringAsFixed(0)}%',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF34C759),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              CupertinoIcons.chevron_right,
                              size: 14,
                              color: Color(0xFF34C759),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Name & Verified Badge
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.nama,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF000000),
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: Color(0xFF007AFF),
                      size: 18,
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                // Handle & School
                Text(
                  '@${user.username} • SMK Negeri 1 Beringin',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8E8E93),
                  ),
                ),

                // Website / Social Pill (Safari Style)
                if (user.website != null && user.website!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => HapticFeedback.selectionClick(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.compass,
                            size: 14,
                            color: Color(0xFF007AFF),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              user.website!,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF007AFF),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // 2 Bento Info Cards: KELAS & NISN (Apple Inset Style)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.book_fill,
                              size: 16,
                              color: Color(0xFF007AFF),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'KELAS',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF8E8E93),
                                    ),
                                  ),
                                  Text(
                                    user.kelas,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF000000),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.person_badge_plus_fill,
                              size: 16,
                              color: Color(0xFF5856D6),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NISN',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF8E8E93),
                                    ),
                                  ),
                                  Text(
                                    user.nisn,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF000000),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  2. APPLE LIVE ACTIVITY / DYNAMIC ISLAND PRESENSI
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
                        fontSize: 10.5,
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
                      Icons.schedule_rounded,
                      size: 13,
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
            sesi.keterangan.isNotEmpty
                ? sesi.keterangan
                : 'Presensi Kehadiran Siswa SMKN 1 Beringin',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8E8E93),
            ),
          ),

          const SizedBox(height: 20),

          // ── Action / Status Area ──
          if (sudahHadir)
            // Apple Success Confirmation Pill
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
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFF34C759),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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
                        const SizedBox(height: 2),
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
                      Icons.camera_alt_rounded,
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
                Icons.near_me_rounded,
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
              Icons.nightlight_round,
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
  //  3. APPLE HEALTH / ACTIVITY RING STATS (PURE HIG - NO AI SLOP)
  // ═══════════════════════════════════════════════════════════

  Widget _buildAppleHealthRingCard(StatsModel stats) {
    final rate = stats.persentase.clamp(0.0, 100.0);

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
                      CupertinoIcons.chart_pie,
                      size: 17,
                      color: Color(0xFF007AFF),
                    ),
                    const SizedBox(width: 8),
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
                    const SizedBox(width: 2),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: Color(0xFF007AFF),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Middle: Apple Activity Ring & Typographic Rate ──
            Row(
              children: [
                // Custom Circular Activity Ring
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: rate / 100.0,
                        strokeWidth: 8,
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
                          color: const Color(0xFF000000),
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
                        'Performa Presensi Siswa',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF000000),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.hadir} dari ${stats.total} total pertemuan semester ini.',
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

            // ── Apple Activity Segmented Bar (Proportional) ──
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 7,
                child: Row(
                  children: [
                    if (stats.hadir > 0)
                      Expanded(
                        flex: stats.hadir,
                        child: Container(color: const Color(0xFF34C759)),
                      ),
                    if (stats.izin > 0)
                      Expanded(
                        flex: stats.izin,
                        child: Container(color: const Color(0xFFFF9500)),
                      ),
                    if (stats.sakit > 0)
                      Expanded(
                        flex: stats.sakit,
                        child: Container(color: const Color(0xFF5856D6)),
                      ),
                    if (stats.alpa > 0)
                      Expanded(
                        flex: stats.alpa,
                        child: Container(color: const Color(0xFFFF3B30)),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── 4 Crisp Apple Metric Columns (NO PASTEL BOXES) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAppleMetric('Hadir', '${stats.hadir}', const Color(0xFF34C759)),
                _buildAppleDivider(),
                _buildAppleMetric('Izin', '${stats.izin}', const Color(0xFFFF9500)),
                _buildAppleDivider(),
                _buildAppleMetric('Sakit', '${stats.sakit}', const Color(0xFF5856D6)),
                _buildAppleDivider(),
                _buildAppleMetric('Alpa', '${stats.alpa}', const Color(0xFFFF3B30)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleDivider() {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFFE5E5EA),
    );
  }

  Widget _buildAppleMetric(String label, String value, Color dotColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF000000),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  4. CLASSMATES STRIP (APPLE CONTACTS STYLE)
  // ═══════════════════════════════════════════════════════════

  Widget _buildClassmatesStrip(
      List<ClassmateModel> classmates, UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.person_2_fill,
                  size: 17,
                  color: Color(0xFF007AFF),
                ),
                const SizedBox(width: 6),
                Text(
                  'Teman Sekelas (${classmates.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
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
                  const SizedBox(width: 2),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: Color(0xFF007AFF),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: classmates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final mate = classmates[index];
              final isHadir = mate.statusHariIni == 'hadir';

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ClassmateDetailDialog.show(
                    context,
                    classmate: mate,
                    kelasNama: user.kelas,
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isHadir
                                  ? const Color(0xFF34C759)
                                  : const Color(0xFFE5E5EA),
                              width: isHadir ? 2.5 : 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: (mate.avatar != null &&
                                    mate.avatar!.isNotEmpty)
                                ? Image.network(
                                    '$_storageBase${mate.avatar}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildInitialAvatar(mate.name),
                                  )
                                : _buildInitialAvatar(mate.name),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isHadir
                                  ? const Color(0xFF34C759)
                                  : const Color(0xFF8E8E93),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 56,
                      child: Text(
                        mate.name.split(' ').first,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C1C1E),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInitialAvatar(String name) {
    final initials = name.isNotEmpty
        ? name
            .trim()
            .split(' ')
            .map((p) => p.isNotEmpty ? p[0] : '')
            .take(2)
            .join()
        : 'S';
    return Container(
      color: const Color(0xFFE5E5EA),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF8E8E93),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(UserModel user) {
    final initials = user.nama.isNotEmpty
        ? user.nama
            .trim()
            .split(' ')
            .map((p) => p.isNotEmpty ? p[0] : '')
            .take(2)
            .join()
        : 'S';
    return Container(
      color: const Color(0xFF007AFF),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
