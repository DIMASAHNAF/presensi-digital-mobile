import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//  APPLE iOS 18 HUMAN INTERFACE GUIDELINES
//  Brightness-aware palette: nilai Light dipertahankan, varian Dark ditambah.
//  `AppColors.configure(brightness)` dipanggil dari MaterialApp.builder sehingga
//  seluruh widget cukup memakai `AppColors.*` (getter) tanpa tahu modus aktif.

class _Palette {
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceElevated;
  final Color surfaceSecondary;
  final Color primaryBlue;
  final Color primaryNavy;
  final Color primaryIndigo;
  final Color success;
  final Color successBg;
  final Color successBorder;
  final Color warning;
  final Color warningBg;
  final Color warningBorder;
  final Color danger;
  final Color dangerBg;
  final Color dangerBorder;
  final Color info;
  final Color infoBg;
  final Color indigoBg;
  final Color textMain;
  final Color textSecondary;
  final Color textMuted;
  final Color textQuaternary;
  final Color border;
  final Color borderLight;
  final Color borderSubtle;
  final Color primaryDark;
  final Color primaryDeep;
  final Color shadow;
  final Color infoBorder;
  final Color amberDeep;
  final Color waGreen;

  const _Palette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceElevated,
    required this.surfaceSecondary,
    required this.primaryBlue,
    required this.primaryNavy,
    required this.primaryIndigo,
    required this.success,
    required this.successBg,
    required this.successBorder,
    required this.warning,
    required this.warningBg,
    required this.warningBorder,
    required this.danger,
    required this.dangerBg,
    required this.dangerBorder,
    required this.info,
    required this.infoBg,
    required this.indigoBg,
    required this.textMain,
    required this.textSecondary,
    required this.textMuted,
    required this.textQuaternary,
    required this.border,
    required this.borderLight,
    required this.borderSubtle,
    required this.primaryDark,
    required this.primaryDeep,
    required this.shadow,
    required this.infoBorder,
    required this.amberDeep,
    required this.waGreen,
  });
}

const _light = _Palette(
  background: Color(0xFFF2F2F7),
  surface: Color(0xFFFFFFFF),
  surfaceMuted: Color(0xFFE5E5EA),
  surfaceElevated: Color(0xFFFFFFFF),
  surfaceSecondary: Color(0xFFF2F2F7),
  primaryBlue: Color(0xFF007AFF),
  primaryNavy: Color(0xFF1C1C1E),
  primaryIndigo: Color(0xFF5856D6),
  success: Color(0xFF34C759),
  successBg: Color(0xFFE8F8ED),
  successBorder: Color(0xFFB0E8C0),
  warning: Color(0xFFFF9500),
  warningBg: Color(0xFFFFF4E6),
  warningBorder: Color(0xFFFFD699),
  danger: Color(0xFFFF3B30),
  dangerBg: Color(0xFFFFEBEB),
  dangerBorder: Color(0xFFFFBBBA),
  info: Color(0xFF5AC8FA),
  infoBg: Color(0xFFE6F7FF),
  indigoBg: Color(0xFFEFEBFF),
  textMain: Color(0xFF000000),
  textSecondary: Color(0xFF3C3C43),
  textMuted: Color(0xFF8E8E93),
  textQuaternary: Color(0xFFC7C7CC),
  border: Color(0xFFE5E5EA),
  borderLight: Color(0xFFE5E5EA),
  borderSubtle: Color(0xFFF2F2F7),
  primaryDark: Color(0xFF1C1C1E),
  primaryDeep: Color(0xFF1C1C1E),
  shadow: Color(0xFF1C1C1E),
  infoBorder: Color(0xFFCCE4FF),
  amberDeep: Color(0xFF8A6D1F),
  waGreen: Color(0xFF25D366),
);

const _dark = _Palette(
  background: Color(0xFF000000),
  surface: Color(0xFF1C1C1E),
  surfaceMuted: Color(0xFF2C2C2E),
  surfaceElevated: Color(0xFF1C1C1E),
  surfaceSecondary: Color(0xFF2C2C2E),
  primaryBlue: Color(0xFF0A84FF),
  primaryNavy: Color(0xFFF2F2F7),
  primaryIndigo: Color(0xFF5E5CE6),
  success: Color(0xFF30D158),
  successBg: Color(0xFF12331C),
  successBorder: Color(0xFF1E5B2E),
  warning: Color(0xFFFF9F0A),
  warningBg: Color(0xFF33260A),
  warningBorder: Color(0xFF66491A),
  danger: Color(0xFFFF453A),
  dangerBg: Color(0xFF33110F),
  dangerBorder: Color(0xFF66201D),
  info: Color(0xFF64D2FF),
  infoBg: Color(0xFF0A2433),
  indigoBg: Color(0xFF1F1B3A),
  textMain: Color(0xFFFFFFFF),
  textSecondary: Color(0xFFD1D1D6),
  textMuted: Color(0xFF98989D),
  textQuaternary: Color(0xFF48484A),
  border: Color(0xFF38383A),
  borderLight: Color(0xFF38383A),
  borderSubtle: Color(0xFF2C2C2E),
  primaryDark: Color(0xFFF2F2F7),
  primaryDeep: Color(0xFF2C2C2E),
  shadow: Color(0xFF000000),
  infoBorder: Color(0xFF1E3A5F),
  amberDeep: Color(0xFFFFD60A),
  waGreen: Color(0xFF25D366),
);

class AppColors {
  static Brightness _brightness = Brightness.light;

  /// Dipanggil sekali dari MaterialApp.builder.
  static void configure(Brightness brightness) {
    _brightness = brightness;
  }

  static bool get isDark => _brightness == Brightness.dark;

  static _Palette get _p => isDark ? _dark : _light;

  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceMuted => _p.surfaceMuted;
  static Color get surfaceElevated => _p.surfaceElevated;
  static Color get surfaceSecondary => _p.surfaceSecondary;

  static Color get primaryBlue => _p.primaryBlue;
  static Color get primaryNavy => _p.primaryNavy;
  static Color get primaryIndigo => _p.primaryIndigo;
  static Color get success => _p.success;
  static Color get successBg => _p.successBg;
  static Color get successBorder => _p.successBorder;
  static Color get warning => _p.warning;
  static Color get warningBg => _p.warningBg;
  static Color get warningBorder => _p.warningBorder;
  static Color get danger => _p.danger;
  static Color get dangerBg => _p.dangerBg;
  static Color get dangerBorder => _p.dangerBorder;
  static Color get info => _p.info;
  static Color get infoBg => _p.infoBg;
  static Color get indigoBg => _p.indigoBg;

  static Color get textMain => _p.textMain;
  static Color get textSecondary => _p.textSecondary;
  static Color get textMuted => _p.textMuted;
  static Color get textQuaternary => _p.textQuaternary;

  static Color get border => _p.border;
  static Color get borderLight => _p.borderLight;
  static Color get borderSubtle => _p.borderSubtle;
  static Color get primaryDark => _p.primaryDark;
  static Color get primaryDeep => _p.primaryDeep;
  static Color get shadow => _p.shadow;
  static Color get infoBorder => _p.infoBorder;
  static Color get amberDeep => _p.amberDeep;
  static Color get waGreen => _p.waGreen;

  static LinearGradient get appleCardGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF1C1C1E), Color(0xFF2C2C2E)]
            : const [Color(0xFFFFFFFF), Color(0xFFF2F2F7)],
      );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme => _theme(Brightness.light);
  static ThemeData get darkTheme => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textMain = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final textSecondary = isDark ? const Color(0xFFD1D1D6) : const Color(0xFF3C3C43);
    final textMuted = isDark ? const Color(0xFF98989D) : const Color(0xFF8E8E93);
    final background = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final surface = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
    final border = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
    final blue = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final indigo = isDark ? const Color(0xFF5E5CE6) : const Color(0xFF5856D6);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: blue,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: border,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: blue,
        secondary: indigo,
        surface: surface,
        error: const Color(0xFFFF3B30),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textMain,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textMain,
          letterSpacing: -0.8,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textMain,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textMain,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textMain,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textMain,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      ),
    );
  }
}
