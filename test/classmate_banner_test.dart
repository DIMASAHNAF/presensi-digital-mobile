import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_smkn1_beringin/core/constants/api_constants.dart';
import 'package:presensi_smkn1_beringin/core/models/dashboard_full_model.dart';
import 'package:presensi_smkn1_beringin/features/dashboard/dialogs/classmate_detail_dialog.dart';

void main() {
  group('ApiConstants.resolveStorageUrl', () {
    test('treats null, empty, and Laravel sentinel 0 as empty', () {
      expect(ApiConstants.resolveStorageUrl(null), '');
      expect(ApiConstants.resolveStorageUrl(''), '');
      expect(ApiConstants.resolveStorageUrl('  '), '');
      expect(ApiConstants.resolveStorageUrl('0'), '');
      expect(ApiConstants.resolveStorageUrl('null'), '');
    });

    test('strips leading slash and duplicate storage prefix and encodes spaces', () {
      expect(
        ApiConstants.resolveStorageUrl('accounts/0092585859/banner/cover.jpg'),
        'https://presensi.smknegeri1beringin.sch.id/storage/accounts/0092585859/banner/cover.jpg',
      );
      expect(
        ApiConstants.resolveStorageUrl('/storage/accounts/0092585859/banner/cover.jpg'),
        'https://presensi.smknegeri1beringin.sch.id/storage/accounts/0092585859/banner/cover.jpg',
      );
      expect(
        ApiConstants.resolveStorageUrl('Siswa/XII PPLG 1/Budi Santoso/banner/my photo.jpg'),
        'https://presensi.smknegeri1beringin.sch.id/storage/Siswa/XII%20PPLG%201/Budi%20Santoso/banner/my%20photo.jpg',
      );
      expect(
        ApiConstants.resolveStorageUrl('https://cdn.example.com/img/banner.png'),
        'https://cdn.example.com/img/banner.png',
      );
    });
  });

  testWidgets('ClassmateDetailDialog default banner never renders campus map asset', (tester) async {
    final classmate = ClassmateModel(
      id: 7,
      name: 'Siti Aisyah',
      username: 'siti_a',
      avatar: null,
      banner: null,
      bio: 'Semangat belajar',
      statusHariIni: 'hadir',
      jamAbsen: '07:15',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClassmateDetailDialog(
              classmate: classmate,
              kelasNama: 'XI PPLG 1',
            ),
          ),
        ),
      ),
    );

    final imageWidgets = tester.widgetList<Image>(find.byType(Image));
    for (final img in imageWidgets) {
      expect(img.image, isNot(isA<AssetImage>()));
    }
    expect(find.text('Siti Aisyah'), findsOneWidget);
  });
}
