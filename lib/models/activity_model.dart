class ActivityLog {
  final int id;
  final String activityType;
  final String description;
  final dynamic timestamp;

  ActivityLog({
    required this.id,
    required this.activityType,
    required this.description,
    this.timestamp,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as int? ?? 0,
      activityType: (json['activityType'] ?? json['type'] ?? 'GENERAL').toString(),
      description: json['description'] ?? json['message'] ?? '',
      timestamp: json['timestamp'] ?? json['createdAt'],
    );
  }
}
