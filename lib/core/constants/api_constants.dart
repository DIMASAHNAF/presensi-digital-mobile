class ApiConstants {
  // Base URL pointing directly to the proxied Rust Microservice (presensi-rust-api v2)
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
  static const String device = '$baseUrl/siswa/device';
  static const String deviceReset = '$baseUrl/siswa/device/reset';

  /// Resolves a stored avatar/banner relative path or full URL into a clean, loadable URL.
  /// Returns an empty string for null, empty, or Laravel sentinel `'0'` / `'null'`.
  static String resolveStorageUrl(String? path) {
    if (path == null) return '';
    final trimmed = path.trim();
    if (trimmed.isEmpty ||
        trimmed == '0' ||
        trimmed.toLowerCase() == 'null') {
      return '';
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Uri.encodeFull(trimmed);
    }
    var clean = trimmed;
    while (clean.startsWith('/')) {
      clean = clean.substring(1);
    }
    if (clean.startsWith('storage/')) {
      clean = clean.substring('storage/'.length);
    }
    if (clean.isEmpty || clean == '0') return '';
    return Uri.encodeFull('$storageBaseUrl/$clean');
  }
}
