import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stable per-install device identifier for anti-titip-absen binding.
class DeviceService {
  static const MethodChannel _channel =
      MethodChannel('id.sch.smknegeri1beringin.presensi/mock_location');
  static const _key = 'device_install_id';
  static const _storage = FlutterSecureStorage();

  static String? _cached;

  static Future<String> getDeviceId() async {
    if (_cached != null && _cached!.isNotEmpty) return _cached!;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final native = await _channel.invokeMethod<String>('getDeviceId');
        if (native != null && native.trim().isNotEmpty) {
          _cached = native.trim();
          return _cached!;
        }
      } catch (_) {}
    }

    try {
      final existing = await _storage.read(key: _key);
      if (existing != null && existing.isNotEmpty) {
        _cached = existing;
        return _cached!;
      }
    } catch (_) {}

    final generated = _randomId();
    try {
      await _storage.write(key: _key, value: generated);
    } catch (_) {}
    _cached = generated;
    return generated;
  }

  static String _randomId() {
    const chars = 'abcdef0123456789';
    final rnd = Random.secure();
    final buf = StringBuffer('dev-');
    for (var i = 0; i < 32; i++) {
      buf.write(chars[rnd.nextInt(chars.length)]);
    }
    return buf.toString();
  }
}
