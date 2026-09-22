class AssignmentModel {
  final int assignmentId;
  final String title;
  final String? description;
  final String? instructions;
  final dynamic startDate;
  final dynamic dueDate;
  final int maxScore;
  final String? supportingFileUrl;
  final bool allowResubmission;
  final int? courseId;
  final String? courseTitle;
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
    this.allowResubmission = true,
    this.courseId,
    this.courseTitle,
    this.status,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      assignmentId: json['assignmentId'] as int? ?? json['id'] as int? ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      instructions: json['instructions'],
      startDate: json['startDate'],
      dueDate: json['dueDate'],
      maxScore: json['maxScore'] as int? ?? 100,
      supportingFileUrl: json['supportingFileUrl'],
      allowResubmission: json['allowResubmission'] ?? true,
      courseId: json['courseId'] as int?,
      courseTitle: json['courseTitle'],
      status: json['status'],
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
        'allowResubmission': allowResubmission,
        if (courseId != null) 'courseId': courseId,
      };
}

class AssignmentSubmissionModel {
  final int submissionId;
  final int? assignmentId;
  final String? assignmentTitle;
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
      submissionId: json['submissionId'] as int? ?? json['id'] as int? ?? 0,
      assignmentId: json['assignmentId'] as int?,
      assignmentTitle: json['assignmentTitle'],
      studentName: json['studentName'] ?? json['userName'],
      studentEmail: json['studentEmail'] ?? json['userEmail'],
      textSubmission: json['textSubmission'],
      fileUrl: json['fileUrl'],
      filePublicId: json['filePublicId'],
      submittedAt: json['submittedAt'],
      status: (json['status'] ?? 'NOT_SUBMITTED').toString(),
      score: json['score'] as num?,
      grade: json['grade']?.toString(),
      feedback: json['feedback'],
      gradedAt: json['gradedAt'],
    );
  }

  bool get isGraded => status == 'GRADED' || score != null;
}
