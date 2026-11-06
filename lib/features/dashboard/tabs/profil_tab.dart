import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/dashboard_full_model.dart';
import '../../../core/models/user_model.dart';
import '../dialogs/edit_profile_dialog.dart';

class ProfilTab extends StatelessWidget {
  final DashboardFullModel data;
  final VoidCallback onLogout;

  const ProfilTab({
    super.key,
    required this.data,
    required this.onLogout,
  });

  static const String _storageBase =
      'https://presensi.smknegeri1beringin.sch.id/storage/';

  void _openEdit(BuildContext context) {
    HapticFeedback.lightImpact();
    EditProfileDialog.show(
      context,
      user: data.user,
      onProfileUpdated: (updatedUser) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = data.user;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(left: 18, right: 18, top: 8, bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. APPLE ID HERO CARD ──
          _buildAppleIDHero(context, user)
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
              .scale(
                begin: const Offset(0.97, 0.97),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 20),

          // ── 2. DATA AKADEMIK (iOS Inset Group) ──
          _buildSectionHeader('INFORMASI AKADEMIK'),
          const SizedBox(height: 8),
          _buildGroupedCard([
            _buildTile(
              icon: CupertinoIcons.number,
              iconColor: const Color(0xFF007AFF),
              label: 'NISN',
              value: user.nisn,
            ),
            _buildTile(
              icon: CupertinoIcons.person_2_fill,
              iconColor: const Color(0xFF5856D6),
              label: 'Kelas',
              value: user.kelas,
            ),
            _buildTile(
              icon: CupertinoIcons.building_2_fill,
              iconColor: const Color(0xFFFF9500),
              label: 'Sekolah',
              value: 'SMKN 1 Beringin',
              isLast: true,
            ),
          ]),

          const SizedBox(height: 20),

          // ── 3. NOTIFIKASI ORANG TUA (iOS Inset Group) ──
          _buildSectionHeader('NOTIFIKASI WHATSAPP ORANG TUA'),
          const SizedBox(height: 8),
          _buildGroupedCard([
            _buildTile(
              icon: CupertinoIcons.person_crop_circle_badge_checkmark,
              iconColor: const Color(0xFF34C759),
              label: 'Nama Orang Tua / Wali',
              value: (user.namaOrtu != null && user.namaOrtu!.isNotEmpty)
                  ? user.namaOrtu!
                  : 'Belum diatur',
            ),
            _buildTile(
              icon: CupertinoIcons.phone_fill,
              iconColor: const Color(0xFF34C759),
              label: 'Nomor WhatsApp',
              value: (user.noHpOrtu != null && user.noHpOrtu!.isNotEmpty)
                  ? user.noHpOrtu!
                  : 'Belum diatur',
              isLast: true,
            ),
          ]),

          const SizedBox(height: 20),

          // ── 4. BIOMETRIK & KEAMANAN ──
          _buildSectionHeader('BIOMETRIK & KEAMANAN'),
          const SizedBox(height: 8),
          _buildGroupedCard([
            _buildTile(
              icon: CupertinoIcons.viewfinder,
              iconColor: user.isFaceEnrolled
                  ? const Color(0xFF34C759)
                  : const Color(0xFFFF9500),
              label: 'Face ID Presensi',
              value: user.isFaceEnrolled
                  ? 'Terverifikasi & Aktif'
                  : 'Belum Rekam Wajah',
              valueColor: user.isFaceEnrolled
                  ? const Color(0xFF34C759)
                  : const Color(0xFFFF9500),
              isLast: true,
            ),
          ]),

          const SizedBox(height: 20),

          // ── 5. AKSI AKUN (iOS Inset Group) ──
          _buildSectionHeader('PENGATURAN'),
          const SizedBox(height: 8),
          _buildGroupedCard([
            _buildActionTile(
              icon: CupertinoIcons.pencil,
              iconColor: const Color(0xFF007AFF),
              label: 'Edit Profil Siswa',
              onTap: () => _openEdit(context),
            ),
            _buildActionTile(
              icon: CupertinoIcons.square_arrow_right,
              iconColor: const Color(0xFFFF3B30),
              label: 'Keluar dari Akun',
              textColor: const Color(0xFFFF3B30),
              isLast: true,
              onTap: onLogout,
            ),
          ]),

          const SizedBox(height: 28),

          // Footer
          Center(
            child: Text(
              'Presensi Siswa v2.0 • SMK Negeri 1 Beringin',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF8E8E93),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  APPLE ID HERO
  // ═══════════════════════════════════════════════════════════

  Widget _buildAppleIDHero(BuildContext context, UserModel user) {
    final hasBanner = user.banner != null && user.banner!.isNotEmpty;

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
        children: [
          // ── Cover Banner (if set) ──
          if (hasBanner)
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: Image.network(
                    '$_storageBase${user.banner}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.35),
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          Padding(
            padding: EdgeInsets.fromLTRB(22, hasBanner ? 0 : 22, 22, 22),
            child: Column(
              children: [
                // Large Avatar (Overlaps banner if present)
                Transform.translate(
                  offset: Offset(0, hasBanner ? -36 : 0),
                  child: Stack(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: (user.avatar != null && user.avatar!.isNotEmpty)
                              ? Image.network(
                                  '$_storageBase${user.avatar}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildFallback(user),
                                )
                              : _buildFallback(user),
                        ),
                      ),
                      if (user.isFaceEnrolled)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                            child: const Icon(
                              CupertinoIcons.checkmark_alt,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: hasBanner ? 0 : 14),

                // Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        user.nama,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: Color(0xFF007AFF),
                      size: 17,
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  '@${user.username.isNotEmpty ? user.username : user.nisn} • ${user.kelas}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8E8E93),
                  ),
                ),

                // Website / Portfolio chip
                if (user.website != null && user.website!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.compass,
                          size: 12,
                          color: Color(0xFF007AFF),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            user.website!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
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
                ],

                // Bio
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF3C3C43),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Edit Profile Button
                CupertinoButton(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  onPressed: () => _openEdit(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.pencil,
                        size: 13,
                        color: Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Atur Profil',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF007AFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF8E8E93),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1C1C1E),
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 60, color: Color(0xFFF2F2F7)),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    Color? textColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? const Color(0xFF1C1C1E),
                  ),
                ),
                const Spacer(),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: Color(0xFFC7C7CC),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 60, color: Color(0xFFF2F2F7)),
      ],
    );
  }

  Widget _buildFallback(UserModel user) {
    return Container(
      color: const Color(0xFF007AFF),
      alignment: Alignment.center,
      child: Text(
        user.nama.isNotEmpty ? user.nama[0] : 'S',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
