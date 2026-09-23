import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class UploadResult {
  final String url;
  final String publicId;
  final String? originalFileName;
  final int? size;

  UploadResult({
    required this.url,
    required this.publicId,
    this.originalFileName,
    this.size,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      url: json['url']?.toString() ?? '',
      publicId: json['publicId']?.toString() ?? '',
      originalFileName: json['originalFileName']?.toString(),
      size: json['size'] is num ? (json['size'] as num).toInt() : null,
    );
  }
}

class UploadRepository {
  final ApiClient _api;

  UploadRepository(this._api);

  Future<String> uploadCourseCover(File file) async {
    final res = await _api.uploadFile(ApiEndpoints.uploadCourseCover, file: file);
    if (res is Map && res.containsKey('url')) return res['url'].toString();
    return res.toString();
  }

  Future<UploadResult> uploadCourseCoverBytes(
    List<int> bytes,
    String filename, {
    ProgressCallback? onSendProgress,
  }) async {
    final res = await _api.uploadBytes(
      ApiEndpoints.uploadCourseCover,
      bytes: bytes,
      filename: filename,
      onSendProgress: onSendProgress,
    );
    if (res is Map<String, dynamic>) {
      return UploadResult.fromJson(res);
    }
    return UploadResult(url: res.toString(), publicId: '');
  }

  Future<String> uploadLessonVideo(
    File file, {
    ProgressCallback? onSendProgress,
  }) async {
    final res = await _api.uploadFile(
      ApiEndpoints.uploadLessonVideo,
      file: file,
      onSendProgress: onSendProgress,
    );
    if (res is Map && res.containsKey('url')) return res['url'].toString();
    return res.toString();
  }

  Future<UploadResult> uploadLessonVideoBytes(
    List<int> bytes,
    String filename, {
    ProgressCallback? onSendProgress,
  }) async {
    final res = await _api.uploadBytes(
      ApiEndpoints.uploadLessonVideo,
      bytes: bytes,
      filename: filename,
      onSendProgress: onSendProgress,
    );
    if (res is Map<String, dynamic>) {
      return UploadResult.fromJson(res);
    }
    return UploadResult(url: res.toString(), publicId: '');
  }

  Future<String> uploadMaterial(File file) async {
    final res = await _api.uploadFile(ApiEndpoints.uploadMaterial, file: file);
    if (res is Map && res.containsKey('url')) return res['url'].toString();
    return res.toString();
  }

  Future<UploadResult> uploadMaterialBytes(
    List<int> bytes,
    String filename, {
    ProgressCallback? onSendProgress,
  }) async {
    final res = await _api.uploadBytes(
      ApiEndpoints.uploadMaterial,
      bytes: bytes,
      filename: filename,
      onSendProgress: onSendProgress,
    );
    if (res is Map<String, dynamic>) {
      return UploadResult.fromJson(res);
    }
    return UploadResult(url: res.toString(), publicId: '');
  }

  Future<Map<String, String>> uploadAssignmentFile(File file) async {
    final res = await _api.uploadFile(ApiEndpoints.uploadAssignmentFile, file: file);
    if (res is Map) {
      return {
        'url': res['url']?.toString() ?? '',
        'publicId': res['publicId']?.toString() ?? '',
      };
    }
    return {'url': res.toString(), 'publicId': ''};
  }
  Future<Map<String, String>> uploadAssignmentFileBytes(
    List<int> bytes,
    String filename, {
    ProgressCallback? onSendProgress,
  }) async {
    final res = await _api.uploadBytes(
      ApiEndpoints.uploadAssignmentFile,
      bytes: bytes,
      filename: filename,
      onSendProgress: onSendProgress,
    );
    if (res is Map) {
      return {
        'url': res['url']?.toString() ?? '',
        'publicId': res['publicId']?.toString() ?? '',
      };
    }
    return {'url': res.toString(), 'publicId': ''};
  }
}
