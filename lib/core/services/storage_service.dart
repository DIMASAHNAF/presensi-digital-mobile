import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Save Token
  static Future<bool> saveToken(String token) async {
    await init();
    return await _prefs!.setString(_keyToken, token);
  }

  // Get Token
  static String? getToken() {
    return _prefs?.getString(_keyToken);
  }

  // Check if logged in
  static bool isLoggedIn() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  // Save User
  static Future<bool> saveUser(UserModel user) async {
    await init();
    return await _prefs!.setString(_keyUser, jsonEncode(user.toJson()));
  }

  // Get User
  static UserModel? getUser() {
    final raw = _prefs?.getString(_keyUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  // Clear Session / Logout
  static Future<void> clear() async {
    await init();
    await _prefs!.remove(_keyToken);
    await _prefs!.remove(_keyUser);
  }
}
