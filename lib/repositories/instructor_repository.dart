import 'dart:io';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/instructor_model.dart';

class InstructorRepository {
  final ApiClient _api;

  InstructorRepository(this._api);

  Future<List<InstructorModel>> getAllInstructors() async {
    final response = await _api.get(ApiEndpoints.instructors);
    if (response is List) {
      return response
          .map((i) => InstructorModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<InstructorModel> getInstructorById(int id) async {
    final response = await _api.get(ApiEndpoints.instructorById(id));
    return InstructorModel.fromJson(response as Map<String, dynamic>);
  }

  Future<InstructorModel> getMyProfile() async {
    final response = await _api.get(ApiEndpoints.instructorMe);
    return InstructorModel.fromJson(response as Map<String, dynamic>);
  }

  Future<InstructorModel> updateMyProfile(Map<String, dynamic> body) async {
    final response = await _api.put(ApiEndpoints.instructorMe, data: body);
    return InstructorModel.fromJson(response as Map<String, dynamic>);
  }

  Future<String> uploadPhoto(File file) async {
    final response = await _api.uploadFile(
      ApiEndpoints.instructorMePhoto,
      file: file,
    );
    if (response is Map && response.containsKey('url')) {
      return response['url'].toString();
    }
    return '';
  }
}
