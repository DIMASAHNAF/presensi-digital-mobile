import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/history_model.dart';
import '../models/dashboard_full_model.dart';
import 'storage_service.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });
}

class ApiService {
  static final http.Client _client = http.Client();

  static Map<String, String> _headers({bool withAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// 1. Login with NISN & Password
  static Future<ApiResponse<UserModel>> login(String nisn, String password) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.login),
        headers: _headers(withAuth: false),
        body: jsonEncode({
          'nisn': nisn.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final token = body['token'] as String;
        final user = UserModel.fromJson(body['user']);

        await StorageService.saveToken(token);
        await StorageService.saveUser(user);

        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Login berhasil.',
          data: user,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'NISN atau Password salah.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Koneksi gagal: pastikan jaringan internet stabil.',
      );
    }
  }

  /// Update Password (Onboarding & Security Setup)
  static Future<ApiResponse<UserModel>> updatePassword(String password, String confirmation) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.updatePassword),
        headers: _headers(withAuth: true),
        body: jsonEncode({
          'password': password.trim(),
          'password_confirmation': confirmation.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final currentUser = StorageService.getUser();
        if (currentUser != null) {
          final updated = currentUser.copyWith(hasChangedPassword: true);
          await StorageService.saveUser(updated);
          return ApiResponse(
            success: true,
            message: body['message'] ?? 'Password berhasil diperbarui.',
            data: updated,
          );
        }
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Password berhasil diperbarui.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Gagal memperbarui password.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Koneksi gagal: periksa internet Anda.',
      );
    }
  }

  /// Submit Izin / Sakit Real-Time
  static Future<ApiResponse<void>> submitIzin({
    required String jenis,
    required String keterangan,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.izin),
        headers: _headers(withAuth: true),
        body: jsonEncode({
          'jenis': jenis.toLowerCase(),
          'keterangan': keterangan.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Permohonan berhasil dicatat.',
        );
      }
      return ApiResponse(
        success: false,
        message: body['message'] ?? 'Gagal mengajukan permohonan.',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Koneksi gagal saat mengajukan permohonan.',
      );
    }
  }

  /// 2. Get Full Dashboard Data (Profile, Active Session, Stats, Classmates, History)
  static Future<ApiResponse<DashboardFullModel>> getDashboardFull() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.dashboardFull),
        headers: _headers(withAuth: true),
      ).timeout(const Duration(seconds: 12));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final model = DashboardFullModel.fromJson(body);
        await StorageService.saveUser(model.user);
        return ApiResponse(
          success: true,
          message: 'Data dashboard berhasil dimuat.',
          data: model,
        );
      } else if (response.statusCode == 401) {
        await StorageService.clear();
        return ApiResponse(
          success: false,
          message: 'Sesi login telah berakhir. Silakan login kembali.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Gagal memuat dashboard.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Koneksi jaringan gagal.',
      );
    }
  }

  /// 3. Get Student Profile
  static Future<ApiResponse<UserModel>> getProfile() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.me),
        headers: _headers(withAuth: true),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final user = UserModel.fromJson(body['user']);
        await StorageService.saveUser(user);
        return ApiResponse(
          success: true,
          message: 'Data profil berhasil dimuat.',
          data: user,
        );
      } else if (response.statusCode == 401) {
        await StorageService.clear();
        return ApiResponse(
          success: false,
          message: 'Sesi login telah berakhir. Silakan login kembali.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Gagal memuat profil.',
        );
      }
    } catch (e) {
      // Fallback to locally cached user
      final cachedUser = StorageService.getUser();
      if (cachedUser != null) {
        return ApiResponse(
          success: true,
          message: 'Mode offline: menampilkan profil tersimpan.',
          data: cachedUser,
        );
      }
      return ApiResponse(
        success: false,
        message: 'Koneksi jaringan gagal.',
      );
    }
  }

  /// 3. Get Active Session & Geofencing Info
  static Future<ApiResponse<ActiveSessionResponse>> getActiveSession() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.sesiAktif),
        headers: _headers(withAuth: true),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final sessionResp = ActiveSessionResponse.fromJson(body);
        return ApiResponse(
          success: true,
          message: 'Sesi aktif berhasil dimuat.',
          data: sessionResp,
        );
      } else if (response.statusCode == 401) {
        await StorageService.clear();
        return ApiResponse(
          success: false,
          message: 'Sesi login telah berakhir. Silakan login kembali.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Gagal memuat sesi aktif.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Koneksi jaringan gagal.',
      );
    }
  }

  /// 4. Submit Face Scan Biometrics + GPS
  static Future<ApiResponse<Map<String, dynamic>>> submitFaceScan({
    required String imageBase64,
    required double latitude,
    required double longitude,
    required double accuracy,
    required bool isMocked,
    int? sesiId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'image': imageBase64,
        'face_image': imageBase64,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'is_mock': isMocked,
        'is_mocked': isMocked,
      };
      if (sesiId != null && sesiId > 0) {
        payload['sesi_id'] = sesiId;
      }

      final response = await _client.post(
        Uri.parse(ApiConstants.scanWajah),
        headers: _headers(withAuth: true),
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 25));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Presensi berhasil dicatat!',
          data: body,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Gagal memproses presensi wajah.',
          data: body,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Koneksi timeout atau gagal menghubungi server presensi.',
      );
    }
  }

  /// 5. Enroll Face Biometrics (Multi-angle photos)
  static Future<ApiResponse<Map<String, dynamic>>> enrollFace({
    required List<String> faceImagesBase64,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.enrollWajah),
        headers: _headers(withAuth: true),
        body: jsonEncode({
          'face_images': faceImagesBase64,
        }),
      ).timeout(const Duration(seconds: 45));

      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = null;
      }

      if (response.statusCode == 200 && body != null && body['success'] == true) {
        // Refresh local user profile so isFaceEnrolled becomes true
        await getProfile();
        return ApiResponse(
          success: true,
          message: (body is Map ? body['message'] : null) ?? 'Wajah berhasil didaftarkan!',
          data: body is Map<String, dynamic> ? body : null,
        );
      } else {
        final errMsg = (body is Map ? body['message'] : null) ??
            'Gagal mendaftarkan biometrik wajah (HTTP ${response.statusCode}).';
        return ApiResponse(
          success: false,
          message: errMsg,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Koneksi jaringan gagal atau server timeout saat memproses biometrik.',
      );
    }
  }

  /// 6. Attendance History
  static Future<ApiResponse<List<HistoryItem>>> getHistory({int limit = 30}) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.riwayat}?limit=$limit'),
        headers: _headers(withAuth: true),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        var rawList = body['riwayat'] as List<dynamic>? ?? [];
        List<HistoryItem> items = rawList
            .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          message: 'Riwayat berhasil dimuat.',
          data: items,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Gagal memuat riwayat.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Koneksi jaringan gagal.',
      );
    }
  }

  /// 6. Update Siswa Profile (Username, Bio, Website, Nama Ortu, No HP Ortu, Avatar, Banner)
  static Future<ApiResponse<UserModel>> updateProfile({
    required String username,
    String? bio,
    String? website,
    String? namaOrtu,
    String? noHpOrtu,
    XFile? avatarFile,
    XFile? bannerFile,
    bool removeAvatar = false,
    bool removeBanner = false,
  }) async {
    try {
      final token = StorageService.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}/siswa/profile');
      final request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      request.fields['username'] = username;
      request.fields['bio'] = bio ?? '';
      request.fields['website'] = website ?? '';
      request.fields['nama_ortu'] = namaOrtu ?? '';
      request.fields['no_hp_ortu'] = noHpOrtu ?? '';
      if (removeAvatar) request.fields['remove_avatar'] = '1';
      if (removeBanner) request.fields['remove_banner'] = '1';

      if (avatarFile != null) {
        final bytes = await avatarFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'avatar',
          bytes,
          filename: avatarFile.name,
        ));
      }

      if (bannerFile != null) {
        final bytes = await bannerFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'banner',
          bytes,
          filename: bannerFile.name,
        ));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final updatedUser = UserModel.fromJson(body['user']);
        await StorageService.saveUser(updatedUser);
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Profil berhasil diperbarui!',
          data: updatedUser,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Gagal memperbarui profil.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Koneksi gagal atau ukuran file melebihi batas.',
      );
    }
  }
}

