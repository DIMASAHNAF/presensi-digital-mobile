import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simpan preferensi tema (default Light, sinkron dengan Presensi Web;
/// dapat diubah ke Dark atau Ikuti Sistem di menu Profil > Tampilan).
class ThemeService {
  static const _key = 'app_theme_mode';
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    switch (raw) {
      case 'dark':
        mode.value = ThemeMode.dark;
        break;
      case 'system':
        mode.value = ThemeMode.system;
        break;
      case 'light':
      default:
        mode.value = ThemeMode.light;
    }
  }

  static Future<void> set(ThemeMode m) async {
    mode.value = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, m.name);
  }
}
