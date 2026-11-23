import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presensi_smkn1_beringin/core/models/dashboard_full_model.dart';
import 'package:presensi_smkn1_beringin/core/models/session_model.dart';
import 'package:presensi_smkn1_beringin/core/models/user_model.dart';
import 'package:presensi_smkn1_beringin/core/services/location_service.dart';
import 'package:presensi_smkn1_beringin/core/theme/app_theme.dart';
import 'package:presensi_smkn1_beringin/features/dashboard/dialogs/rekap_kehadiran_dialog.dart';
import 'package:presensi_smkn1_beringin/features/dashboard/tabs/beranda_tab.dart';
import 'package:presensi_smkn1_beringin/features/dashboard/tabs/kehadiran_tab.dart';
import 'package:presensi_smkn1_beringin/features/dashboard/tabs/profil_tab.dart';
import 'package:presensi_smkn1_beringin/features/dashboard/tabs/teman_tab.dart';

DashboardFullModel _sampleDashboard() {
  return DashboardFullModel(
    user: UserModel(
      id: 42,
      nisn: '0092506720',
      name: 'DIMAS AHNAF FATHURRAHMAN',
      username: 'dimas_ahnaf',
      kelasId: 3,
      kelasNama: 'XI PPLG 3',
      avatar: null,
      banner: null,
      isFaceEnrolled: true,
      hasChangedPassword: true,
      namaOrtu: 'Ahmad Fathurrahman',
      noHpOrtu: '081234567890',
      bio: 'Pelajar SMKN 1 Beringin',
      website: null,
    ),
    stats: StatsModel(
      persentase: 65,
      hadir: 11,
      izin: 1,
      sakit: 0,
      alpa: 5,
      total: 17,
    ),
    hasSesi: true,
    sudahHadir: false,
    sesi: SessionDetail(
      id: 101,
      kelasId: 3,
      kelasNama: 'XI PPLG 3',
      jamPelajaran: 'Presensi Pagi',
      guruNama: 'Guru Piket',
      tanggal: '2026-11-23',
      tipe: 'kelas',
    ),
    geofencing: GeofenceConfig(
      active: true,
      schoolName: 'SMK Negeri 1 Beringin',
      latitude: 3.586138,
      longitude: 98.881361,
      radiusMeters: 110,
      mode: 'polygon',
      polygonPoints: const [],
    ),
    temanSekelas: [
      ClassmateModel(
        id: 2,
        name: 'SITI AISYAH RAHMADANI',
        username: '0091112233',
        statusHariIni: 'hadir',
        jamAbsen: '07:12',
      ),
      ClassmateModel(
        id: 3,
        name: 'MUHAMMAD RIZKY PRATAMA',
        username: '0092223344',
        statusHariIni: 'belum',
      ),
    ],
    totalTeman: 2,
    riwayat: [
      {
        'id': 1,
        'status': 'hadir',
        'tanggal': '23 Nov 2026',
        'jam': '07:14',
        'mapel': 'Pemrograman Web',
        'guru': 'Pak Budi',
        'distance': 12.0,
      },
    ],
    jadwal: [
      JadwalItem(
        hari: 'senin',
        jamKe: 1,
        jamMulai: '07:30',
        jamSelesai: '09:00',
        mapel: 'Pemrograman Perangkat Bergerak',
        guru: 'Ibu Sari Rahayu, S.Kom',
        ruangan: 'Lab PPLG 1 Lantai 2',
        isBreak: false,
      ),
    ],
    calendar: CalendarData(
      monthName: 'November 2026',
      month: 11,
      year: 2026,
      daysInMonth: 30,
      todayDay: 23,
      days: List.generate(
        30,
        (i) => CalendarDay(
          day: i + 1,
          status: i == 22 ? 'hadir' : null,
          isToday: i == 22,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets(
      'Narrow 360dp viewport renders all tabs & Rekap dialog with zero overflow, zero Izin button, and semantic 65% color',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    AppColors.configure(Brightness.light);
    final data = _sampleDashboard();

    // 1. BerandaTab: zero Izin button, zero OpenStreetMap mojibake, zero overflow
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: BerandaTab(
            data: data,
            geofenceResult: GeofenceResult(
              isInside: true,
              distanceMeters: 0,
              isMocked: false,
            ),
            currentTimeWIB: '07:25:10 WIB',
            onOpenScanner: () {},
            onOpenRekap: () {},
            onOpenKehadiran: () {},
            onOpenTeman: () {},
            onProfileUpdated: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Izin'), findsNothing);
    expect(find.textContaining('OpenStreetMap'), findsNothing);
    expect(find.textContaining('Â©'), findsNothing);
    expect(find.text('Area Valid • 0m'), findsOneWidget);

    // 2. KehadiranTab: Dapodik 75% card + aligned 7-col calendar, zero overflow
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: KehadiranTab(data: data),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Standar Dapodik 75%'), findsOneWidget);
    expect(find.text('Perlu Perhatian'), findsOneWidget);
    expect(find.textContaining('Sisa Toleransi Izin/Sakit'), findsNothing);

    // 3. RekapKehadiranDialog: long name doesn't collide, 65% is warning (not green), 07.30 WIB policy
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: RekapKehadiranDialog(data: data),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Dimas Ahnaf Fathurrahman'), findsOneWidget);
    final pctWidget = tester.widget<Text>(find.text('65%'));
    expect(pctWidget.style?.color, isNot(equals(AppColors.success)));
    expect(find.textContaining('07.30 WIB', findRichText: true), findsOneWidget);

    // 4. TemanTab: overflow-safe header & iOS segmented control
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: TemanTab(data: data),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('XI PPLG 3'), findsOneWidget);

    // 5. ProfilTab: no 'Perangkat Saya' tile, overflow-safe academic card
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ProfilTab(data: data, onLogout: () {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Perangkat Saya'), findsNothing);
    // Clean up repeating animations before test teardown
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
