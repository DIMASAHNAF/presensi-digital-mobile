import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/dashboard_full_model.dart';

class ClassmateDetailDialog extends StatelessWidget {
  final ClassmateModel classmate;
  final String kelasNama;

  const ClassmateDetailDialog({
    super.key,
    required this.classmate,
    required this.kelasNama,
  });

  static const String _storageBase =
      'https://presensi.smknegeri1beringin.sch.id/storage/';

  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static Future<void> show(
    BuildContext context, {
    required ClassmateModel classmate,
    required String kelasNama,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClassmateDetailDialog(
        classmate: classmate,
        kelasNama: kelasNama,
      ),
    );
  }

  String _formatUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$_storageBase$cleanPath';
  }

  Future<void> _openWebsite(String url) async {
    try {
      final validUrl = url.startsWith('http') ? url : 'https://$url';
      final uri = Uri.parse(validUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final status = classmate.statusHariIni.toLowerCase();
    final isHadir = status == 'hadir';
    final isIzin = status == 'izin';
    final isSakit = status == 'sakit';

    Color statusBgColor;
    Color statusTextColor;
    Color statusDotColor;
    String statusLabel;

    if (isHadir) {
      statusBgColor = const Color(0xFFECFDF5);
      statusTextColor = const Color(0xFF047857);
      statusDotColor = const Color(0xFF10B981);
      statusLabel = classmate.jamAbsen != null && classmate.jamAbsen!.isNotEmpty
          ? 'Hadir ${classmate.jamAbsen} WIB'
          : 'Hadir Hari Ini';
    } else if (isIzin) {
      statusBgColor = const Color(0xFFFFFBEB);
      statusTextColor = const Color(0xFFB45309);
      statusDotColor = const Color(0xFFF59E0B);
      statusLabel = 'Izin';
    } else if (isSakit) {
      statusBgColor = const Color(0xFFF0F9FF);
      statusTextColor = const Color(0xFF0369A1);
      statusDotColor = const Color(0xFF0EA5E9);
      statusLabel = 'Sakit';
    } else {
      statusBgColor = const Color(0xFFF1F5F9);
      statusTextColor = const Color(0xFF64748B);
      statusDotColor = const Color(0xFF94A3B8);
      statusLabel = 'Belum Presensi';
    }

    final bannerUrl = _formatUrl(classmate.banner);
    final avatarUrl = _formatUrl(classmate.avatar);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Classmate Cover Banner (Identik Versi Web) ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 110,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: bannerUrl.isNotEmpty
                    ? Image.network(
                        bannerUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultBanner(),
                      )
                    : _buildDefaultBanner(),
              ),

              // Close Button (top right)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // iOS Drag Handle on top center
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── 2. Avatar & Status Badge (Overlapping Banner) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Overlapping Avatar with presence ring
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
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
                      child: avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                            )
                          : _buildAvatarFallback(),
                    ),
                  ),
                ),

                // Status Badge Hari Ini
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusDotColor.withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusDotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: statusTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 3. Info Siswa (Nama, Verified Badge, Username, Kelas) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _toTitleCase(classmate.nama),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: Color(0xFF007AFF),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Username & Kelas
                Row(
                  children: [
                    Text(
                      '@${classmate.username.isNotEmpty ? classmate.username : 'siswa'}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      kelasNama.isNotEmpty ? kelasNama : 'SMKN 1 Beringin',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── 4. Bio Quote Box (Identik Versi Web) ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    (classmate.bio != null && classmate.bio!.trim().isNotEmpty)
                        ? '“${classmate.bio!.trim()}”'
                        : 'Teman ini belum menulis biografi profil.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: (classmate.bio != null &&
                              classmate.bio!.trim().isNotEmpty)
                          ? const Color(0xFF334155)
                          : const Color(0xFF94A3B8),
                      height: 1.45,
                    ),
                  ),
                ),

                // ── 5. Website / Portfolio Link (Jika ada) ──
                if (classmate.website != null &&
                    classmate.website!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _openWebsite(classmate.website!.trim()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.link,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              classmate.website!
                                  .trim()
                                  .replaceAll(RegExp(r'^https?:\/\/'), ''),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2563EB),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            CupertinoIcons.arrow_up_right,
                            size: 11,
                            color: Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // ── 6. Close Button ──
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      color: const Color(0xFF1E293B),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/map_campus.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFF2563EB),
      alignment: Alignment.center,
      child: Text(
        classmate.nama.isNotEmpty ? classmate.nama[0].toUpperCase() : 'S',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
