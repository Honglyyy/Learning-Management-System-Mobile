import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/enrollment_model.dart';

class EnrollmentRepository {
  final ApiClient _api;

  EnrollmentRepository(this._api);

  Future<List<EnrollmentModel>> getMyEnrollments() async {
    final response = await _api.get(ApiEndpoints.enrollmentsMe);
    if (response is List) {
      return response
          .map((e) => EnrollmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> enrollCourse(int courseId) async {
    await _api.post(
      ApiEndpoints.enrollments,
      data: {'courseId': courseId},
    );
  }

  Future<void> cancelEnrollmentMe(int courseId) async {
    await _api.delete(ApiEndpoints.cancelEnrollmentMe(courseId));
  }

  Future<ContinueLearningItem?> getContinueLearning() async {
    try {
      final response = await _api.get(ApiEndpoints.learningContinue);
      if (response != null && response is Map<String, dynamic>) {
        return ContinueLearningItem.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  Future<List<EnrollmentModel>> getAllEnrollments({int? courseId}) async {
    final response = await _api.get(
      ApiEndpoints.enrollments,
      queryParameters: courseId != null ? {'courseId': courseId} : null,
    );
    if (response is List) {
      return response
          .map((e) => EnrollmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> updateEnrollmentStatus(int enrollmentId, String status) async {
    await _api.patch(
      ApiEndpoints.enrollmentStatus(enrollmentId),
      data: {'status': status},
    );
  }

  Future<void> deleteEnrollment(int enrollmentId) async {
    await _api.delete(ApiEndpoints.enrollmentById(enrollmentId));
  }

  Future<void> manualEnroll(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.enrollmentsManage, data: body);
  }
}
