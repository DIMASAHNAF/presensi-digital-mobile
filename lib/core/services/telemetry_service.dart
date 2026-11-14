import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../constants/app_version.dart';
import 'storage_service.dart';

/// B10. Pelaporan crash ringan + analytics ke endpoint sendiri (`/telemetry`).
///
/// Tidak memakai SDK pihak ketiga: satu endpoint, satu tabel. Cukup untuk tahu
/// bug apa yang muncul di lapangan (contoh: `cameraNotReadable`).
class TelemetryService {
  static final http.Client _client = http.Client();

  static String get _platform {
    if (kIsWeb) return 'web';
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }

  /// Kirim satu peristiwa. Tidak pernah melempar â€” telemetry tak boleh
  /// merusak alur aplikasi.
  static Future<void> send({
    required String kind, // 'error' | 'event'
    required String category,
    String? message,
    String? stack,
  }) async {
    try {
      final token = StorageService.getToken();
      final payload = <String, dynamic>{
        'kind': kind,
        'category': category,
        'message': message,
        'stack': stack,
        'app_build': kAppBuild,
        'app_version': kAppVersionName,
        'platform': _platform,
      };
      await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}/telemetry'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Diamkan: kegagalan telemetry tidak boleh mengganggu pengguna.
    }
  }

  static void report(String category, Object error, [StackTrace? stack]) {
    send(
      kind: 'error',
      category: category,
      message: error.toString(),
      stack: stack?.toString(),
    );
  }

  static void event(String category, {String? detail}) {
    send(kind: 'event', category: category, message: detail);
  }

  /// Pasang handler global: error Flutter framework + error async tak tertangkap.
  static void install() {
    final prev = FlutterError.onError;
    FlutterError.onError = (details) {
      report('flutter', details.exception, details.stack);
      prev?.call(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      report('async', error, stack);
      return true;
    };
  }
}
