class UserModel {
  final int id;
  final String nisn;
  final String name;
  final String username;
  final int? kelasId;
  final String? kelasNama;
  final String? avatar;
  final bool isFaceEnrolled;
  final bool hasChangedPassword;
  final String? namaOrtu;
  final String? noHpOrtu;

  UserModel({
    required this.id,
    required this.nisn,
    required this.name,
    required this.username,
    this.kelasId,
    this.kelasNama,
    this.avatar,
    required this.isFaceEnrolled,
    required this.hasChangedPassword,
    this.namaOrtu,
    this.noHpOrtu,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      nisn: json['nisn'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      kelasId: json['kelas_id'],
      kelasNama: json['kelas_nama'],
      avatar: json['avatar'],
      isFaceEnrolled: json['is_face_enrolled'] ?? false,
      hasChangedPassword: json['has_changed_password'] ?? false,
      namaOrtu: json['nama_ortu'],
      noHpOrtu: json['no_hp_ortu'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nisn': nisn,
      'name': name,
      'username': username,
      'kelas_id': kelasId,
      'kelas_nama': kelasNama,
      'avatar': avatar,
      'is_face_enrolled': isFaceEnrolled,
      'has_changed_password': hasChangedPassword,
      'nama_ortu': namaOrtu,
      'no_hp_ortu': noHpOrtu,
    };
  }
}
