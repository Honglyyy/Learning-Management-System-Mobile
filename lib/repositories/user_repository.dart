import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';

class UserRepository {
  final ApiClient _api;

  UserRepository(this._api);

  Future<List<UserModel>> getAllUsers() async {
    final response = await _api.get(ApiEndpoints.users);
    if (response is List) {
      return response
          .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> updateUser(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.userById(id), data: body);
  }

  Future<void> changeUserRole(int id, String role) async {
    await _api.put(
      ApiEndpoints.userRole(id),
      data: {'role': role},
    );
  }

  Future<void> deleteUser(int id) async {
    await _api.delete(ApiEndpoints.userById(id));
  }

  Future<void> createAdmin(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.adminRegister, data: body);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _api.post(
      ApiEndpoints.changePassword,
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<List<ActivityLog>> getActivities() async {
    final response = await _api.get(ApiEndpoints.userActivities);
    if (response is List) {
      return response
          .map((a) => ActivityLog.fromJson(a as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
