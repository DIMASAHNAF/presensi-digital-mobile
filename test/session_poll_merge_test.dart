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
  group('mobile attendance policy contract', () {
    test('network polling state reflects configured Wi-Fi policy', () {
      final network = NetworkConfig.fromJson({
        'active': true,
        'is_allowed': false,
      });

      expect(network.active, isTrue);
      expect(network.isAllowed, isFalse);
    });

    test('poll merges server network state and geofence configuration', () {
      final poll = ActiveSessionResponse.fromJson({
        'success': true,
        'has_sesi': true,
        'sudah_hadir': false,
        'sesi': {
          'id': 7,
          'kelas_id': 1,
          'kelas_nama': 'X PPLG 1',
          'jam_pelajaran': 'Pagi',
          'guru_nama': 'Budi',
          'tanggal': '2026-11-15',
          'tipe': 'kelas',
        },
        'network': {'active': true, 'is_allowed': false},
        'geofencing': {
          'active': true,
          'mode': 'radius',
          'school_name': 'SMKN 1 Beringin',
          'latitude': 3.586138,
          'longitude': 98.881361,
          'radius_meters': 100,
        },
      });
      final merged = _base().applySessionPoll(poll);
      expect(merged.network?.active, isTrue);
      expect(merged.network?.isAllowed, isFalse);
      expect(merged.geofencing?.latitude, 3.586138);
      expect(merged.geofencing?.longitude, 98.881361);
    });

    test('morning scanner requires open class session and no attendance', () {
      final model = _base().copyWith(
        hasSesi: true,
        sesi: SessionDetail(
          id: 7,
          kelasId: 1,
          kelasNama: 'X PPLG 1',
          jamPelajaran: 'Pagi',
          guruNama: 'Budi',
          tanggal: '2026-11-15',
          tipe: 'kelas',
        ),
      );
      expect(model.canScanMorning, isTrue);
      expect(model.copyWith(sudahHadir: true).canScanMorning, isFalse);
      expect(model.copyWith(hasSesi: false).canScanMorning, isFalse);
      expect(
          model
              .copyWith(
                  sesi: SessionDetail(
                id: 8,
                kelasId: 1,
                kelasNama: 'X PPLG 1',
                jamPelajaran: 'Matematika',
                guruNama: 'Budi',
                tanggal: '2026-11-15',
                tipe: 'mapel',
              ))
              .canScanMorning,
          isFalse);
    });
  });

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
