import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _api;

  NotificationRepository(this._api);

  Future<int> getUnreadCount() async {
    try {
      final response = await _api.get(ApiEndpoints.notificationsUnreadCount);
      if (response is int) return response;
      if (response is Map && response.containsKey('count')) {
        return (response['count'] as num).toInt();
      }
      if (response is Map && response.containsKey('unreadCount')) {
        return (response['unreadCount'] as num).toInt();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<NotificationItem>> getNotifications() async {
    final response = await _api.get(ApiEndpoints.notifications);
    if (response is List) {
      return response
          .map((n) => NotificationItem.fromJson(n as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> markRead(int id) async {
    await _api.patch(ApiEndpoints.notificationRead(id));
  }

  Future<void> markAllRead() async {
    await _api.patch(ApiEndpoints.notificationsReadAll);
  }
}
