class KelasModel {
  final int id;
  final String namaKelas;
  final String? tingkat;
  final String? jurusan;

  KelasModel({
    required this.id,
    required this.namaKelas,
    this.tingkat,
    this.jurusan,
  });

  factory KelasModel.fromJson(Map<String, dynamic> json) {
    return KelasModel(
      id: json['id'] ?? 0,
      namaKelas: json['nama_kelas'] ?? '',
      tingkat: json['tingkat'],
      jurusan: json['jurusan'],
    );
  }

  String get label => namaKelas;
}
