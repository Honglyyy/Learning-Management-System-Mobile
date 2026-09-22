import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/section_model.dart';

class SectionRepository {
  final ApiClient _api;

  SectionRepository(this._api);

  Future<List<SectionModel>> getSections({int? courseId}) async {
    final response = await _api.get(
      ApiEndpoints.sections,
      queryParameters: courseId != null ? {'courseId': courseId} : null,
    );
    if (response is List) {
      return response
          .map((item) => SectionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<SectionModel>> getInstructorSections({int? courseId}) async {
    final response = await _api.get(
      ApiEndpoints.instructorSectionsMe,
      queryParameters: courseId != null ? {'courseId': courseId} : null,
    );
    if (response is List) {
      return response
          .map((item) => SectionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> createSection(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.sections, data: body);
  }

  Future<void> updateSection(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.sectionById(id), data: body);
  }

  Future<void> deleteSection(int id) async {
    await _api.delete(ApiEndpoints.sectionById(id));
  }

  Future<void> createInstructorSection(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.instructorSectionsMe, data: body);
  }

  Future<void> updateInstructorSection(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.instructorSectionMeById(id), data: body);
  }

  Future<void> deleteInstructorSection(int id) async {
    await _api.delete(ApiEndpoints.instructorSectionMeById(id));
  }
}
