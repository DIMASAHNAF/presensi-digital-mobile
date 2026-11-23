import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/dashboard_full_model.dart';
import '../../../core/theme/app_theme.dart';

class ClassmateDetailDialog extends StatelessWidget {
  final ClassmateModel classmate;
  final String kelasNama;

  const ClassmateDetailDialog({
    super.key,
    required this.classmate,
    required this.kelasNama,
  });

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

  String _formatUrl(String? path) => ApiConstants.resolveStorageUrl(path);

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
      statusBgColor =  AppColors.successBg;
      statusTextColor =  AppColors.success;
      statusDotColor =  AppColors.success;
      statusLabel = classmate.jamAbsen != null && classmate.jamAbsen!.isNotEmpty
          ? 'Hadir ${classmate.jamAbsen} WIB'
          : 'Hadir Hari Ini';
    } else if (isIzin) {
      statusBgColor =  AppColors.warningBg;
      statusTextColor =  AppColors.amberDeep;
      statusDotColor =  AppColors.warning;
      statusLabel = 'Izin';
    } else if (isSakit) {
      statusBgColor =  AppColors.infoBg;
      statusTextColor =  AppColors.primaryBlue;
      statusDotColor =  AppColors.info;
      statusLabel = 'Sakit';
    } else {
      statusBgColor =  AppColors.background;
      statusTextColor =  AppColors.textMuted;
      statusDotColor =  AppColors.textMuted;
      statusLabel = 'Belum Presensi';
    }

    final bannerUrl = _formatUrl(classmate.banner);
    final avatarUrl = _formatUrl(classmate.avatar);

    return Container(
      decoration:  BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //  1. Classmate Cover Banner (Identik Versi Web)
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 118,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildDefaultBanner(),
                    if (bannerUrl.isNotEmpty)
                      Image.network(
                        bannerUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.28),
                            Colors.transparent,
                            Colors.black.withOpacity(0.22),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
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

          //  2. Avatar & Status Badge (Overlapping Banner)
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
                      color: AppColors.surface,
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

          //  3. Info Siswa (Nama, Verified Badge, Username, Kelas)
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
                          color:  AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                     Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: AppColors.primaryBlue,
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
                        color:  AppColors.textMuted,
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration:  BoxDecoration(
                        color: AppColors.textQuaternary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      kelasNama.isNotEmpty ? kelasNama : 'SMKN 1 Beringin',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:  AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                //  4. Bio Quote Box (Identik Versi Web)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:  AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color:  AppColors.border),
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
                          ?  AppColors.textSecondary
                          :  AppColors.textMuted,
                      height: 1.45,
                    ),
                  ),
                ),

                //  5. Website / Portfolio Link (Jika ada)
                if (classmate.website != null &&
                    classmate.website!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _openWebsite(classmate.website!.trim()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color:  AppColors.infoBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color:  AppColors.infoBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(
                            CupertinoIcons.link,
                            size: 14,
                            color: AppColors.primaryBlue,
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
                                color:  AppColors.primaryBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                           Icon(
                            CupertinoIcons.arrow_up_right,
                            size: 11,
                            color: AppColors.primaryBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                //  6. Close Button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color:  AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:  AppColors.textSecondary,
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDeep,
            AppColors.primaryDeep,
            AppColors.primaryBlue.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: _BannerDotGridPainter(),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color:  AppColors.primaryBlue,
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

class _BannerDotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    const spacing = 16.0;
    for (double y = 8; y < size.height; y += spacing) {
      for (double x = 8; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
