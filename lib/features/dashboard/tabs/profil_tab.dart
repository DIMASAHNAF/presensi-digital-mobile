import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/link.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/dashboard_full_model.dart';
import '../../../core/models/user_model.dart';
import '../dialogs/change_password_dialog.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/theme_service.dart';

class ProfilTab extends StatelessWidget {
  final DashboardFullModel data;
  final VoidCallback onLogout;
  final VoidCallback? onOpenEnrollment;
  final ValueChanged<UserModel>? onProfileUpdated;

  const ProfilTab({
    super.key,
    required this.data,
    required this.onLogout,
    this.onOpenEnrollment,
    this.onProfileUpdated,
  });

  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _openEdit(BuildContext context) {
    HapticFeedback.lightImpact();
    EditProfileDialog.show(
      context,
      user: data.user,
      onProfileUpdated: onProfileUpdated ?? (updatedUser) {},
    );
  }

  Widget _buildThemeTile(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.mode,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark ||
            (mode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);
        return _buildActionTile(
          icon: isDark ? CupertinoIcons.moon_stars_fill : CupertinoIcons.sun_max_fill,
          iconColor: AppColors.primaryIndigo,
          label: 'Tampilan',
          onTap: () => _openThemeSheet(context),
        );
      },
    );
  }

  void _openThemeSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Pilih Tampilan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
            ),
            for (final entry in const [
              (ThemeMode.system, 'Ikuti Sistem', CupertinoIcons.device_phone_portrait),
              (ThemeMode.light, 'Terang', CupertinoIcons.sun_max_fill),
              (ThemeMode.dark, 'Gelap', CupertinoIcons.moon_stars_fill),
            ])
              ListTile(
                leading: Icon(entry.$3, color: AppColors.primaryIndigo),
                title: Text(
                  entry.$2,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                trailing: ThemeService.mode.value == entry.$1
                    ? Icon(CupertinoIcons.checkmark_alt,
                        color: AppColors.primaryBlue)
                    : null,
                onTap: () {
                  ThemeService.set(entry.$1);
                  Navigator.of(ctx).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openChangePassword(BuildContext context) {
    HapticFeedback.lightImpact();
    ChangePasswordDialog.show(context);
  }

  void _launchWebsite(String url) async {
    final cleanUrl = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.parse(cleanUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _launchWhatsApp(String phone) async {
    var cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label disalin ke papan klip!',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.primaryDeep,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = data.user;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(left: 18, right: 18, top: 8, bottom: 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //  1. APPLE ID HERO CARD WITH CURVED WAVE BANNER
          _buildAppleIDHero(context, user)
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
              .scale(
                begin: const Offset(0.97, 0.97),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 16),

          //  2. DATA AKADEMIK & IDENTITAS SISWA (Matching Reference Photo)
          _buildDapodikAcademicCard(context, user)
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          //  3. NOTIFIKASI ORANG TUA (Stacked 2-Baris Anti-Tabrakan)
          _buildSectionHeader('NOTIFIKASI WHATSAPP ORANG TUA'),
          const SizedBox(height: 8),
          _buildWhatsAppNotificationCard(context, user),

          const SizedBox(height: 16),

          //  4. BIOMETRIK & KEAMANAN
          _buildSectionHeader('BIOMETRIK & KEAMANAN'),
          const SizedBox(height: 8),
          _buildGroupedCard([
            _buildTile(
              icon: CupertinoIcons.viewfinder,
              iconColor: user.isFaceEnrolled
                  ? AppColors.success
                  : AppColors.warning,
              label: 'Face ID Biometrik',
              value: user.isFaceEnrolled ? 'Aktif' : 'Belum Rekam',
              valueColor: user.isFaceEnrolled
                  ? AppColors.success
                  : AppColors.warning,
              onTap: !user.isFaceEnrolled ? onOpenEnrollment : null,
            ),
            _buildActionTile(
              icon: CupertinoIcons.lock_shield,
              iconColor:  AppColors.primaryBlue,
              label: 'Ubah Kata Sandi Akun',
              isLast: true,
              onTap: () => _openChangePassword(context),
            ),
          ]),

          const SizedBox(height: 16),

          //  5. AKSI AKUN (iOS Inset Group)
          _buildSectionHeader('PENGATURAN'),
          const SizedBox(height: 8),
          _buildGroupedCard([
            _buildThemeTile(context),
            _buildActionTile(
              icon: CupertinoIcons.pencil,
              iconColor:  AppColors.primaryBlue,
              label: 'Edit Profil Siswa',
              onTap: () => _openEdit(context),
            ),
            _buildActionTile(
              icon: CupertinoIcons.square_arrow_right,
              iconColor:  AppColors.danger,
              label: 'Keluar dari Akun',
              textColor:  AppColors.danger,
              isLast: true,
              onTap: onLogout,
            ),
          ]),

          const SizedBox(height: 24),

          // Footer
          Center(
            child: Text(
              'Portal Siswa • SMK Negeri 1 Beringin',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color:  AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  1. APPLE ID HERO CARD WITH CURVED WAVE BANNER

  Widget _buildAppleIDHero(BuildContext context, UserModel user) {
    final bannerUrl = ApiConstants.resolveStorageUrl(user.banner);
    final hasBanner = bannerUrl.isNotEmpty;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color:  AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color:  AppColors.shadow.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          //  Wave Curved Header Banner
          ClipPath(
            clipper: _ProfileWaveClipper(),
            child: Container(
              height: 125,
              width: double.infinity,
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasBanner)
                    Image.network(
                      bannerUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.40),
                          Colors.transparent,
                          Colors.black.withOpacity(0.35),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Top Pill inside Banner
                  Positioned(
                    top: 12,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: user.isFaceEnrolled ? AppColors.success :  AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            user.isFaceEnrolled ? 'Face ID Aktif' : 'Belum Wajah',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Edit Profile Top Right
                  Positioned(
                    top: 10,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _openEdit(context),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.pencil, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Edit Profil',
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
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                //  Circular avatar (anti-aliased clip)
                Transform.translate(
                  offset: const Offset(0, -38),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:  AppColors.background,
                          border: Border.all(color: Colors.white, width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.14),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        child: ClipOval(
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: ApiConstants.resolveStorageUrl(user.avatar).isNotEmpty
                              ? Image.network(
                                  ApiConstants.resolveStorageUrl(user.avatar),
                                  fit: BoxFit.cover,
                                  width: 86,
                                  height: 86,
                                  errorBuilder: (_, __, ___) => _buildFallback(user),
                                )
                              : _buildFallback(user),
                        ),
                      ),
                      if (user.isFaceEnrolled)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color:  AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.2),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Column(
                    children: [
                      // Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _toTitleCase(user.nama),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color:  AppColors.primaryDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                           Icon(
                            Icons.verified_rounded,
                            color: AppColors.primaryBlue,
                            size: 17,
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Siswa Aktif • SMKN 1 Beringin',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:  AppColors.textMuted,
                        ),
                      ),

                      // Website / Portfolio chip (Clickable with Link widget)
                      if (user.website != null && user.website!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Link(
                          uri: Uri.parse(user.website!.startsWith('http')
                              ? user.website!
                              : 'https://${user.website!}'),
                          target: LinkTarget.blank,
                          builder: (context, followLink) => MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                if (followLink != null) {
                                  followLink();
                                } else {
                                  _launchWebsite(user.website!);
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color:  AppColors.infoBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color:  AppColors.infoBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                     Icon(
                                      CupertinoIcons.link,
                                      size: 12,
                                      color: AppColors.primaryBlue,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        user.website!,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color:  AppColors.primaryBlue,
                                          decoration: TextDecoration.underline,
                                          decorationColor:  AppColors.primaryBlue,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                     Icon(
                                      Icons.open_in_new_rounded,
                                      size: 11,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  //  2. DAPODIK ACADEMIC IDENTITY CARD (Photo 1 Reference)

  Widget _buildDapodikAcademicCard(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color:  AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color:  AppColors.shadow.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DATA AKADEMIK & IDENTITAS',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DAPODIK',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2 Columns: Kelas & Rombel | NISN Nasional (Equal Height)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Column 1: Kelas
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:  AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color:  AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KELAS & ROMBEL',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color:  AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.kelas,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color:  AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.kelas.contains('PPLG')
                              ? 'Pengembangan Perangkat Lunak & Gim'
                              : 'Kejuruan SMKN 1 Beringin',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color:  AppColors.primaryBlue,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Column 2: NISN
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:  AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color:  AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'NISN NASIONAL',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _copyToClipboard(context, user.nisn, 'NISN'),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      'Salin',
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.nisn,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color:  AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ID Siswa Kemendikbud',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color:  AppColors.textMuted,
                          ),
                        ),
                      ],
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

  //  HELPERS & STYLED WIDGETS

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color:  AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildWhatsAppNotificationCard(BuildContext context, UserModel user) {
    final namaOrtu = (user.namaOrtu != null && user.namaOrtu!.isNotEmpty)
        ? user.namaOrtu!
        : 'Belum diatur';
    final noHpOrtu = (user.noHpOrtu != null && user.noHpOrtu!.isNotEmpty)
        ? user.noHpOrtu!
        : 'Belum diatur';
    final hasPhone = user.noHpOrtu != null && user.noHpOrtu!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color:  AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color:  AppColors.shadow.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Row 1: Nama Orang Tua / Wali
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:  AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:  Icon(
                  CupertinoIcons.person_crop_circle_badge_checkmark,
                  size: 20,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama Orang Tua / Wali',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color:  AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      namaOrtu,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color:  AppColors.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
           Divider(height: 1, indent: 52, color: AppColors.background),
          const SizedBox(height: 12),

          // Row 2: Nomor WhatsApp Terdaftar
          InkWell(
            onTap: hasPhone ? () => _launchWhatsApp(user.noHpOrtu!) : () => _openEdit(context),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:  AppColors.successBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const WhatsAppBrandIcon(size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nomor WhatsApp Terdaftar',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color:  AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        noHpOrtu,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: hasPhone ?  AppColors.success :  AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                 Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
           Divider(height: 1, color: AppColors.background),
          const SizedBox(height: 12),

          // Row 3: Tombol Kirim Pesan Uji Coba ke WhatsApp Wali
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
              color:  AppColors.successBg,
              borderRadius: BorderRadius.circular(14),
              onPressed: () {
                HapticFeedback.lightImpact();
                if (hasPhone) {
                  _launchWhatsApp(user.noHpOrtu!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Silakan lengkapi nomor WhatsApp Orang Tua terlebih dahulu.',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: AppColors.primaryDeep,
                    ),
                  );
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const WhatsAppBrandIcon(size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Uji Pesan ke WhatsApp Wali',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color:  AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color:  AppColors.shadow.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    Widget? leadingWidget,
    IconData? icon,
    Color? iconColor,
    required String label,
    required String value,
    Color? valueColor,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                if (leadingWidget != null)
                  leadingWidget
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (iconColor ??  AppColors.primaryBlue).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon ?? Icons.circle, size: 16, color: iconColor ??  AppColors.primaryBlue),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: valueColor ?? AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(width: 6),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
           Divider(height: 1, indent: 60, color: AppColors.background),
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
           Divider(height: 1, indent: 60, color: AppColors.background),
      ],
    );
  }

  Widget _buildFallback(UserModel user) {
    return Container(
      color:  AppColors.primaryBlue,
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

//  CURVED WAVE CLIPPER FOR PROFILE HEADER (Reference: Photo 5)

class _ProfileWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 24);
    // Smooth natural wave dipping and rising
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.55,
      size.height - 14,
    );
    path.quadraticBezierTo(
      size.width * 0.82,
      size.height - 28,
      size.width,
      size.height - 18,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

//  OFFICIAL WHATSAPP BRAND BADGE

class WhatsAppBrandIcon extends StatelessWidget {
  final double size;
  const WhatsAppBrandIcon({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:  AppColors.waGreen,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color:  AppColors.waGreen.withOpacity(0.30),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.70,
          height: size * 0.70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Chat bubble tail at bottom-left
              Positioned(
                bottom: 1.5,
                left: 1.5,
                child: Transform.rotate(
                  angle: -0.65,
                  child: Container(
                    width: size * 0.22,
                    height: size * 0.22,
                    decoration:  BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              // Main white round speech bubble
              Container(
                width: size * 0.60,
                height: size * 0.60,
                decoration:  BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.phone_rounded,
                    size: size * 0.38,
                    color:  AppColors.waGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
