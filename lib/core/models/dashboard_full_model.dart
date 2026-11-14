import 'session_model.dart';
import 'user_model.dart';

class JadwalItem {
  final String hari;
  final int jamKe;
  final String jamMulai;
  final String jamSelesai;
  final String mapel;
  final String guru;
  final String ruangan;
  final bool isBreak;

  JadwalItem({
    required this.hari,
    required this.jamKe,
    required this.jamMulai,
    required this.jamSelesai,
    required this.mapel,
    required this.guru,
    required this.ruangan,
    required this.isBreak,
  });

  factory JadwalItem.fromJson(Map<String, dynamic> json) {
    return JadwalItem(
      hari: json['hari'] ?? '',
      jamKe: json['jam_ke'] ?? 0,
      jamMulai: json['jam_mulai'] ?? '',
      jamSelesai: json['jam_selesai'] ?? '',
      mapel: json['mapel'] ?? '',
      guru: json['guru'] ?? '',
      ruangan: json['ruangan'] ?? '',
      isBreak: json['is_break'] ?? false,
    );
  }

  String get jamLabel =>
      (jamMulai.isEmpty && jamSelesai.isEmpty) ? '-' : '$jamMulai - $jamSelesai';

  String get lesLabel => 'Jam ke-$jamKe';
}

class CalendarDay {
  final int day;
  final String? status;
  final bool isToday;

  CalendarDay({required this.day, this.status, required this.isToday});

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      day: json['day'] ?? 0,
      status: json['status'],
      isToday: json['is_today'] ?? false,
    );
  }
}

class CalendarData {
  final String monthName;
  final int month;
  final int year;
  final int daysInMonth;
  final int todayDay;
  final List<CalendarDay> days;

  CalendarData({
    required this.monthName,
    required this.month,
    required this.year,
    required this.daysInMonth,
    required this.todayDay,
    required this.days,
  });

  factory CalendarData.fromJson(Map<String, dynamic> json) {
    var raw = json['days'] as List<dynamic>? ?? [];
    return CalendarData(
      monthName: json['month_name'] ?? '',
      month: json['month'] ?? 1,
      year: json['year'] ?? 2026,
      daysInMonth: json['days_in_month'] ?? 30,
      todayDay: json['today_day'] ?? 1,
      days: raw.map((d) => CalendarDay.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}

class StatsModel {
  final int persentase;
  final int hadir;
  final int izin;
  final int sakit;
  final int alpa;
  final int total;

  StatsModel({
    required this.persentase,
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alpa,
    required this.total,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      persentase: json['persentase'] ?? 0,
      hadir: json['hadir'] ?? 0,
      izin: json['izin'] ?? 0,
      sakit: json['sakit'] ?? 0,
      alpa: json['alpa'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class ClassmateModel {
  final int id;
  final String name;
  final String username;
  final String? avatar;
  final String? banner;
  final String? bio;
  final String? website;
  final String statusHariIni; // 'hadir' | 'belum'
  final String? jamAbsen;

  String get nama => name;
  String get nisn => username;

  ClassmateModel({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
    this.banner,
    this.bio,
    this.website,
    required this.statusHariIni,
    this.jamAbsen,
  });

  factory ClassmateModel.fromJson(Map<String, dynamic> json) {
    return ClassmateModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'],
      banner: json['banner'],
      bio: json['bio'],
      website: json['website'],
      statusHariIni: json['status_hari_ini'] ?? 'belum',
      jamAbsen: json['jam_absen'],
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'SW';
  }
}

class DashboardFullModel {
  final UserModel user;
  final StatsModel stats;
  final bool hasSesi;
  final bool sudahHadir;
  final SessionDetail? sesi;
  final PresensiTodayInfo? presensiInfo;
  final GeofenceConfig? geofencing;
  final List<ClassmateModel> temanSekelas;
  final int totalTeman;
  final List<dynamic> riwayat;
  final List<JadwalItem> jadwal;
  final CalendarData? calendar;

  DashboardFullModel({
    required this.user,
    required this.stats,
    required this.hasSesi,
    required this.sudahHadir,
    this.sesi,
    this.presensiInfo,
    this.geofencing,
    required this.temanSekelas,
    required this.totalTeman,
    required this.riwayat,
    this.jadwal = const [],
    this.calendar,
  });

  factory DashboardFullModel.fromJson(Map<String, dynamic> json) {
    var rawFriends = json['teman_sekelas'] as List<dynamic>? ?? [];
    List<ClassmateModel> friends = rawFriends
        .map((f) => ClassmateModel.fromJson(f as Map<String, dynamic>))
        .toList();

    var rawJadwal = json['jadwal'] as List<dynamic>? ?? [];

    return DashboardFullModel(
      user: UserModel.fromJson(json['user'] ?? {}),
      stats: StatsModel.fromJson(json['stats'] ?? {}),
      hasSesi: json['has_sesi'] ?? false,
      sudahHadir: json['sudah_hadir'] ?? false,
      sesi: json['sesi'] != null ? SessionDetail.fromJson(json['sesi']) : null,
      presensiInfo: json['presensi_info'] != null
          ? PresensiTodayInfo.fromJson(json['presensi_info'])
          : null,
      geofencing: json['geofencing'] != null
          ? GeofenceConfig.fromJson(json['geofencing'])
          : null,
      temanSekelas: friends,
      totalTeman: json['total_teman'] ?? friends.length,
      riwayat: json['riwayat'] as List<dynamic>? ?? [],
      jadwal: rawJadwal
          .map((j) => JadwalItem.fromJson(j as Map<String, dynamic>))
          .toList(),
      calendar: json['calendar'] != null
          ? CalendarData.fromJson(json['calendar'])
          : null,
    );
  }

  DashboardFullModel copyWith({
    UserModel? user,
    StatsModel? stats,
    bool? hasSesi,
    bool? sudahHadir,
    SessionDetail? sesi,
    PresensiTodayInfo? presensiInfo,
    GeofenceConfig? geofencing,
    List<ClassmateModel>? temanSekelas,
    int? totalTeman,
    List<dynamic>? riwayat,
    List<JadwalItem>? jadwal,
    CalendarData? calendar,
  }) {
    return DashboardFullModel(
      user: user ?? this.user,
      stats: stats ?? this.stats,
      hasSesi: hasSesi ?? this.hasSesi,
      sudahHadir: sudahHadir ?? this.sudahHadir,
      sesi: sesi ?? this.sesi,
      presensiInfo: presensiInfo ?? this.presensiInfo,
      geofencing: geofencing ?? this.geofencing,
      temanSekelas: temanSekelas ?? this.temanSekelas,
      totalTeman: totalTeman ?? this.totalTeman,
      riwayat: riwayat ?? this.riwayat,
      jadwal: jadwal ?? this.jadwal,
      calendar: calendar ?? this.calendar,
    );
  }

  /// Terapkan hasil polling `/siswa/sesi-aktif` tanpa reload penuh.
  DashboardFullModel applySessionPoll(ActiveSessionResponse poll) {
    return DashboardFullModel(
      user: user,
      stats: stats,
      hasSesi: poll.hasSesi,
      sudahHadir: poll.sudahHadir,
      sesi: poll.sesi,
      presensiInfo: poll.presensiInfo ?? presensiInfo,
      geofencing: poll.geofencing ?? geofencing,
      temanSekelas: temanSekelas,
      totalTeman: totalTeman,
      riwayat: riwayat,
      jadwal: jadwal,
      calendar: calendar,
    );
  }
}

