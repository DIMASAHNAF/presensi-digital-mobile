import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/history_model.dart';
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

  /// 2. Get Student Profile
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
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.scanWajah),
        headers: _headers(withAuth: true),
        body: jsonEncode({
          'image': imageBase64,
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'is_mocked': isMocked,
        }),
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

  /// 5. Attendance History
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
}
