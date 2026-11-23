import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_smkn1_beringin/core/models/session_model.dart';
import 'package:presensi_smkn1_beringin/features/scanner/scanner_screen.dart';

Widget _scanner() => MaterialApp(
      home: ScannerScreen(
        geofenceConfig: GeofenceConfig(
          active: false,
          schoolName: 'Sekolah',
          mode: 'radius',
          latitude: 0,
          longitude: 0,
          radiusMeters: 100,
          polygonPoints: const [],
        ),
      ),
    );

void main() {
  testWidgets('scanner initializes policy state from widget', (tester) async {
    await tester.pumpWidget(_scanner());

    expect(tester.takeException(), isNull);
  });

  testWidgets('scanner describes capture without claiming local Face ID',
      (tester) async {
    await tester.pumpWidget(_scanner());

    expect(find.text('Presensi Wajah'), findsOneWidget);
    expect(find.text('Face ID'), findsNothing);
  });
}
