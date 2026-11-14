import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C12. Simpan preferensi tema (light/dark/system) + notifikasi ke UI.
class ThemeService {
  static const _key = 'app_theme_mode';
  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    switch (raw) {
      case 'light':
        mode.value = ThemeMode.light;
        break;
      case 'dark':
        mode.value = ThemeMode.dark;
        break;
      default:
        mode.value = ThemeMode.system;
    }
  }

  static Future<void> set(ThemeMode m) async {
    mode.value = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, m.name);
  }
}
