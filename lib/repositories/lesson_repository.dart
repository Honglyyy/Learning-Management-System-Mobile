import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/lesson_model.dart';

class LessonRepository {
  final ApiClient _api;

  LessonRepository(this._api);

  Future<List<LessonModel>> getLessons({int? sectionId}) async {
    final response = await _api.get(
      ApiEndpoints.lessons,
      queryParameters: sectionId != null ? {'sectionId': sectionId} : null,
    );
    if (response is List) {
      final list = response
          .map((item) => LessonModel.fromJson(item as Map<String, dynamic>))
          .toList();
      list.sort((a, b) {
        final cmp = a.orderIndex.compareTo(b.orderIndex);
        if (cmp != 0) return cmp;
        return a.lessonId.compareTo(b.lessonId);
      });
      return list;
    }
    return [];
  }

  Future<List<LessonModel>> getInstructorLessons({int? sectionId, int? courseId}) async {
    final queryParams = <String, dynamic>{};
    if (sectionId != null) queryParams['sectionId'] = sectionId;
    if (courseId != null) queryParams['courseId'] = courseId;
    final response = await _api.get(
      ApiEndpoints.instructorLessonsMe,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    if (response is List) {
      final list = response
          .map((item) => LessonModel.fromJson(item as Map<String, dynamic>))
          .toList();
      list.sort((a, b) {
        final cmp = a.orderIndex.compareTo(b.orderIndex);
        if (cmp != 0) return cmp;
        return a.lessonId.compareTo(b.lessonId);
      });
      return list;
    }
    return [];
  }

  Future<LessonModel> getLessonById(int id) async {
    final response = await _api.get(ApiEndpoints.lessonById(id));
    return LessonModel.fromJson(response as Map<String, dynamic>);
  }

  Future<LessonNavigation> getLessonNavigation(int lessonId) async {
    final response = await _api.get(ApiEndpoints.lessonNavigation(lessonId));
    return LessonNavigation.fromJson(response as Map<String, dynamic>);
  }

  Future<LessonProgress> getLessonProgress(int lessonId) async {
    final response = await _api.get(ApiEndpoints.lessonProgress(lessonId));
    return LessonProgress.fromJson(response as Map<String, dynamic>);
  }

  Future<void> saveLessonProgress(int lessonId, int seconds) async {
    await _api.post(
      '${ApiEndpoints.lessonProgress(lessonId)}?seconds=$seconds',
    );
  }

  Future<void> markLessonComplete(int lessonId) async {
    await _api.post(ApiEndpoints.lessonComplete(lessonId));
  }

  Future<List<LessonMaterial>> getLessonMaterials(int lessonId) async {
    final response = await _api.get(ApiEndpoints.lessonMaterials(lessonId));
    if (response is List) {
      return response
          .map((item) => LessonMaterial.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> createMaterial(int lessonId, Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.lessonMaterials(lessonId), data: body);
  }

  Future<void> deleteMaterial(int materialId) async {
    await _api.delete(ApiEndpoints.materialById(materialId));
  }

  Future<void> createLesson(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.lessons, data: body);
  }

  Future<void> updateLesson(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.lessonById(id), data: body);
  }

  Future<void> deleteLesson(int id) async {
    await _api.delete(ApiEndpoints.lessonById(id));
  }

  Future<void> createInstructorLesson(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.instructorLessonsMe, data: body);
  }

  Future<void> updateInstructorLesson(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.instructorLessonMeById(id), data: body);
  }

  Future<void> deleteInstructorLesson(int id) async {
    await _api.delete(ApiEndpoints.instructorLessonMeById(id));
  }
}
