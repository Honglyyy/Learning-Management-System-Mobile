import 'dart:io';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/student_model.dart';

class StudentRepository {
  final ApiClient _api;

  StudentRepository(this._api);

  Future<StudentProfile> getProfile() async {
    final response = await _api.get(ApiEndpoints.studentProfile);
    return StudentProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<StudentProfile> updateProfile(Map<String, dynamic> body) async {
    final response = await _api.put(ApiEndpoints.studentProfile, data: body);
    return StudentProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<String> uploadPhoto(File file) async {
    final response = await _api.uploadFile(
      ApiEndpoints.studentProfilePhoto,
      file: file,
    );
    if (response is Map && response.containsKey('url')) {
      return response['url'].toString();
    }
    return '';
  }
  Future<String> uploadPhotoBytes(List<int> bytes, String filename) async {
    final response = await _api.uploadBytes(
      ApiEndpoints.studentProfilePhoto,
      bytes: bytes,
      filename: filename,
    );
    if (response is Map && response.containsKey('url')) {
      return response['url'].toString();
    }
    return '';
  }
}
