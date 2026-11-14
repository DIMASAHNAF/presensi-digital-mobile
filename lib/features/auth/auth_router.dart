import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/models/user_model.dart';
import '../dashboard/dashboard_screen.dart';
import '../enrollment/enroll_wajah_screen.dart';
import 'onboarding_password_screen.dart';

/// Urutan langkah penyiapan akun siswa.
enum AuthStep {
  /// Wajib ganti password baru (akun belum mengubah password default).
  setPassword,

  /// Wajib merekam biometrik wajah.
  enrollFace,

  /// Akun siap — langsung ke dashboard.
  dashboard,
}

/// Tentukan langkah onboarding berikutnya (pure, mudah dites).
AuthStep resolveAuthStep(UserModel user) {
  if (!user.hasChangedPassword) return AuthStep.setPassword;
  if (!user.isFaceEnrolled) return AuthStep.enrollFace;
  return AuthStep.dashboard;
}

/// Bangun layar tujuan berdasarkan langkah onboarding.
Widget buildAuthDestination(AuthStep step, UserModel user) {
  switch (step) {
    case AuthStep.setPassword:
      return OnboardingPasswordScreen(user: user);
    case AuthStep.enrollFace:
      return const EnrollWajahScreen(isOnboarding: true);
    case AuthStep.dashboard:
      return const DashboardScreen();
  }
}
