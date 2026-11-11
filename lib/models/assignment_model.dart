class AssignmentModel {
  final int assignmentId;
  final String title;
  final String? description;
  final String? instructions;
  final dynamic startDate;
  final dynamic dueDate;
  final int maxScore;
  final String? supportingFileUrl;
  final String? supportingFilePublicId;
  final bool allowResubmission;
  final int? courseId;
  final String? courseTitle;
  final int? sectionId;
  final String? sectionTitle;
  final String? status;

  AssignmentModel({
    required this.assignmentId,
    required this.title,
    this.description,
    this.instructions,
    this.startDate,
    this.dueDate,
    this.maxScore = 100,
    this.supportingFileUrl,
    this.supportingFilePublicId,
    this.allowResubmission = true,
    this.courseId,
    this.courseTitle,
    this.sectionId,
    this.sectionTitle,
    this.status,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      assignmentId: (json['assignmentId'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      instructions: json['instructions']?.toString(),
      startDate: json['startDate'],
      dueDate: json['dueDate'],
      maxScore: (json['maxScore'] as num?)?.toInt() ?? 100,
      supportingFileUrl: json['supportingFileUrl']?.toString(),
      supportingFilePublicId: json['supportingFilePublicId']?.toString(),
      allowResubmission: json['allowResubmission'] as bool? ?? true,
      courseId: (json['courseId'] as num?)?.toInt(),
      courseTitle: json['courseTitle']?.toString(),
      sectionId: (json['sectionId'] as num?)?.toInt(),
      sectionTitle: json['sectionTitle']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'assignmentId': assignmentId,
        'title': title,
        'description': description,
        'instructions': instructions,
        'startDate': startDate,
        'dueDate': dueDate,
        'maxScore': maxScore,
        'supportingFileUrl': supportingFileUrl,
        if (supportingFilePublicId != null)
          'supportingFilePublicId': supportingFilePublicId,
        'allowResubmission': allowResubmission,
        if (courseId != null) 'courseId': courseId,
        if (sectionId != null) 'sectionId': sectionId,
      };
}

class AssignmentSubmissionModel {
  final int submissionId;
  final int? assignmentId;
  final String? assignmentTitle;
  final int? studentId;
  final String? studentName;
  final String? studentEmail;
  final String? textSubmission;
  final String? fileUrl;
  final String? filePublicId;
  final dynamic submittedAt;
  final String status;
  final num? score;
  final String? grade;
  final String? feedback;
  final dynamic gradedAt;

  AssignmentSubmissionModel({
    required this.submissionId,
    this.assignmentId,
    this.assignmentTitle,
    this.studentId,
    this.studentName,
    this.studentEmail,
    this.textSubmission,
    this.fileUrl,
    this.filePublicId,
    this.submittedAt,
    this.status = 'NOT_SUBMITTED',
    this.score,
    this.grade,
    this.feedback,
    this.gradedAt,
  });

  factory AssignmentSubmissionModel.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmissionModel(
      submissionId: (json['submissionId'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      assignmentId: (json['assignmentId'] as num?)?.toInt(),
      assignmentTitle: json['assignmentTitle']?.toString(),
      studentId: (json['studentId'] as num?)?.toInt(),
      studentName: (json['studentName'] ?? json['userName'])?.toString(),
      studentEmail: (json['studentEmail'] ?? json['userEmail'])?.toString(),
      textSubmission: json['textSubmission']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
      filePublicId: json['filePublicId']?.toString(),
      submittedAt: json['submittedAt'],
      status: (json['status'] ?? 'NOT_SUBMITTED').toString(),
      score: json['score'] as num?,
      grade: json['grade']?.toString(),
      feedback: json['feedback']?.toString(),
      gradedAt: json['gradedAt'],
    );
  }

  bool get isGraded => status == 'GRADED' || score != null;
}
