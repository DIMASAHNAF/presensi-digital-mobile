import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:geolocator/geolocator.dart';
import '../models/session_model.dart';

enum LocationIssue {
  none,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  mocked,
  lowAccuracy,
  outsideArea,
}

class GeofenceResult {
  final bool isInside;
  final double distanceMeters;
  final bool isMocked;
  final bool verifiedByWifi;
  final LocationIssue issue;
  final Position? position;
  final String? errorMessage;

  bool get isInsideRadius => isInside;

  GeofenceResult({
    required this.isInside,
    required this.distanceMeters,
    required this.isMocked,
    this.verifiedByWifi = false,
    this.issue = LocationIssue.none,
    this.position,
    this.errorMessage,
  });
}

class LocationService {
  static const double polygonEdgeToleranceMeters = 5.0;
  static const double _metersPerDegLat = 110574.0;

  static bool scanLocationAllowed(bool geofenceActive, bool isMocked) =>
      !geofenceActive || !isMocked;

  static bool scanGpsAllowed({
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime timestamp,
    required DateTime now,
    double maxAccuracyMeters = 80.0,
  }) =>
      latitude.isFinite &&
      latitude >= -11.5 &&
      latitude <= 6.5 &&
      longitude.isFinite &&
      longitude >= 94.5 &&
      longitude <= 141.5 &&
      accuracy.isFinite &&
      accuracy > 0 &&
      accuracy <= maxAccuracyMeters &&
      !timestamp.isBefore(now.subtract(const Duration(minutes: 5))) &&
      !timestamp.isAfter(now.add(const Duration(seconds: 30)));

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
  /// Returns null on failure; callers use [lastError] and [lastIssue] for the reason.
  static String? lastError;
  static LocationIssue lastIssue = LocationIssue.none;

  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();

  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  static Future<Position?> getCurrentPosition() async {
    lastError = null;
    lastIssue = LocationIssue.none;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        lastIssue = LocationIssue.serviceDisabled;
        lastError = kIsWeb
            ? 'Layanan lokasi browser tidak aktif. Aktifkan izin lokasi di pengaturan situs.'
            : 'GPS perangkat tidak aktif. Nyalakan Lokasi lalu coba lagi.';
        return null;
      }

      final hasPermission = await ensurePermission();
      if (!hasPermission) {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.deniedForever) {
          lastIssue = LocationIssue.permissionDeniedForever;
          lastError = kIsWeb
              ? 'Izin lokasi diblokir permanen. Buka pengaturan situs browser dan izinkan Lokasi.'
              : 'Izin lokasi diblokir permanen. Aktifkan di Pengaturan > Aplikasi > Izin.';
        } else {
          lastIssue = LocationIssue.permissionDenied;
          lastError = 'Izin lokasi diperlukan untuk memverifikasi kehadiran.';
        }
        return null;
      }

      const timeout = kIsWeb ? Duration(seconds: 25) : Duration(seconds: 12);
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: timeout,
        ),
      );
    } catch (_) {
      lastIssue = LocationIssue.lowAccuracy;
      lastError = kIsWeb
          ? 'Gagal membaca lokasi. Pastikan situs diakses via HTTPS dan izin lokasi diizinkan.'
          : 'Gagal membaca sinyal GPS. Coba di area terbuka.';
      return null;
    }
  }

  /// Check if user location satisfies Geofencing rules (Polygon ray-casting + 5m edge tolerance,
  /// Radius fallback, or verified school WiFi fallback matching Rust API & Laravel Web).
  static Future<GeofenceResult> verifyGeofence(
    GeofenceConfig config, {
    NetworkConfig? networkConfig,
  }) async {
    if (!config.active) {
      return GeofenceResult(
        isInside: true,
        distanceMeters: 0,
        isMocked: false,
      );
    }

    final bool schoolWifiVerified =
        networkConfig != null && networkConfig.active && networkConfig.isAllowed;
    final double maxAccuracyMeters = schoolWifiVerified ? 150.0 : 80.0;

    final pos = await getCurrentPosition();
    if (pos == null) {
      if (schoolWifiVerified) {
        final nativeMock = await isMockLocationNative();
        if (nativeMock) {
          return GeofenceResult(
            isInside: false,
            distanceMeters: 9999,
            isMocked: true,
            issue: LocationIssue.mocked,
            errorMessage:
                'Terdeteksi aplikasi Lokasi Palsu (Fake GPS / Mock Location). Matikan untuk melanjutkan.',
          );
        }
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
        distanceMeters: 9999,
        isMocked: false,
        issue: lastIssue == LocationIssue.none
            ? LocationIssue.lowAccuracy
            : lastIssue,
        errorMessage: lastError ??
            'Gagal mendapatkan sinyal GPS. Pastikan lokasi aktif dan izin diberikan.',
      );
    }

    // Anti-Mock GPS check (geolocator flag + native Android detector)
    final nativeMock = await isMockLocationNative();
    if (!scanLocationAllowed(config.active, pos.isMocked || nativeMock)) {
      return GeofenceResult(
        isInside: false,
        distanceMeters: 9999,
        isMocked: true,
        issue: LocationIssue.mocked,
        position: pos,
        errorMessage:
            'Terdeteksi aplikasi Lokasi Palsu (Fake GPS / Mock Location). Matikan untuk melanjutkan.',
      );
    }

    // Accuracy threshold check (80m GPS satelit, 150m saat terhubung WiFi resmi sekolah)
    if (pos.accuracy > maxAccuracyMeters) {
      return GeofenceResult(
        isInside: false,
        distanceMeters: 9999,
        isMocked: false,
        issue: LocationIssue.lowAccuracy,
        position: pos,
        errorMessage:
            'Akurasi GPS rendah (${pos.accuracy.toInt()}m, batas ${maxAccuracyMeters.toInt()}m). Pindah ke ruang terbuka.',
      );
    }

    final double distanceToCenter = haversineDistance(
      pos.latitude,
      pos.longitude,
      config.latitude,
      config.longitude,
    );

    if (!scanGpsAllowed(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      timestamp: pos.timestamp,
      now: DateTime.now(),
      maxAccuracyMeters: maxAccuracyMeters,
    )) {
      return GeofenceResult(
        isInside: false,
        distanceMeters: 9999,
        isMocked: false,
        issue: LocationIssue.lowAccuracy,
        position: pos,
        errorMessage:
            'Lokasi GPS basi atau koordinat tidak valid. Refresh lokasi lalu coba lagi.',
      );
    }

    // If mode is polygon and points exist, use Ray-Casting + 5m fence edge tolerance
    if (config.mode.toLowerCase() == 'polygon' &&
        config.polygonPoints.length >= 3) {
      final bool inside = isPointAllowedInPolygon(
        pos.latitude,
        pos.longitude,
        config.polygonPoints,
      );
      return GeofenceResult(
        isInside: inside,
        distanceMeters: distanceToCenter,
        isMocked: false,
        issue: inside ? LocationIssue.none : LocationIssue.outsideArea,
        position: pos,
        errorMessage: inside
            ? null
            : 'Anda berada di luar area polygon ${config.schoolName}.',
      );
    }

    // Fallback: Radial Geofence
    final bool insideRadius = distanceToCenter <= config.radiusMeters;
    return GeofenceResult(
      isInside: insideRadius,
      distanceMeters: distanceToCenter,
      isMocked: false,
      issue: insideRadius ? LocationIssue.none : LocationIssue.outsideArea,
      position: pos,
      errorMessage: insideRadius
          ? null
          : 'Jarak Anda (${distanceToCenter.toStringAsFixed(1)}m) melebihi batas radius (${config.radiusMeters.toInt()}m).',
    );
  }

  /// Checks whether a point is inside the polygon OR within [toleranceMeters] (default 5m)
  /// of its nearest fence edge, matching `presensi-rust-api` (`geofence-rs`) and Laravel Web.
  static bool isPointAllowedInPolygon(
    double lat,
    double lng,
    List<LatLngPoint> polygon, {
    double toleranceMeters = polygonEdgeToleranceMeters,
  }) {
    if (polygon.length < 3) return false;
    if (isPointInPolygon(lat, lng, polygon)) return true;
    return distanceToPolygonEdge(lat, lng, polygon) <= toleranceMeters;
  }

  /// Shortest perpendicular distance in meters from `(lat, lng)` to the nearest polygon edge.
  /// Identical to `geofence-rs` (`DistanceToPolygonEdge`) and Laravel `SchoolSetting::distanceToPolygonEdge`.
  static double distanceToPolygonEdge(
    double lat,
    double lng,
    List<LatLngPoint> polygon,
  ) {
    final int n = polygon.length;
    if (n < 2) return 0.0;

    final double metersPerDegLng = 111320.0 * cos(_toRadians(lat));
    double best = double.maxFinite;

    for (int i = 0; i < n; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % n];

      final double x1 = (p1.lng - lng) * metersPerDegLng;
      final double y1 = (p1.lat - lat) * _metersPerDegLat;
      final double x2 = (p2.lng - lng) * metersPerDegLng;
      final double y2 = (p2.lat - lat) * _metersPerDegLat;

      final double dx = x2 - x1;
      final double dy = y2 - y1;
      final double lengthSq = dx * dx + dy * dy;

      final double dist;
      if (lengthSq <= 0.0001) {
        dist = sqrt(x1 * x1 + y1 * y1);
      } else {
        final double t = (-(x1 * dx + y1 * dy) / lengthSq).clamp(0.0, 1.0);
        final double px = x1 + t * dx;
        final double py = y1 + t * dy;
        dist = sqrt(px * px + py * py);
      }
      if (dist < best) {
        best = dist;
      }
    }
    return best;
  }

  /// Ray-Casting algorithm for Point-In-Polygon
  /// Identical to Rust (`geofence-rs`) and Laravel implementation
  static bool isPointInPolygon(
      double lat, double lng, List<LatLngPoint> polygon) {
    final int n = polygon.length;
    if (n < 3) return false;

    bool inside = false;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final double xi = polygon[i].lat;
      final double yi = polygon[i].lng;
      final double xj = polygon[j].lat;
      final double yj = polygon[j].lng;

      final bool intersect = ((yi > lng) != (yj > lng)) &&
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
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) => degree * pi / 180;
}
