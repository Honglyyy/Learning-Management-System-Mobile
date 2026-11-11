import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/assignment_model.dart';

class AssignmentRepository {
  final ApiClient _api;

  AssignmentRepository(this._api);

  Future<List<AssignmentModel>> getCourseAssignments(int courseId) async {
    final response = await _api.get(ApiEndpoints.courseAssignments(courseId));
    if (response is List) {
      return response
          .map((a) => AssignmentModel.fromJson(a as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<AssignmentSubmissionModel?> getSubmissionMe(int assignmentId) async {
    try {
      final response = await _api.get(ApiEndpoints.assignmentSubmissionMe(assignmentId));
      if (response != null && response is Map<String, dynamic>) {
        return AssignmentSubmissionModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  Future<void> submitAssignment(
    int assignmentId, {
    String? textSubmission,
    String? fileUrl,
    String? filePublicId,
  }) async {
    await _api.post(
      ApiEndpoints.assignmentSubmit(assignmentId),
      data: {
        'textSubmission': textSubmission,
        'fileUrl': fileUrl,
        'filePublicId': filePublicId,
      },
    );
  }

  Future<List<AssignmentSubmissionModel>> getSubmissions(int assignmentId) async {
    final response = await _api.get(ApiEndpoints.assignmentSubmissions(assignmentId));
    if (response is List) {
      return response
          .map((s) => AssignmentSubmissionModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> gradeSubmission(
    int submissionId, {
    num? score,
    String? grade,
    String? feedback,
  }) async {
    final body = <String, dynamic>{};
    if (score != null) body['score'] = score;
    if (grade != null && grade.trim().isNotEmpty) body['grade'] = grade.trim();
    if (feedback != null && feedback.trim().isNotEmpty) body['feedback'] = feedback.trim();
    await _api.put(
      ApiEndpoints.gradeSubmission(submissionId),
      data: body,
    );
  }

  Future<List<AssignmentModel>> getAssignments() async {
    final response = await _api.get(ApiEndpoints.assignments);
    if (response is List) {
      return response
          .map((a) => AssignmentModel.fromJson(a as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> createAssignment(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.assignments, data: body);
  }

  Future<void> updateAssignment(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.assignmentById(id), data: body);
  }

  Future<void> deleteAssignment(int id) async {
    await _api.delete(ApiEndpoints.assignmentById(id));
  }
}
