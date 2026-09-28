class ContinueLearningItem {
  final int courseId;
  final String courseTitle;
  final String? coverUrl;
  final int? lessonId;
  final String? lessonTitle;
  final double progressPercent;

  ContinueLearningItem({
    required this.courseId,
    required this.courseTitle,
    this.coverUrl,
    this.lessonId,
    this.lessonTitle,
    this.progressPercent = 0.0,
  });

  factory ContinueLearningItem.fromJson(Map<String, dynamic> json) {
    return ContinueLearningItem(
      courseId: json['courseId'] as int? ?? json['id'] as int? ?? 0,
      courseTitle: json['courseTitle'] ?? json['title'] ?? '',
      coverUrl: json['coverUrl'] ?? json['courseCoverUrl'],
      lessonId: json['lessonId'] as int?,
      lessonTitle: json['lessonTitle'],
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ??
          (json['progress'] as num?)?.toDouble() ??
          0.0,
    );
  }
}

class EnrollmentModel {
  final int enrollmentId;
  final int? userId;
  final String? userName;
  final String? userEmail;
  final int courseId;
  final String courseTitle;
  final String? courseCoverUrl;
  final String? instructorName;
  final String status;
  final int earnedPoints;
  final int totalPoints;
  final double progressPercent;
  final dynamic enrolledAt;
  final dynamic completedAt;
  final dynamic expirationDate;
  final bool isExpired;
  final int? daysRemaining;

  EnrollmentModel({
    required this.enrollmentId,
    this.userId,
    this.userName,
    this.userEmail,
    required this.courseId,
    required this.courseTitle,
    this.courseCoverUrl,
    this.instructorName,
    this.status = 'ACTIVE',
    this.earnedPoints = 0,
    this.totalPoints = 0,
    this.progressPercent = 0.0,
    this.enrolledAt,
    this.completedAt,
    this.expirationDate,
    this.isExpired = false,
    this.daysRemaining,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] ?? 'ACTIVE').toString();
    final expiredFlag = (json['isExpired'] as bool?) ?? (statusStr == 'EXPIRED');

    return EnrollmentModel(
      enrollmentId: json['enrollmentId'] as int? ?? json['id'] as int? ?? 0,
      userId: json['userId'] as int?,
      userName: json['userName'] ?? json['studentName'],
      userEmail: json['userEmail'] ?? json['studentEmail'],
      courseId: json['courseId'] as int? ?? 0,
      courseTitle: json['courseTitle'] ?? json['title'] ?? '',
      courseCoverUrl: json['courseCoverUrl'] ?? json['coverUrl'],
      instructorName: json['instructorName'] ?? json['instructor'],
      status: statusStr,
      earnedPoints: json['earnedPoints'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ??
          (json['progress'] as num?)?.toDouble() ??
          0.0,
      enrolledAt: json['enrolledAt'] ?? json['createdAt'],
      completedAt: json['completedAt'],
      expirationDate: json['expirationDate'],
      isExpired: expiredFlag,
      daysRemaining: (json['daysRemaining'] as num?)?.toInt(),
    );
  }

  bool get isEnrollmentExpired => isExpired || status == 'EXPIRED';
  bool get isCompleted => (status == 'COMPLETED' || progressPercent >= 100.0) && !isEnrollmentExpired;
  bool get isActive => status == 'ACTIVE' && !isEnrollmentExpired;
  bool get isExpiringSoon => daysRemaining != null && daysRemaining! <= 7 && daysRemaining! >= 0;
}
