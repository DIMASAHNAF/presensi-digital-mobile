class ApiConstants {
  // Base URL pointing directly to the proxied Golang Microservice
  static const String baseUrl = 'https://presensi.smknegeri1beringin.sch.id/api/v1';
  static const String storageBaseUrl = 'https://presensi.smknegeri1beringin.sch.id/storage';

  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String appConfig = '$baseUrl/app/config';
  static const String register = '$baseUrl/auth/register';

  // Master Data
  static const String kelas = '$baseUrl/kelas';

  // Siswa Endpoints
  static const String me = '$baseUrl/siswa/me';
  static const String updatePassword = '$baseUrl/siswa/update-password';
  static const String dashboardFull = '$baseUrl/siswa/dashboard-full';
  static const String sesiAktif = '$baseUrl/siswa/sesi-aktif';
  static const String scanWajah = '$baseUrl/siswa/scan-wajah';
  static const String enrollWajah = '$baseUrl/siswa/enroll-wajah';
  static const String riwayat = '$baseUrl/siswa/riwayat';
  static const String notifications = '$baseUrl/siswa/notifications';
  static const String izin = '$baseUrl/siswa/izin';
  static const String device = '$baseUrl/siswa/device';
  static const String deviceReset = '$baseUrl/siswa/device/reset';
}
