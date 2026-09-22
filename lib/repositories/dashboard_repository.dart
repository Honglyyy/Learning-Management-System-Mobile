import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/dashboard_models.dart';

class DashboardRepository {
  final ApiClient _api;

  DashboardRepository(this._api);

  Future<AdminDashboardDTO> getAdminDashboard() async {
    final response = await _api.get(ApiEndpoints.dashboardAdmin);
    return AdminDashboardDTO.fromJson(response as Map<String, dynamic>);
  }

  Future<InstructorDashboardDTO> getInstructorDashboard() async {
    final response = await _api.get(ApiEndpoints.dashboardInstructor);
    return InstructorDashboardDTO.fromJson(response as Map<String, dynamic>);
  }

  Future<EnrollmentReportDTO> getEnrollmentReports() async {
    final response = await _api.get(ApiEndpoints.reportsEnrollments);
    return EnrollmentReportDTO.fromJson(response as Map<String, dynamic>);
  }

  Future<ProgressReportDTO> getProgressReports() async {
    final response = await _api.get(ApiEndpoints.reportsProgress);
    return ProgressReportDTO.fromJson(response as Map<String, dynamic>);
  }

  Future<QuizReportDTO> getQuizReports() async {
    final response = await _api.get(ApiEndpoints.reportsQuizzes);
    return QuizReportDTO.fromJson(response as Map<String, dynamic>);
  }
}
