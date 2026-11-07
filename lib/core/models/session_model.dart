class LatLngPoint {
  final double lat;
  final double lng;

  LatLngPoint({required this.lat, required this.lng});

  factory LatLngPoint.fromJson(Map<String, dynamic> json) {
    return LatLngPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

class GeofenceConfig {
  final bool active;
  final String schoolName;
  final String mode;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final List<LatLngPoint> polygonPoints;

  GeofenceConfig({
    required this.active,
    required this.schoolName,
    required this.mode,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.polygonPoints,
  });

  factory GeofenceConfig.fromJson(Map<String, dynamic> json) {
    var rawPolygon = json['polygon_points'] as List<dynamic>? ?? [];
    List<LatLngPoint> points = rawPolygon
        .map((p) => LatLngPoint.fromJson(p as Map<String, dynamic>))
        .toList();

    return GeofenceConfig(
      active: json['active'] ?? false,
      schoolName: json['school_name'] ?? 'SMK Negeri 1 Beringin',
      mode: json['mode'] ?? 'polygon',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 3.5866,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 98.8813,
      radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 100.0,
      polygonPoints: points,
    );
  }
}

class SessionDetail {
  final int id;
  final int kelasId;
  final String kelasNama;
  final String jamPelajaran;
  final String guruNama;
  final String tanggal;
  final String tipe;

  String get namaKelas => kelasNama;
  String get keterangan => guruNama.isNotEmpty ? 'Guru: $guruNama' : 'Presensi Pembelajaran';

  // Smart subject name extraction:
  String get namaMapel {
    if (jamPelajaran.contains('(')) {
      final name = jamPelajaran.split('(').first.trim();
      if (name.isNotEmpty) return name;
    }
    return 'Presensi Mata Pelajaran';
  }

  // Smart schedule time extraction (without duplicating subject name):
  String get jadwalJam {
    if (jamPelajaran.contains('•')) {
      final parts = jamPelajaran.split('•');
      if (parts.length >= 2) {
        return parts.last.replaceAll(')', '').trim();
      }
    }
    if (jamPelajaran.contains('(') && jamPelajaran.contains(')')) {
      final inside = jamPelajaran.substring(
        jamPelajaran.indexOf('(') + 1,
        jamPelajaran.lastIndexOf(')'),
      );
      return inside.trim();
    }
    return jamPelajaran;
  }

  // Smart period label extraction:
  String get jamKeLabel {
    final lower = jamPelajaran.toLowerCase();
    if (lower.contains('jam ke')) {
      final regex = RegExp(r'Jam ke[- ]?(\d+)', caseSensitive: false);
      final match = regex.firstMatch(jamPelajaran);
      if (match != null) {
        return 'Jam ke-${match.group(1)}';
      }
    }
    return 'Jam Pelajaran';
  }

  String get jamMulai => jadwalJam.contains('-') ? jadwalJam.split('-').first.trim() : jadwalJam;
  String get jamSelesai => jadwalJam.contains('-') ? jadwalJam.split('-').last.trim() : jadwalJam;

  SessionDetail({
    required this.id,
    required this.kelasId,
    required this.kelasNama,
    required this.jamPelajaran,
    required this.guruNama,
    required this.tanggal,
    required this.tipe,
  });

  factory SessionDetail.fromJson(Map<String, dynamic> json) {
    return SessionDetail(
      id: json['id'] ?? 0,
      kelasId: json['kelas_id'] ?? 0,
      kelasNama: json['kelas_nama'] ?? '',
      jamPelajaran: json['jam_pelajaran'] ?? '',
      guruNama: json['guru_nama'] ?? '',
      tanggal: json['tanggal'] ?? '',
      tipe: json['tipe'] ?? 'kelas',
    );
  }
}

class PresensiTodayInfo {
  final String status;
  final String? checkInStatus;
  final String? waktuScan;
  final int lateMinutes;

  PresensiTodayInfo({
    required this.status,
    this.checkInStatus,
    this.waktuScan,
    required this.lateMinutes,
  });

  factory PresensiTodayInfo.fromJson(Map<String, dynamic> json) {
    return PresensiTodayInfo(
      status: json['status'] ?? 'belum',
      checkInStatus: json['check_in_status'],
      waktuScan: json['waktu_scan'],
      lateMinutes: json['late_minutes'] ?? 0,
    );
  }
}

class ActiveSessionResponse {
  final bool hasSesi;
  final bool sudahHadir;
  final SessionDetail? sesi;
  final GeofenceConfig? geofencing;
  final PresensiTodayInfo? presensiInfo;
  final String? message;

  ActiveSessionResponse({
    required this.hasSesi,
    required this.sudahHadir,
    this.sesi,
    this.geofencing,
    this.presensiInfo,
    this.message,
  });

  factory ActiveSessionResponse.fromJson(Map<String, dynamic> json) {
    return ActiveSessionResponse(
      hasSesi: json['has_sesi'] ?? false,
      sudahHadir: json['sudah_hadir'] ?? false,
      sesi: json['sesi'] != null ? SessionDetail.fromJson(json['sesi']) : null,
      geofencing: json['geofencing'] != null
          ? GeofenceConfig.fromJson(json['geofencing'])
          : null,
      presensiInfo: json['presensi_info'] != null
          ? PresensiTodayInfo.fromJson(json['presensi_info'])
          : null,
      message: json['message'],
    );
  }
}
