class AdminDashboardDTO {
  final int totalStudents;
  final int totalInstructors;
  final int totalCourses;
  final int totalEnrollments;
  final int completedEnrollments;
  final double completionRate;
  final num grossRevenue;
  final int totalQuizzes;
  final int totalAssignments;

  AdminDashboardDTO({
    this.totalStudents = 0,
    this.totalInstructors = 0,
    this.totalCourses = 0,
    this.totalEnrollments = 0,
    this.completedEnrollments = 0,
    this.completionRate = 0.0,
    this.grossRevenue = 0,
    this.totalQuizzes = 0,
    this.totalAssignments = 0,
  });

  factory AdminDashboardDTO.fromJson(Map<String, dynamic> json) {
    return AdminDashboardDTO(
      totalStudents: json['totalStudents'] as int? ?? 0,
      totalInstructors: json['totalInstructors'] as int? ?? 0,
      totalCourses: json['totalCourses'] as int? ?? 0,
      totalEnrollments: json['totalEnrollments'] as int? ?? 0,
      completedEnrollments: json['completedEnrollments'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      grossRevenue: json['grossRevenue'] as num? ?? 0,
      totalQuizzes: json['totalQuizzes'] as int? ?? 0,
      totalAssignments: json['totalAssignments'] as int? ?? 0,
    );
  }
}

class InstructorDashboardDTO {
  final int totalCourses;
  final int totalStudents;
  final double averageRating;
  final num grossRevenue;

  InstructorDashboardDTO({
    this.totalCourses = 0,
    this.totalStudents = 0,
    this.averageRating = 0.0,
    this.grossRevenue = 0,
  });

  factory InstructorDashboardDTO.fromJson(Map<String, dynamic> json) {
    return InstructorDashboardDTO(
      totalCourses: json['totalCourses'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      grossRevenue: json['grossRevenue'] as num? ?? 0,
    );
  }
}

class MonthlyEnrollmentDTO {
  final String month;
  final int enrollmentCount;
  final int newLearnersCount;

  MonthlyEnrollmentDTO({
    required this.month,
    this.enrollmentCount = 0,
    this.newLearnersCount = 0,
  });

  factory MonthlyEnrollmentDTO.fromJson(Map<String, dynamic> json) {
    return MonthlyEnrollmentDTO(
      month: json['month'] ?? '',
      enrollmentCount: json['enrollmentCount'] as int? ?? 0,
      newLearnersCount: json['newLearnersCount'] as int? ?? 0,
    );
  }
}

class CourseEnrollmentDTO {
  final int courseId;
  final String courseTitle;
  final int totalEnrolled;
  final int activeStudents;
  final int completedStudents;

  CourseEnrollmentDTO({
    required this.courseId,
    required this.courseTitle,
    this.totalEnrolled = 0,
    this.activeStudents = 0,
    this.completedStudents = 0,
  });

  factory CourseEnrollmentDTO.fromJson(Map<String, dynamic> json) {
    return CourseEnrollmentDTO(
      courseId: json['courseId'] as int? ?? 0,
      courseTitle: json['courseTitle'] ?? '',
      totalEnrolled: json['totalEnrolled'] as int? ?? 0,
      activeStudents: json['activeStudents'] as int? ?? 0,
      completedStudents: json['completedStudents'] as int? ?? 0,
    );
  }
}

class EnrollmentReportDTO {
  final int totalEnrollments;
  final List<MonthlyEnrollmentDTO> monthlyBreakdown;
  final List<CourseEnrollmentDTO> courseBreakdown;

  EnrollmentReportDTO({
    this.totalEnrollments = 0,
    this.monthlyBreakdown = const [],
    this.courseBreakdown = const [],
  });

  factory EnrollmentReportDTO.fromJson(Map<String, dynamic> json) {
    final rawMonthly = json['monthlyBreakdown'] as List<dynamic>? ?? [];
    final rawCourse = json['courseBreakdown'] as List<dynamic>? ?? [];
    return EnrollmentReportDTO(
      totalEnrollments: json['totalEnrollments'] as int? ?? 0,
      monthlyBreakdown: rawMonthly.map((m) => MonthlyEnrollmentDTO.fromJson(m)).toList(),
      courseBreakdown: rawCourse.map((c) => CourseEnrollmentDTO.fromJson(c)).toList(),
    );
  }
}

class CourseProgressReportDTO {
  final int courseId;
  final String courseTitle;
  final int enrolledStudents;
  final double averageProgressPercent;
  final double completionRate;
  final double averageQuizScore;

  CourseProgressReportDTO({
    required this.courseId,
    required this.courseTitle,
    this.enrolledStudents = 0,
    this.averageProgressPercent = 0.0,
    this.completionRate = 0.0,
    this.averageQuizScore = 0.0,
  });

  factory CourseProgressReportDTO.fromJson(Map<String, dynamic> json) {
    return CourseProgressReportDTO(
      courseId: json['courseId'] as int? ?? 0,
      courseTitle: json['courseTitle'] ?? '',
      enrolledStudents: json['enrolledStudents'] as int? ?? 0,
      averageProgressPercent: (json['averageProgressPercent'] as num?)?.toDouble() ?? 0.0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      averageQuizScore: (json['averageQuizScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProgressReportDTO {
  final int totalStudentsEnrolled;
  final double overallCompletionRate;
  final double overallAverageQuizScore;
  final double assignmentSubmissionRate;
  final List<CourseProgressReportDTO> courseProgressList;

  ProgressReportDTO({
    this.totalStudentsEnrolled = 0,
    this.overallCompletionRate = 0.0,
    this.overallAverageQuizScore = 0.0,
    this.assignmentSubmissionRate = 0.0,
    this.courseProgressList = const [],
  });

  factory ProgressReportDTO.fromJson(Map<String, dynamic> json) {
    final rawList = json['courseProgressList'] as List<dynamic>? ?? [];
    return ProgressReportDTO(
      totalStudentsEnrolled: json['totalStudentsEnrolled'] as int? ?? 0,
      overallCompletionRate: (json['overallCompletionRate'] as num?)?.toDouble() ?? 0.0,
      overallAverageQuizScore: (json['overallAverageQuizScore'] as num?)?.toDouble() ?? 0.0,
      assignmentSubmissionRate: (json['assignmentSubmissionRate'] as num?)?.toDouble() ?? 0.0,
      courseProgressList: rawList.map((c) => CourseProgressReportDTO.fromJson(c)).toList(),
    );
  }
}

class QuizSummaryReportDTO {
  final int quizId;
  final String quizTitle;
  final int totalAttempts;
  final double averageScore;
  final double passRate;

  QuizSummaryReportDTO({
    required this.quizId,
    required this.quizTitle,
    this.totalAttempts = 0,
    this.averageScore = 0.0,
    this.passRate = 0.0,
  });

  factory QuizSummaryReportDTO.fromJson(Map<String, dynamic> json) {
    return QuizSummaryReportDTO(
      quizId: json['quizId'] as int? ?? 0,
      quizTitle: json['quizTitle'] ?? '',
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      passRate: (json['passRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class QuizReportDTO {
  final int totalQuizzes;
  final double overallPassRate;
  final double averageScore;
  final List<QuizSummaryReportDTO> quizSummaries;

  QuizReportDTO({
    this.totalQuizzes = 0,
    this.overallPassRate = 0.0,
    this.averageScore = 0.0,
    this.quizSummaries = const [],
  });

  factory QuizReportDTO.fromJson(Map<String, dynamic> json) {
    final rawList = json['quizSummaries'] as List<dynamic>? ?? [];
    return QuizReportDTO(
      totalQuizzes: json['totalQuizzes'] as int? ?? 0,
      overallPassRate: (json['overallPassRate'] as num?)?.toDouble() ?? 0.0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      quizSummaries: rawList.map((q) => QuizSummaryReportDTO.fromJson(q)).toList(),
    );
  }
}
