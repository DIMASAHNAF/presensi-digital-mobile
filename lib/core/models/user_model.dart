class UserModel {
  final int id;
  final String nisn;
  final String name;
  final String username;
  final int? kelasId;
  final String? kelasNama;
  final String? avatar;
  final String? banner;
  final bool isFaceEnrolled;
  final bool hasChangedPassword;
  final String? namaOrtu;
  final String? noHpOrtu;
  final String? bio;
  final String? website;

  String get nama => name;
  String get kelas => kelasNama ?? 'Siswa';

  UserModel({
    required this.id,
    required this.nisn,
    required this.name,
    required this.username,
    this.kelasId,
    this.kelasNama,
    this.avatar,
    this.banner,
    required this.isFaceEnrolled,
    required this.hasChangedPassword,
    this.namaOrtu,
    this.noHpOrtu,
    this.bio,
    this.website,
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
      banner: json['banner'],
      isFaceEnrolled: json['is_face_enrolled'] ?? false,
      hasChangedPassword: json['has_changed_password'] ?? false,
      namaOrtu: json['nama_ortu'],
      noHpOrtu: json['no_hp_ortu'],
      bio: json['bio'],
      website: json['website'],
    );
  }

  UserModel copyWith({
    int? id,
    String? nisn,
    String? name,
    String? username,
    int? kelasId,
    String? kelasNama,
    String? avatar,
    String? banner,
    bool? isFaceEnrolled,
    bool? hasChangedPassword,
    String? namaOrtu,
    String? noHpOrtu,
    String? bio,
    String? website,
  }) {
    return UserModel(
      id: id ?? this.id,
      nisn: nisn ?? this.nisn,
      name: name ?? this.name,
      username: username ?? this.username,
      kelasId: kelasId ?? this.kelasId,
      kelasNama: kelasNama ?? this.kelasNama,
      avatar: avatar ?? this.avatar,
      banner: banner ?? this.banner,
      isFaceEnrolled: isFaceEnrolled ?? this.isFaceEnrolled,
      hasChangedPassword: hasChangedPassword ?? this.hasChangedPassword,
      namaOrtu: namaOrtu ?? this.namaOrtu,
      noHpOrtu: noHpOrtu ?? this.noHpOrtu,
      bio: bio ?? this.bio,
      website: website ?? this.website,
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
      'banner': banner,
      'is_face_enrolled': isFaceEnrolled,
      'has_changed_password': hasChangedPassword,
      'nama_ortu': namaOrtu,
      'no_hp_ortu': noHpOrtu,
      'bio': bio,
      'website': website,
    };
  }
}
