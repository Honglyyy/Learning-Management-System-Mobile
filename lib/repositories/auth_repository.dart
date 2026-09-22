import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/constants/app_constants.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final ApiClient _api;
  final SharedPreferences _prefs;

  AuthRepository(this._api, this._prefs);

  Future<String> login(String emailOrUsername, String password) async {
    final response = await _api.post(
      ApiEndpoints.authenticate,
      data: {'email': emailOrUsername, 'password': password},
      options: Options(
        responseType: ResponseType.plain,
        headers: {
          'Accept': '*/*',
        },
      ),
    );

    // Backend returns token either as plain string or inside json { "token": "..." }
    String token = '';
    if (response is String) {
      token = response.trim();
      if (token.startsWith('{') && token.endsWith('}')) {
        try {
          final decoded = jsonDecode(token);
          if (decoded is Map) {
            token = (decoded['token'] ?? decoded['jwt'] ?? token).toString();
          }
        } catch (_) {}
      }
    } else if (response is Map<String, dynamic>) {
      token = (response['token'] ?? response['jwt'] ?? '').toString();
    }

    if (token.isNotEmpty) {
      await _prefs.setString(AppConstants.keyToken, token);
      final decoded = JwtDecoder.decode(token);
      final role = (decoded['role'] ?? 'STUDENT').toString().toUpperCase();
      final email = (decoded['email'] ?? decoded['sub'] ?? '').toString();
      await _prefs.setString(AppConstants.keyUserRole, role);
      await _prefs.setString(AppConstants.keyUserEmail, email);
    }

    return token;
  }

  Future<void> register(RegisterRequest req) async {
    await _api.post(
      ApiEndpoints.register,
      data: req.toJson(),
    );
  }

  Future<void> verifyOtp(String email, String otp) async {
    await _api.post(
      ApiEndpoints.verifyOtp,
      data: {'email': email, 'otp': otp},
    );
  }

  Future<void> resendOtp(String email) async {
    await _api.post(
      ApiEndpoints.resendOtp,
      data: {'email': email},
    );
  }

  Future<void> sendResetOtp(String email) async {
    await _api.post(
      '${ApiEndpoints.sendResetOtp}?email=${Uri.encodeComponent(email)}',
    );
  }

  Future<void> resetPassword(String email, String otp, String password) async {
    await _api.post(
      ApiEndpoints.resetPassword,
      data: {'email': email, 'otp': otp, 'password': password},
    );
  }

  Future<SessionResponse?> getSession() async {
    try {
      final res = await _api.get(ApiEndpoints.authSession);
      if (res is Map<String, dynamic>) {
        return SessionResponse.fromJson(res);
      }
    } catch (_) {}
    return null;
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.authLogout);
    } catch (_) {}
    await _prefs.remove(AppConstants.keyToken);
    await _prefs.remove(AppConstants.keyUserRole);
    await _prefs.remove(AppConstants.keyUserEmail);
    await _prefs.remove(AppConstants.keyLastActivity);
  }

  String? getToken() => _prefs.getString(AppConstants.keyToken);

  String? getUserRole() => _prefs.getString(AppConstants.keyUserRole);

  String? getUserEmail() => _prefs.getString(AppConstants.keyUserEmail);

  bool get isAuthenticated {
    final token = getToken();
    if (token == null || token.isEmpty) return false;
    return !JwtDecoder.isExpired(token);
  }

  AuthClaims? getClaims() {
    final token = getToken();
    if (token == null || token.isEmpty) return null;
    try {
      return AuthClaims.fromMap(JwtDecoder.decode(token));
    } catch (_) {
      return null;
    }
  }
}
