class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? actionUrl;
  final dynamic createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'SYSTEM',
    this.isRead = false,
    this.actionUrl,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int? ?? json['notificationId'] as int? ?? 0,
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? json['content'] ?? '',
      type: (json['type'] ?? 'SYSTEM').toString(),
      isRead: json['isRead'] ?? json['read'] ?? false,
      actionUrl: json['actionUrl'],
      createdAt: json['createdAt'],
    );
  }
}
