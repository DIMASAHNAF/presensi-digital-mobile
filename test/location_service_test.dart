import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
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

  group('evaluatePosition', () {
    final now = DateTime.utc(2026, 11, 26, 7, 15);
    final schoolPolygon = <LatLngPoint>[
      LatLngPoint(lat: 3.5866173, lng: 98.8803164),
      LatLngPoint(lat: 3.5856054, lng: 98.8803594),
      LatLngPoint(lat: 3.5855947, lng: 98.8818401),
      LatLngPoint(lat: 3.587158, lng: 98.8818934),
      LatLngPoint(lat: 3.5871955, lng: 98.8810727),
      LatLngPoint(lat: 3.5866333, lng: 98.8808689),
    ];

    final polygonCfg = GeofenceConfig(
      active: true,
      mode: 'polygon',
      latitude: 3.5864674,
      longitude: 98.8810585,
      radiusMeters: 120,
      polygonPoints: schoolPolygon,
      schoolName: 'SMK Negeri 1 Beringin',
    );

    Position makePos({
      required double lat,
      required double lng,
      double accuracy = 10.0,
      bool isMocked = false,
      Duration age = Duration.zero,
    }) =>
        Position(
          latitude: lat,
          longitude: lng,
          timestamp: now.subtract(age),
          accuracy: accuracy,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
          isMocked: isMocked,
        );

    test('validates inside SMKN 1 Beringin polygon', () {
      final res = LocationService.evaluatePosition(
        makePos(lat: 3.5864, lng: 98.8811, accuracy: 12),
        polygonCfg,
        now: now,
      );
      expect(res.isInside, isTrue);
      expect(res.issue, LocationIssue.none);
      expect(res.position, isNotNull);
    });

    test('reports distance to polygon edge when outside polygon', () {
      // ~30m north of northern edge (lat ~3.58719)
      final res = LocationService.evaluatePosition(
        makePos(lat: 3.58746, lng: 98.8814, accuracy: 8),
        polygonCfg,
        now: now,
      );
      expect(res.isInside, isFalse);
      expect(res.issue, LocationIssue.outsideArea);
      expect(res.distanceMeters, greaterThan(20));
      expect(res.distanceMeters, lessThan(45));
      expect(res.errorMessage, contains('di luar batas area sekolah'));
    });

    test('rejects mocked GPS with mocked issue', () {
      final res = LocationService.evaluatePosition(
        makePos(lat: 3.5864, lng: 98.8811, isMocked: true),
        polygonCfg,
        now: now,
      );
      expect(res.isInside, isFalse);
      expect(res.isMocked, isTrue);
      expect(res.issue, LocationIssue.mocked);
    });

    test('drops stale position so map never jumps to old home fix', () {
      final res = LocationService.evaluatePosition(
        makePos(
          lat: 3.5500,
          lng: 98.8500,
          accuracy: 10,
          age: const Duration(minutes: 15),
        ),
        polygonCfg,
        now: now,
      );
      expect(res.isInside, isFalse);
      expect(res.issue, LocationIssue.inaccurate);
      expect(res.position, isNull);
    });

    test('keeps fresh inaccurate position for accuracy halo and rescues via WiFi', () {
      final noWifi = LocationService.evaluatePosition(
        makePos(lat: 3.5864, lng: 98.8811, accuracy: 110),
        polygonCfg,
        now: now,
      );
      expect(noWifi.isInside, isFalse);
      expect(noWifi.issue, LocationIssue.inaccurate);
      expect(noWifi.position, isNotNull);

      final withWifi = LocationService.evaluatePosition(
        makePos(lat: 3.5864, lng: 98.8811, accuracy: 110),
        polygonCfg,
        networkConfig: NetworkConfig(active: true, isAllowed: true),
        now: now,
      );
      expect(withWifi.isInside, isTrue);
      expect(withWifi.position, isNotNull);
    });
  });
}

