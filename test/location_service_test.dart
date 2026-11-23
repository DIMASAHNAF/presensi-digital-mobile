import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_smkn1_beringin/core/services/location_service.dart';
import 'package:presensi_smkn1_beringin/core/models/session_model.dart';

void main() {
  group('mock location policy', () {
    test('mock flag cannot reject scan when geofence disabled', () {
      expect(LocationService.scanLocationAllowed(false, true), isTrue);
      expect(LocationService.scanLocationAllowed(true, true), isFalse);
      expect(LocationService.scanLocationAllowed(true, false), isTrue);
    });
  });

  group('scan GPS validity', () {
    final now = DateTime.utc(2026, 11, 15, 8);

    test('accepts fresh Indonesian coordinates with acceptable accuracy', () {
      expect(
        LocationService.scanGpsAllowed(
          latitude: 3.586138,
          longitude: 98.881361,
          accuracy: 80,
          timestamp: now,
          now: now,
        ),
        isTrue,
      );
    });

    test('rejects stale, too-future, inaccurate, or invalid coordinates', () {
      bool allowed({
        double latitude = 3.586138,
        double longitude = 98.881361,
        double accuracy = 10,
        Duration age = Duration.zero,
      }) =>
          LocationService.scanGpsAllowed(
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            timestamp: now.subtract(age),
            now: now,
          );

      expect(allowed(age: const Duration(minutes: 5, milliseconds: 1)), isFalse);
      expect(allowed(age: const Duration(seconds: -31)), isFalse);
      expect(allowed(accuracy: 0), isFalse);
      expect(allowed(accuracy: 81), isFalse);
      expect(allowed(latitude: 91), isFalse);
      expect(allowed(longitude: double.nan), isFalse);
    });
  });

  group('haversineDistance', () {
    test('same point returns 0', () {
      final d =
          LocationService.haversineDistance(3.5866, 98.8813, 3.5866, 98.8813);
      expect(d, closeTo(0, 0.01));
    });

    test('known distance ~111km per degree latitude', () {
      // 1 derajat lintang ~111.19 km
      final d = LocationService.haversineDistance(0.0, 0.0, 1.0, 0.0);
      expect(d, closeTo(111194.9, 100));
    });
  });

  group('isPointInPolygon', () {
    // Kotak: lat 3.58..3.59, lng 98.88..98.89
    final box = <LatLngPoint>[
      LatLngPoint(lat: 3.58, lng: 98.88),
      LatLngPoint(lat: 3.58, lng: 98.89),
      LatLngPoint(lat: 3.59, lng: 98.89),
      LatLngPoint(lat: 3.59, lng: 98.88),
    ];

    test('inside box returns true', () {
      expect(LocationService.isPointInPolygon(3.585, 98.885, box), isTrue);
    });

    test('outside box returns false', () {
      expect(LocationService.isPointInPolygon(3.60, 98.885, box), isFalse);
    });

    test('degenerate polygon (<3 points) returns false', () {
      final degenerate = <LatLngPoint>[
        LatLngPoint(lat: 3.58, lng: 98.88),
        LatLngPoint(lat: 3.59, lng: 98.89),
      ];
      expect(
          LocationService.isPointInPolygon(3.585, 98.885, degenerate), isFalse);
    });
  });

  group('polygon 5m edge tolerance parity with Rust and Laravel', () {
    final fence = <LatLngPoint>[
      LatLngPoint(lat: 3.585, lng: 98.880),
      LatLngPoint(lat: 3.585, lng: 98.883),
      LatLngPoint(lat: 3.587, lng: 98.883),
      LatLngPoint(lat: 3.587, lng: 98.880),
    ];

    test('accepts point ~3.3m outside polygon edge within 5m tolerance', () {
      expect(LocationService.isPointInPolygon(3.58703, 98.8815, fence), isFalse);
      final edgeDist =
          LocationService.distanceToPolygonEdge(3.58703, 98.8815, fence);
      expect(edgeDist, greaterThan(2.0));
      expect(edgeDist, lessThanOrEqualTo(5.0));
      expect(
          LocationService.isPointAllowedInPolygon(3.58703, 98.8815, fence),
          isTrue);
    });

    test('rejects point ~25m outside polygon edge', () {
      expect(
          LocationService.isPointAllowedInPolygon(3.58723, 98.8815, fence),
          isFalse);
    });

    test('allows up to 150m GPS accuracy when verified on school WiFi', () {
      final now = DateTime.utc(2026, 11, 23, 7, 25);
      expect(
        LocationService.scanGpsAllowed(
          latitude: 3.586138,
          longitude: 98.881361,
          accuracy: 120,
          timestamp: now,
          now: now,
          maxAccuracyMeters: 150.0,
        ),
        isTrue,
      );
      expect(
        LocationService.scanGpsAllowed(
          latitude: 3.586138,
          longitude: 98.881361,
          accuracy: 120,
          timestamp: now,
          now: now,
        ),
        isFalse,
      );
    });
  });
}

