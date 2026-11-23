import 'package:shared_preferences/shared_preferences.dart';

/// Identitas sekolah yang dipakai sebelum dashboard termuat (splash, login,
/// register). Nilai terbaru diambil dari `geofencing.school_name` pada payload
/// dashboard, sehingga satu build aplikasi bisa menampilkan nama sekolah yang
/// berbeda tanpa mengubah kode.
class SchoolBranding {
  static const String _key = 'school_branding_name_v1';
  static const String _fallback = 'SMK Negeri 1 Beringin';

  static String _name = _fallback;

  static String get name => _name;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key)?.trim();
    if (stored != null && stored.isNotEmpty) {
      _name = stored;
    }
  }

  static Future<void> update(String? schoolName) async {
    final clean = schoolName?.trim();
    if (clean == null || clean.isEmpty || clean == _name) return;
    _name = clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, clean);
  }
}
