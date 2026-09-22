class CertificateModel {
  final int certificateId;
  final String certificateCode;
  final dynamic issuedAt;
  final num? finalScore;
  final int? userId;
  final int? courseId;
  final String? courseTitle;
  final String? recipientName;
  final String? instructorName;

  CertificateModel({
    required this.certificateId,
    required this.certificateCode,
    this.issuedAt,
    this.finalScore,
    this.userId,
    this.courseId,
    this.courseTitle,
    this.recipientName,
    this.instructorName,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      certificateId: json['certificateId'] as int? ?? json['id'] as int? ?? 0,
      certificateCode: json['certificateCode'] ?? json['code'] ?? '',
      issuedAt: json['issuedAt'] ?? json['createdAt'],
      finalScore: json['finalScore'] as num?,
      userId: json['userId'] as int?,
      courseId: json['courseId'] as int?,
      courseTitle: json['courseTitle'] ?? json['course'] ?? 'Course',
      recipientName: json['recipientName'] ?? json['userName'],
      instructorName: json['instructorName'] ?? json['instructor'],
    );
  }
}

class CertificateVerification {
  final bool verified;
  final String certificateCode;
  final String recipientName;
  final String courseTitle;
  final dynamic issuedAt;
  final String? instructorName;
  final String? programDuration;
  final num? finalScore;

  CertificateVerification({
    this.verified = true,
    required this.certificateCode,
    required this.recipientName,
    required this.courseTitle,
    this.issuedAt,
    this.instructorName,
    this.programDuration,
    this.finalScore,
  });

  factory CertificateVerification.fromJson(Map<String, dynamic> json) {
    return CertificateVerification(
      verified: json['verified'] ?? true,
      certificateCode: json['certificateCode'] ?? json['code'] ?? '',
      recipientName: json['recipientName'] ?? json['studentName'] ?? 'Recipient',
      courseTitle: json['courseTitle'] ?? json['course'] ?? 'Course',
      issuedAt: json['issuedAt'],
      instructorName: json['instructorName'] ?? json['instructor'],
      programDuration: json['programDuration'] ?? json['duration'],
      finalScore: json['finalScore'] as num?,
    );
  }
}
