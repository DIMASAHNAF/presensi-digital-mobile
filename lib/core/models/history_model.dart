class HistoryItem {
  final int id;
  final String tanggal;
  final String waktuScan;
  final String status; // 'hadir', 'terlambat', 'izin', 'sakit', 'alpha'
  final String? jamPelajaran;
  final String? mapel;
  final String? guruNama;
  final int lateMinutes;
  final String? fotoUrl;

  HistoryItem({
    required this.id,
    required this.tanggal,
    required this.waktuScan,
    required this.status,
    this.jamPelajaran,
    this.mapel,
    this.guruNama,
    required this.lateMinutes,
    this.fotoUrl,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? 0,
      tanggal: json['tanggal'] ?? '',
      waktuScan: json['waktu_scan'] ?? json['jam_masuk'] ?? '',
      status: (json['status'] ?? 'hadir').toString().toLowerCase(),
      jamPelajaran: json['jam_pelajaran'],
      mapel: json['mapel'],
      guruNama: json['guru_nama'],
      lateMinutes: json['late_minutes'] ?? 0,
      fotoUrl: json['foto_url'] ?? json['foto_scan'],
    );
  }
}
