import 'session_model.dart';
import 'user_model.dart';

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
  });

  factory DashboardFullModel.fromJson(Map<String, dynamic> json) {
    var rawFriends = json['teman_sekelas'] as List<dynamic>? ?? [];
    List<ClassmateModel> friends = rawFriends
        .map((f) => ClassmateModel.fromJson(f as Map<String, dynamic>))
        .toList();

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
    );
  }
}

