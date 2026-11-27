import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/session_model.dart';

enum LocationIssue {
  none,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  inaccurate,
  mocked,
  outsideArea,
  unavailable,
}

class GeofenceResult {
  final bool isInside;
  final double distanceMeters;
  final bool isMocked;
  final bool verifiedByWifi;
  final bool geofencingDisabled;
  final LocationIssue issue;
  final Position? position;
  final String? errorMessage;

  GeofenceResult({
    required this.isInside,
    required this.distanceMeters,
    required this.isMocked,
    this.verifiedByWifi = false,
    this.geofencingDisabled = false,
    this.issue = LocationIssue.none,
    this.position,
    this.errorMessage,
  });

  double? get accuracyMeters => position?.accuracy;
}

class LocationService {
  static const MethodChannel _securityChannel =
      MethodChannel('id.sch.smknegeri1beringin.presensi/security');

  /// Toleransi jarak tepi poligon dalam meter (parity dengan Rust API & Laravel).
  static const double polygonEdgeToleranceMeters = 5.0;

  /// Usia maksimum fix GPS yang diizinkan (5 menit) agar koordinat basi tidak diterima.
  static const Duration maxGpsFixAge = Duration(minutes: 5);

  /// Deteksi Fake GPS / Mock Location lewat native Android (API 18+ / 31+).
  static Future<bool> isMockLocation() async {
    if (kIsWeb) return false;
    try {
      final result = await _securityChannel.invokeMethod<bool>('isMockLocation');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Alias kompatibilitas untuk `ScannerScreen` (deteksi Mock Location native Android).
  static Future<bool> isMockLocationNative() => isMockLocation();

  /// Ambil posisi GPS segar secara multi-tahap (dipakai oleh `ScannerScreen` saat submit scan).
  static Future<Position?> getCurrentPosition() => _acquireFreshPosition();

  static Future<bool> openLocationSettings() async {
    if (kIsWeb) return false;
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openAppSettings() async {
    if (kIsWeb) return false;
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Cek cepat tanpa memunculkan dialog izin apakah GPS aktif & izin sudah diberikan.
  static Future<bool> hasActivePermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// Stream GPS berkelanjutan agar chipset GPS tetap hangat & cepat terkunci
  /// tanpa cold-start berulang setiap 5 detik.
  static Stream<Position> positionStream({
    int distanceFilterMeters = 3,
    Duration androidInterval = const Duration(seconds: 4),
  }) {
    final LocationSettings settings =
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
            ? AndroidSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: distanceFilterMeters,
                intervalDuration: androidInterval,
              )
            : LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: distanceFilterMeters,
              );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Evaluasi murni apakah kebijakan lokasi mengizinkan scan (dipakai runtime & unit test).
  static bool scanLocationAllowed(bool geofencingActive, bool isMocked) {
    if (!geofencingActive) return true;
    return !isMocked;
  }

  /// Evaluasi murni kualitas & kesegaran fix GPS (dipakai runtime & unit test).
  static bool scanGpsAllowed({
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime timestamp,
    DateTime? now,
    double maxAccuracyMeters = 80.0,
  }) {
    if (!latitude.isFinite || !longitude.isFinite) return false;
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return false;
    }
    if (latitude.abs() < 1e-6 && longitude.abs() < 1e-6) return false;
    if (!accuracy.isFinite || accuracy <= 0 || accuracy > maxAccuracyMeters) {
      return false;
    }
    final current = now ?? DateTime.now();
    if (current.difference(timestamp) > maxGpsFixAge) return false;
    if (timestamp.difference(current) > const Duration(seconds: 30)) {
      return false;
    }
    return true;
  }

  /// Evaluasi murni satu pembacaan `Position` terhadap konfigurasi geofencing & jaringan.
  /// Dipakai bersama oleh `verifyGeofence()` dan stream GPS realtime.
  static GeofenceResult evaluatePosition(
    Position position,
    GeofenceConfig config, {
    NetworkConfig? networkConfig,
    bool isNativeMocked = false,
    DateTime? now,
  }) {
    final currentNow = now ?? DateTime.now();
    final isVerifiedWifi =
        networkConfig?.active == true && networkConfig?.isAllowed == true;
    final isMock = position.isMocked || isNativeMocked;

    if (isMock) {
      return GeofenceResult(
        isInside: false,
        distanceMeters: 0,
        isMocked: true,
        issue: LocationIssue.mocked,
        position: position,
        errorMessage:
            'Fake GPS / Mock Location terdeteksi! Nonaktifkan aplikasi pemalsu lokasi.',
      );
    }

    if (!config.active) {
      return GeofenceResult(
        isInside: true,
        distanceMeters: 0,
        isMocked: false,
        geofencingDisabled: true,
        issue: LocationIssue.none,
        position: position,
      );
    }

    final maxAccuracy = isVerifiedWifi ? 150.0 : 80.0;
    final isFresh = currentNow.difference(position.timestamp) <= maxGpsFixAge;

    if (!scanGpsAllowed(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
      now: currentNow,
      maxAccuracyMeters: maxAccuracy,
    )) {
      if (isVerifiedWifi) {
        return GeofenceResult(
          isInside: true,
          distanceMeters: 0,
          isMocked: false,
          verifiedByWifi: true,
          issue: LocationIssue.none,
          position: isFresh ? position : null,
        );
      }
      final accStr = position.accuracy.isFinite && position.accuracy > 0
          ? '±${position.accuracy.round()}m'
          : 'tidak terbaca';
      return GeofenceResult(
        isInside: false,
        distanceMeters: 0,
        isMocked: false,
        issue: LocationIssue.inaccurate,
        position: isFresh ? position : null,
        errorMessage: isFresh
            ? 'Sinyal GPS sedang menstabilkan ($accStr, maks ≤${maxAccuracy.toInt()}m). Geser ke area lebih terbuka.'
            : 'Koordinat GPS usang. Ketuk perbarui untuk mengunci sinyal terbaru.',
      );
    }

    final centerDistance = haversineDistance(
      position.latitude,
      position.longitude,
      config.latitude,
      config.longitude,
    );

    bool inside;
    double displayDistance = centerDistance;
    String? outsideMsg;

    if (config.mode == 'polygon' && config.polygonPoints.length >= 3) {
      inside = isPointAllowedInPolygon(
        position.latitude,
        position.longitude,
        config.polygonPoints,
      );
      if (!inside) {
        final edgeDist = distanceToPolygonEdge(
          position.latitude,
          position.longitude,
          config.polygonPoints,
        );
        displayDistance = edgeDist.isFinite ? edgeDist : centerDistance;
        outsideMsg =
            'Anda berada ${displayDistance.toStringAsFixed(0)}m di luar batas area sekolah';
      }
    } else {
      inside = centerDistance <= config.radiusMeters;
      if (!inside) {
        outsideMsg =
            'Anda berada ${centerDistance.toStringAsFixed(0)}m dari sekolah (Maks ${config.radiusMeters.toInt()}m)';
      }
    }

    if (!inside && isVerifiedWifi) {
      return GeofenceResult(
        isInside: true,
        distanceMeters: 0,
        isMocked: false,
        verifiedByWifi: true,
        issue: LocationIssue.none,
        position: position,
      );
    }

    return GeofenceResult(
      isInside: inside,
      distanceMeters: displayDistance,
      isMocked: false,
      issue: inside ? LocationIssue.none : LocationIssue.outsideArea,
      position: position,
      errorMessage: inside ? null : outsideMsg,
    );
  }

  /// Mendapatkan posisi GPS aktif dan validasi geofencing secara penuh.
  static Future<GeofenceResult> verifyGeofence(
    GeofenceConfig config, {
    NetworkConfig? networkConfig,
  }) async {
    final isVerifiedWifi =
        networkConfig?.active == true && networkConfig?.isAllowed == true;

    if (!config.active) {
      Position? optionalPos;
      try {
        if (await hasActivePermission()) {
          optionalPos = await Geolocator.getLastKnownPosition();
        }
      } catch (_) {}
      return GeofenceResult(
        isInside: true,
        distanceMeters: 0,
        isMocked: false,
        geofencingDisabled: true,
        issue: LocationIssue.none,
        position: optionalPos,
      );
    }

    if (networkConfig != null && networkConfig.blocksScan) {
      return GeofenceResult(
        isInside: false,
        distanceMeters: 0,
        isMocked: false,
        issue: LocationIssue.outsideArea,
        errorMessage:
            'Jaringan Anda tidak terdaftar. Hubungkan ke Wi-Fi resmi SMKN 1 Beringin.',
      );
    }

    bool serviceEnabled;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      serviceEnabled = false;
    }

    if (!serviceEnabled) {
      if (isVerifiedWifi) {
        return GeofenceResult(
          isInside: true,
          distanceMeters: 0,
          isMocked: false,
          verifiedByWifi: true,
          issue: LocationIssue.none,
        );
      }
      return GeofenceResult(
        isInside: false,
        distanceMeters: 0,
        isMocked: false,
        issue: LocationIssue.serviceDisabled,
        errorMessage: 'GPS belum aktif. Nyalakan Lokasi di perangkat Anda.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (isVerifiedWifi) {
          return GeofenceResult(
            isInside: true,
            distanceMeters: 0,
            isMocked: false,
            verifiedByWifi: true,
            issue: LocationIssue.none,
          );
        }
        return GeofenceResult(
          isInside: false,
          distanceMeters: 0,
          isMocked: false,
          issue: LocationIssue.permissionDenied,
          errorMessage: 'Izin lokasi diperlukan. Ketuk untuk mengizinkan GPS.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (isVerifiedWifi) {
        return GeofenceResult(
          isInside: true,
          distanceMeters: 0,
          isMocked: false,
          verifiedByWifi: true,
          issue: LocationIssue.none,
        );
      }
      return GeofenceResult(
        isInside: false,
        distanceMeters: 0,
        isMocked: false,
        issue: LocationIssue.permissionDeniedForever,
        errorMessage:
            'Izin lokasi diblokir. Aktifkan di Pengaturan Aplikasi.',
      );
    }

    final Position? position = await _acquireFreshPosition();

    if (position == null) {
      if (isVerifiedWifi) {
        return GeofenceResult(
          isInside: true,
          distanceMeters: 0,
          isMocked: false,
          verifiedByWifi: true,
          issue: LocationIssue.none,
        );
      }
      return GeofenceResult(
        isInside: false,
        distanceMeters: 0,
        isMocked: false,
        issue: LocationIssue.unavailable,
        errorMessage:
            'Gagal mengunci koordinat GPS. Geser ke area lebih terbuka lalu ketuk muat ulang.',
      );
    }

    final nativeMock = await isMockLocation();
    return evaluatePosition(
      position,
      config,
      networkConfig: networkConfig,
      isNativeMocked: nativeMock,
    );
  }

  /// Akuisisi GPS multi-tahap untuk Android: Fused -> LocationManager -> fresh cache (<= 5 menit).
  static Future<Position?> _acquireFreshPosition() async {
    final bool isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    // 1. Fused Location Provider (cepat: GPS + WiFi + Cell)
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: isAndroid
            ? AndroidSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 8),
              )
            : const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 8),
              ),
      );
    } catch (_) {}

    // 2. Fallback Android LocationManager jika GMS Fused sedang macet di ROM tertentu
    if (isAndroid) {
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.medium,
            forceLocationManager: true,
            timeLimit: const Duration(seconds: 5),
          ),
        );
      } catch (_) {}
    }

    // 3. Last known position HANYA jika masih segar (<= 5 menit)
    try {
      final cached = await Geolocator.getLastKnownPosition();
      if (cached != null &&
          DateTime.now().difference(cached.timestamp) <= maxGpsFixAge) {
        return cached;
      }
    } catch (_) {}

    return null;
  }

  /// Rumus Haversine jarak permukaan bumi dalam meter.
  static double haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double R = 6371000.0;
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLng = _deg2rad(lng2 - lng1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180.0);

  /// Ray-casting Point-in-Polygon (mirror `is_point_in_polygon` di Rust API).
  static bool isPointInPolygon(
      double lat, double lng, List<LatLngPoint> polygon) {
    if (polygon.length < 3) return false;
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].lat;
      final yi = polygon[i].lng;
      final xj = polygon[j].lat;
      final yj = polygon[j].lng;

      final intersect = ((yi > lng) != (yj > lng)) &&
          (lat < (xj - xi) * (lng - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
      j = i;
    }
    return inside;
  }

  /// Jarak terpendek titik ke sisi poligon dalam meter (proyeksi equirectangular lokal,
  /// mirror persis `distance_to_polygon_edge` di Rust API).
  static double distanceToPolygonEdge(
      double lat, double lng, List<LatLngPoint> polygon) {
    if (polygon.length < 3) return double.infinity;
    final cosLat = cos(_deg2rad(lat));
    const metersPerDegLat = 111320.0;
    final metersPerDegLng = 111320.0 * cosLat;

    double minDist = double.infinity;
    final n = polygon.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final ax = (polygon[i].lng - lng) * metersPerDegLng;
      final ay = (polygon[i].lat - lat) * metersPerDegLat;
      final bx = (polygon[j].lng - lng) * metersPerDegLng;
      final by = (polygon[j].lat - lat) * metersPerDegLat;

      final dx = bx - ax;
      final dy = by - ay;
      final lenSq = dx * dx + dy * dy;
      final t =
          lenSq > 0 ? ((-ax * dx - ay * dy) / lenSq).clamp(0.0, 1.0) : 0.0;
      final px = ax + t * dx;
      final py = ay + t * dy;
      final d = sqrt(px * px + py * py);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  /// Mirror aturan poligon Rust API & Laravel: titik valid bila di dalam poligon ATAU
  /// jaraknya ke tepi poligon <= 5 meter (`polygonEdgeToleranceMeters`).
  static bool isPointAllowedInPolygon(
    double lat,
    double lng,
    List<LatLngPoint> polygon,
  ) {
    if (isPointInPolygon(lat, lng, polygon)) return true;
    return distanceToPolygonEdge(lat, lng, polygon) <=
        polygonEdgeToleranceMeters;
  }
}
