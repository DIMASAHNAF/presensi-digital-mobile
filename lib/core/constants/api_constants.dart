class ApiConstants {
  // Base URL pointing directly to the proxied Golang Microservice
  static const String baseUrl = 'https://presensi.smknegeri1beringin.sch.id/api/v1';
  static const String storageBaseUrl = 'https://presensi.smknegeri1beringin.sch.id/storage';

  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';

  // Siswa Endpoints
  static const String me = '$baseUrl/siswa/me';
  static const String sesiAktif = '$baseUrl/siswa/sesi-aktif';
  static const String scanWajah = '$baseUrl/siswa/scan-wajah';
  static const String riwayat = '$baseUrl/siswa/riwayat';
}
