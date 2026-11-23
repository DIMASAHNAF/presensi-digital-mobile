import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'storage_service.dart';
import 'telemetry_service.dart';

/// B7. Antrian presensi offline.
///
/// Sinyal di lingkungan sekolah tidak selalu stabil. Bila server tak terjangkau
/// saat siswa scan, paket presensi disimpan lokal lalu dikirim otomatis begitu
/// koneksi kembali — supaya presensi tidak hilang.
class ScanQueueService {
  static const String _key = 'pending_scan_queue_v1';
  static const int _maxItems = 20;

  static Timer? _timer;
  static bool _syncing = false;

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  /// Peristiwa yang disimpan lokal. `image` sudah dikompresi oleh pemanggil.
  static Future<void> enqueue({
    required String imageBase64,
    required double latitude,
    required double longitude,
    required double accuracy,
    required bool isMocked,
    int? gpsTimestampMs,
    int? sesiId,
    String? deviceId,
  }) async {
    try {
      final prefs = await _prefs();
      final list = prefs.getStringList(_key) ?? <String>[];
      list.add(jsonEncode({
        'image': imageBase64,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'isMocked': isMocked,
        'gpsTimestampMs': gpsTimestampMs,
        'sesiId': sesiId,
        'deviceId': deviceId,
        'createdAt': DateTime.now().toIso8601String(),
      }));
      // Buang yang paling lama bila melebihi batas.
      while (list.length > _maxItems) {
        list.removeAt(0);
      }
      await prefs.setStringList(_key, list);
      TelemetryService.event('scan_queued', detail: 'pending=${list.length}');
    } catch (_) {}
  }

  static Future<int> pendingCount() async {
    try {
      final prefs = await _prefs();
      return (prefs.getStringList(_key) ?? <String>[]).length;
    } catch (_) {
      return 0;
    }
  }

  /// Kirim antrian dari yang paling lama. Berhenti saat koneksi gagal agar
  /// urutan waktu tetap terjaga; membuang item yang ditolak permanen server.
  static Future<int> syncPending() async {
    if (_syncing) return 0;
    if (!StorageService.isLoggedIn()) return 0;
    _syncing = true;
    var sent = 0;
    try {
      final prefs = await _prefs();
      final list = prefs.getStringList(_key) ?? <String>[];

      for (var i = 0; i < list.length; i++) {
        final item = jsonDecode(list[i]) as Map<String, dynamic>;
        final res = await ApiService.submitFaceScan(
          imageBase64: item['image'] as String,
          latitude: (item['latitude'] as num).toDouble(),
          longitude: (item['longitude'] as num).toDouble(),
          accuracy: (item['accuracy'] as num).toDouble(),
          isMocked: item['isMocked'] == true,
          gpsTimestampMs: (item['gpsTimestampMs'] as num?)?.toInt(),
          sesiId: (item['sesiId'] as num?)?.toInt(),
          deviceId: item['deviceId'] as String?,
        );

        if (res.success) {
          list.removeAt(i);
          i--;
          sent++;
          continue;
        }
        if (res.offline) {
          break; // masih tanpa koneksi; coba lagi nanti
        }
        // Ditolak server: 4xx permanen -> buang; 5xx -> tahan untuk dicoba lagi.
        final code = res.statusCode ?? 0;
        if (code >= 400 && code < 500) {
          list.removeAt(i);
          i--;
          continue;
        }
        break;
      }

      await prefs.setStringList(_key, list);
      if (sent > 0) {
        TelemetryService.event('scan_synced', detail: 'sent=$sent');
      }
    } catch (_) {
    } finally {
      _syncing = false;
    }
    return sent;
  }

  /// Polling ringan saat aplikasi aktif.
  static void startAutoSync({Duration interval = const Duration(seconds: 60)}) {
    if (kIsWeb) return; // web selalu online; queue tak relevan
    if (_timer != null) return;
    _timer = Timer.periodic(interval, (_) async {
      if (await pendingCount() == 0) return;
      syncPending();
    });
  }

  static void stopAutoSync() {
    _timer?.cancel();
    _timer = null;
  }

  static bool get supportsOfflineQueue {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }
}
