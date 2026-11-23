import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_full_model.dart';

/// Snapshot dashboard terakhir yang berhasil dimuat dari server.
///
/// Dipakai sebagai fallback saat perangkat kehilangan koneksi, supaya siswa
/// tetap bisa melihat data terakhir (dengan penanda "data tersimpan") alih-alih
/// layar error. Cache dibersihkan saat logout agar tidak bocor ke akun lain.
class DashboardCache {
  static const String _keyPayload = 'dashboard_cache_payload_v1';
  static const String _keySavedAt = 'dashboard_cache_saved_at_v1';

  static Future<void> save(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPayload, jsonEncode(payload));
    await prefs.setInt(_keySavedAt, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<CachedDashboard?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPayload);
    final savedAtMs = prefs.getInt(_keySavedAt);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return CachedDashboard(
        model: DashboardFullModel.fromJson(decoded),
        savedAt: savedAtMs != null
            ? DateTime.fromMillisecondsSinceEpoch(savedAtMs)
            : DateTime.now(),
      );
    } catch (_) {
      // Cache rusak / format berubah: abaikan dan hapus agar tidak dipakai.
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPayload);
    await prefs.remove(_keySavedAt);
  }
}

class CachedDashboard {
  final DashboardFullModel model;
  final DateTime savedAt;

  const CachedDashboard({required this.model, required this.savedAt});
}
