import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_smkn1_beringin/core/models/dashboard_full_model.dart';
import 'package:presensi_smkn1_beringin/core/models/session_model.dart';
import 'package:presensi_smkn1_beringin/core/models/user_model.dart';

DashboardFullModel _base() => DashboardFullModel(
      user: UserModel(
        id: 1,
        nisn: '1234567890',
        name: 'Test',
        username: 'test',
        isFaceEnrolled: true,
        hasChangedPassword: true,
      ),
      stats: StatsModel(
        persentase: 90,
        hadir: 9,
        izin: 1,
        sakit: 0,
        alpa: 0,
        total: 10,
      ),
      hasSesi: false,
      sudahHadir: false,
      temanSekelas: [],
      totalTeman: 0,
      riwayat: [],
    );

void main() {
  group('applySessionPoll', () {
    test('poll dengan sesi baru -> hasSesi true, sesi terpasang', () {
      final base = _base();
      final poll = ActiveSessionResponse(
        hasSesi: true,
        sudahHadir: false,
        sesi: SessionDetail(
          id: 7,
          kelasId: 1,
          kelasNama: 'X PPLG 1',
          jamPelajaran: 'Matematika',
          guruNama: 'Budi',
          tanggal: '2026-11-12',
          tipe: 'kelas',
        ),
      );

      final merged = base.applySessionPoll(poll);

      expect(merged.hasSesi, isTrue);
      expect(merged.sesi?.id, 7);
      expect(merged.sudahHadir, isFalse);
    });

    test('poll tanpa sesi -> hasSesi false, sesi null', () {
      final base = _base();
      final poll = ActiveSessionResponse(hasSesi: false, sudahHadir: false);

      final merged = base.applySessionPoll(poll);

      expect(merged.hasSesi, isFalse);
      expect(merged.sesi, isNull);
    });

    test('poll sudah hadir -> sudahHadir true, data lain tetap', () {
      final base = _base();
      final poll = ActiveSessionResponse(hasSesi: true, sudahHadir: true);

      final merged = base.applySessionPoll(poll);

      expect(merged.sudahHadir, isTrue);
      expect(merged.stats.hadir, 9);
      expect(merged.user.name, 'Test');
    });

    test('poll update geofencing bila ada', () {
      final base = _base();
      final poll = ActiveSessionResponse(
        hasSesi: false,
        sudahHadir: false,
        geofencing: GeofenceConfig(
          active: true,
          schoolName: 'SMKN 1 Beringin',
          mode: 'radius',
          latitude: 3.5,
          longitude: 98.8,
          radiusMeters: 120,
          polygonPoints: [],
        ),
      );

      final merged = base.applySessionPoll(poll);

      expect(merged.geofencing?.radiusMeters, 120);
    });
  });
}
