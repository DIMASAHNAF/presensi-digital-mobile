  import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:geolocator/geolocator.dart';
import '../models/session_model.dart';

class GeofenceResult {
  final bool isInside;
  final double distanceMeters;
  final bool isMocked;
  final Position? position;
  final String? errorMessage;

  bool get isInsideRadius => isInside;

  GeofenceResult({
    required this.isInside,
    required this.distanceMeters,
    required this.isMocked,
    this.position,
    this.errorMessage,
  });
}

class LocationService {
  static const MethodChannel _mockChannel =
      MethodChannel('id.sch.smknegeri1beringin.presensi/mock_location');

  /// Deteksi lokasi palsu via sinyal native Android (API 18+ / 31+ + developer
  /// options). Di iOS/web tidak ada padanan langsung → false (andalkan
  /// `Position.isMocked` dari geolocator).
  static Future<bool> isMockLocationNative() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final res = await _mockChannel.invokeMethod<bool>('isMockLocation');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Request GPS permission and verify location services are enabled
  static Future<bool> ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current GPS position with high accuracy.
  /// Returns null on failure; callers use [lastError] for the reason.
  static String? lastError;

  static Future<Position?> getCurrentPosition() async {
    lastError = null;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        lastError = kIsWeb
            ? 'Layanan lokasi browser tidak aktif. Aktifkan izin lokasi di pengaturan situs.'
            : 'GPS perangkat tidak aktif. Nyalakan Lokasi lalu coba lagi.';
        return null;
      }

      final hasPermission = await ensurePermission();
      if (!hasPermission) {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.deniedForever) {
          lastError = kIsWeb
              ? 'Izin lokasi diblokir permanen. Buka pengaturan situs browser dan izinkan Lokasi.'
              : 'Izin lokasi diblokir permanen. Aktifkan di Pengaturan > Aplikasi > Izin.';
        } else {
          lastError = 'Izin lokasi diperlukan untuk memverifikasi kehadiran.';
        }
        return null;
      }

      // Web GPS (browser) sering perlu waktu lebih lama & butuh HTTPS.
      const timeout =
          kIsWeb ? Duration(seconds: 25) : Duration(seconds: 12);
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: timeout,
        ),
      );
    } catch (_) {
      lastError = kIsWeb
          ? 'Gagal membaca lokasi. Pastikan situs diakses via HTTPS dan izin lokasi diizinkan.'
          : 'Gagal membaca sinyal GPS. Coba di area terbuka.';
      return null;
    }
  }

  /// Check if user location satisfies Geofencing rules (Polygon ray-casting or Radius fallback)
  static Future<GeofenceResult> verifyGeofence(GeofenceConfig config) async {
    if (!config.active) {
      return GeofenceResult(
        isInside: true,
        distanceMeters: 0,
        isMocked: false,
      );
    }

    final pos = await getCurrentPosition();
    if (pos == null) {
      return GeofenceResult(
        isInside: false,
        distanceMeters: 9999,
        isMocked: false,
        errorMessage: lastError ??
            'Gagal mendapatkan sinyal GPS. Pastikan lokasi aktif dan izin diberikan.',
      );
    }

    // Anti-Mock GPS check (geolocator flag + native Android detector)
    final nativeMock = await isMockLocationNative();
    if (pos.isMocked || nativeMock) {
      return GeofenceResult(
        isInside: false,
        distanceMeters: 9999,
        isMocked: true,
        position: pos,
        errorMessage: 'Terdeteksi aplikasi Lokasi Palsu (Fake GPS / Mock Location). Matikan untuk melanjutkan.',
      );
    }

    // Accuracy threshold check (reject GPS accuracy worse than 80m)
    if (pos.accuracy > 80.0) {
      return GeofenceResult(
        isInside: false,
        distanceMeters: 9999,
        isMocked: false,
        position: pos,
        errorMessage: 'Akurasi GPS rendah (${pos.accuracy.toInt()}m). Pindah ke ruang terbuka.',
      );
    }

    double distanceToCenter = haversineDistance(
      pos.latitude,
      pos.longitude,
      config.latitude,
      config.longitude,
    );

    // If mode is polygon and points exist, use Ray-Casting Point-In-Polygon
    if (config.mode.toLowerCase() == 'polygon' && config.polygonPoints.isNotEmpty) {
      bool inside = isPointInPolygon(pos.latitude, pos.longitude, config.polygonPoints);
      return GeofenceResult(
        isInside: inside,
        distanceMeters: distanceToCenter,
        isMocked: false,
        position: pos,
        errorMessage: inside ? null : 'Anda berada di luar area polygon SMK Negeri 1 Beringin.',
      );
    }

    // Fallback: Radial Geofence
    bool insideRadius = distanceToCenter <= config.radiusMeters;
    return GeofenceResult(
      isInside: insideRadius,
      distanceMeters: distanceToCenter,
      isMocked: false,
      position: pos,
      errorMessage: insideRadius
          ? null
          : 'Jarak Anda (${distanceToCenter.toStringAsFixed(1)}m) melebihi batas radius (${config.radiusMeters.toInt()}m).',
    );
  }

  /// Ray-Casting algorithm for Point-In-Polygon
  /// Identical to the Golang and Laravel implementation
  static bool isPointInPolygon(double lat, double lng, List<LatLngPoint> polygon) {
    int n = polygon.length;
    if (n < 3) return false;

    bool inside = false;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      double xi = polygon[i].lat;
      double yi = polygon[i].lng;
      double xj = polygon[j].lat;
      double yj = polygon[j].lng;

      bool intersect = ((yi > lng) != (yj > lng)) &&
          (lat < (xj - xi) * (lng - yi) / (yj - yi) + xi);

      if (intersect) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Haversine distance in meters
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // in meters
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) => degree * pi / 180;
}

