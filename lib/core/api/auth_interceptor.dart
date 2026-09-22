import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

typedef SessionExpiredCallback = void Function(String reason);

class AuthInterceptor extends Interceptor {
  final SharedPreferences _prefs;
  final SessionExpiredCallback? onSessionExpired;

  AuthInterceptor(this._prefs, {this.onSessionExpired});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _prefs.getString(AppConstants.keyToken);

    if (token != null && token.isNotEmpty) {
      if (JwtDecoder.isExpired(token)) {
        _prefs.remove(AppConstants.keyToken);
        _prefs.remove(AppConstants.keyUserRole);
        _prefs.remove(AppConstants.keyUserEmail);
        onSessionExpired?.call('token_expired');
        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: {'message': 'Session has expired. Please sign in again.'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );
      }
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      final token = _prefs.getString(AppConstants.keyToken);
      if (token != null) {
        _prefs.remove(AppConstants.keyToken);
        _prefs.remove(AppConstants.keyUserRole);
        _prefs.remove(AppConstants.keyUserEmail);
        onSessionExpired?.call('unauthorized');
      }
    }
    return handler.next(err);
  }
}
