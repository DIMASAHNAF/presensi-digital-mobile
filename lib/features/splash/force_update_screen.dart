import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

/// Layar wajib update ketika build aplikasi < min_build dari server.
class ForceUpdateScreen extends StatelessWidget {
  final bool blocking;
  final String? storeUrl;
  const ForceUpdateScreen({super.key, this.blocking = true, this.storeUrl});

  static const String defaultAndroidStoreUrl =
      'https://play.google.com/store/apps/details?id=id.sch.smknegeri1beringin.presensi';
  static const String defaultIosDownloadUrl =
      'https://presensi.smknegeri1beringin.sch.id';

  static String resolveUpdateUrl({
    String? storeUrl,
    required TargetPlatform platform,
    required bool isWeb,
  }) {
    if (storeUrl != null && storeUrl.trim().isNotEmpty) {
      return storeUrl.trim();
    }
    if (!isWeb && platform == TargetPlatform.iOS) {
      return defaultIosDownloadUrl;
    }
    return defaultAndroidStoreUrl;
  }

  static String resolveButtonLabel({
    required TargetPlatform platform,
    required bool isWeb,
  }) {
    if (!isWeb && platform == TargetPlatform.iOS) {
      return 'Unduh Versi Terbaru';
    }
    return 'Buka Play Store';
  }

  @override
  Widget build(BuildContext context) {
    final updateUrl = resolveUpdateUrl(
      storeUrl: storeUrl,
      platform: defaultTargetPlatform,
      isWeb: kIsWeb,
    );
    final buttonLabel = resolveButtonLabel(
      platform: defaultTargetPlatform,
      isWeb: kIsWeb,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrow_down_circle,
                    size: 72, color: AppColors.primaryBlue),
                const SizedBox(height: 24),
                Text(
                  'Perbarui Aplikasi',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  blocking
                      ? 'Versi aplikasi Anda sudah tidak didukung. Silakan perbarui untuk melanjutkan presensi.'
                      : 'Versi baru tersedia dengan perbaikan penting.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(14),
                    onPressed: () async {
                      final uri = Uri.tryParse(updateUrl);
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Text(buttonLabel,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
