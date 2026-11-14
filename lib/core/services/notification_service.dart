import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import 'storage_service.dart';

/// C14. Notifikasi kotak masuk siswa (izin/sakit + keterlambatan).
class AppNotification {
  final String id;
  final String category; // izin | late
  final String tone; // success | danger | warning | info
  final String title;
  final String body;
  final String time;

  const AppNotification({
    required this.id,
    required this.category,
    required this.tone,
    required this.title,
    required this.body,
    required this.time,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        tone: (j['tone'] ?? 'info').toString(),
        title: (j['title'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        time: (j['time'] ?? '').toString(),
      );
}

class NotificationService {
  static final http.Client _client = http.Client();

  /// Ambil daftar notifikasi dari server.
  static Future<List<AppNotification>> fetch() async {
    try {
      final token = StorageService.getToken();
      final res = await _client.get(
        Uri.parse(ApiConstants.notifications),
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (body['notifications'] as List<dynamic>? ?? []);
      return list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static const _seenKey = 'seen_notification_ids_v1';

  /// Jumlah notifikasi yang belum pernah dibuka (untuk badge lonceng).
  static Future<int> unreadCount() async {
    final items = await fetch();
    if (items.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getStringList(_seenKey) ?? []).toSet();
    return items.where((e) => !seen.contains(e.id)).length;
  }
}
