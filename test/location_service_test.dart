import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_smkn1_beringin/core/services/location_service.dart';
import 'package:presensi_smkn1_beringin/core/models/session_model.dart';

void main() {
  group('haversineDistance', () {
    test('same point returns 0', () {
      final d = LocationService.haversineDistance(3.5866, 98.8813, 3.5866, 98.8813);
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
      expect(LocationService.isPointInPolygon(3.585, 98.885, degenerate), isFalse);
    });
  });
}
