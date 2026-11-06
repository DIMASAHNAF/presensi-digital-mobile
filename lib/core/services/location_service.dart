import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/session_model.dart';

class GeofenceResult {
  final bool isInside;
  final double distanceMeters;
  final bool isMocked;
  final Position? position;
  final String? errorMessage;

  GeofenceResult({
    required this.isInside,
    required this.distanceMeters,
    required this.isMocked,
    this.position,
    this.errorMessage,
  });
}

class LocationService {
  /// Request GPS permission and verify location services are enabled
  static Future<bool> ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current GPS position with high accuracy
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await ensurePermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
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
        errorMessage: 'Gagal mendapatkan sinyal GPS. Pastikan lokasi aktif dan izin diberikan.',
      );
    }

    // Anti-Mock GPS check
    if (pos.isMocked) {
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

