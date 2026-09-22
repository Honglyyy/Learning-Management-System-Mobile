import 'package:dio/dio.dart';

class ApiError implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiError({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiError.fromDioException(DioException error) {
    String message = 'An unexpected network error occurred.';
    int? statusCode = error.response?.statusCode;
    dynamic data = error.response?.data;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Please check your internet connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Unable to connect to the server. Please verify your connection.';
    } else if (error.response != null) {
      if (data is Map<String, dynamic>) {
        if (data.containsKey('message') && data['message'] != null && data['message'].toString().isNotEmpty) {
          message = data['message'].toString();
        } else if (data.containsKey('error') && data['error'] != null && data['error'].toString().isNotEmpty) {
          message = data['error'].toString();
        } else if (data.containsKey('detail') && data['detail'] != null) {
          message = data['detail'].toString();
        }
      } else if (data is String && data.isNotEmpty) {
        message = data;
      } else {
        message = 'Request failed with status: ${statusCode ?? "unknown"}';
      }
    } else if (error.message != null && error.message!.trim().isNotEmpty) {
      message = error.message!.trim();
    } else if (error.error != null) {
      message = error.error.toString();
    }

    return ApiError(
      message: message,
      statusCode: statusCode,
      data: data,
    );
  }

  @override
  String toString() => message;
}
