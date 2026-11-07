import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  APPLE iOS 18 HUMAN INTERFACE GUIDELINES (LIGHT PALETTE)
//  Pure iOS System Grouped Canvas • White Cards • SF/Inter Typography
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppColors {
  // Apple iOS 18 System Light Palette
  static const Color background = Color(0xFFF2F2F7); // iOS System Grouped Background
  static const Color surface = Colors.white; // iOS Pure White Surface (Cards)
  static const Color surfaceMuted = Color(0xFFE5E5EA); // System Gray 5 (Separators/Subtle fills)
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF8FAFC); // Apple Card satin sheen

  // Apple System Accents
  static const Color primaryBlue = Color(0xFF007AFF); // Apple System Blue
  static const Color primaryNavy = Color(0xFF0F172A); // Apple Dark Navy for high contrast titles
  static const Color primaryIndigo = Color(0xFF5856D6); // Apple System Purple/Indigo
  static const Color success = Color(0xFF34C759); // Apple System Green
  static const Color successBg = Color(0xFFE8F8ED);
  static const Color successBorder = Color(0xFFB0E8C0);

  static const Color warning = Color(0xFFFF9500); // Apple System Orange
  static const Color warningBg = Color(0xFFFFF4E6);
  static const Color warningBorder = Color(0xFFFFD699);

  static const Color danger = Color(0xFFFF3B30); // Apple System Red
  static const Color dangerBg = Color(0xFFFFEBEB);
  static const Color dangerBorder = Color(0xFFFFBFBA);

  static const Color info = Color(0xFF5AC8FA); // Apple System Teal/Cyan
  static const Color infoBg = Color(0xFFE6F7FF);

  // Apple System Typography Colors
  static const Color textMain = Color(0xFF000000); // System Primary Label (Pure Black)
  static const Color textSecondary = Color(0xFF3C3C43); // System Secondary Label (~60% Black)
  static const Color textMuted = Color(0xFF8E8E93); // System Tertiary Label (Gray 1)
  static const Color textQuaternary = Color(0xFFC7C7CC); // System Quaternary Label (Gray 2)

  // Borders & Dividers
  static const Color border = Color(0xFFE5E5EA); // System Hairline Separator
  static const Color borderLight = Color(0xFFE5E5EA);
  static const Color borderSubtle = Color(0xFFF2F2F7);
  static const Color primaryDark = Color(0xFF0F172A);

  // Apple Gradients (Light & Subtle)
  static const LinearGradient appleCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FAFC),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      cardColor: AppColors.surface,
      dividerColor: AppColors.border,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryIndigo,
        surface: AppColors.surface,
        error: AppColors.danger,
        onSurface: AppColors.textMain,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textMain,
          letterSpacing: -0.8,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
