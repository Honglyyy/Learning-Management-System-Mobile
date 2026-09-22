import 'section_model.dart';

class CourseReview {
  final int reviewId;
  final String reviewText;
  final int rating;
  final dynamic createdAt;
  final int? userId;
  final String? userName;
  final String? userPhotoUrl;
  final int? courseId;

  CourseReview({
    required this.reviewId,
    required this.reviewText,
    required this.rating,
    this.createdAt,
    this.userId,
    this.userName,
    this.userPhotoUrl,
    this.courseId,
  });

  factory CourseReview.fromJson(Map<String, dynamic> json) {
    return CourseReview(
      reviewId: json['reviewId'] as int? ?? json['id'] as int? ?? 0,
      reviewText: json['reviewText'] ?? json['content'] ?? '',
      rating: json['rating'] as int? ?? 5,
      createdAt: json['createdAt'],
      userId: json['userId'] as int?,
      userName: json['userName'] ?? json['userFullName'] ?? json['username'] ?? 'Anonymous',
      userPhotoUrl: json['userPhotoUrl'] ?? json['avatarUrl'],
      courseId: json['courseId'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'reviewText': reviewText,
        'rating': rating,
      };
}

class CourseModel {
  final int courseId;
  final String title;
  final String description;
  final String? overallDuration;
  final String? coverUrl;
  final String? coverPublicId;
  final num price;
  final String level;
  final String status;
  final String? learningOutcomes;
  final String? requirements;
  final List<String> categories;
  final List<int> categoryIds;
  final int? instructorId;
  final String? instructor;
  final String? instructorPhotoUrl;
  final double rating;
  final int lessonCount;
  final int enrollmentCount;
  final bool isFavorite;
  final List<SectionModel> sections;
  final List<CourseReview> reviews;

  CourseModel({
    required this.courseId,
    required this.title,
    required this.description,
    this.overallDuration,
    this.coverUrl,
    this.coverPublicId,
    this.price = 0,
    this.level = 'ALL_LEVELS',
    this.status = 'PUBLISHED',
    this.learningOutcomes,
    this.requirements,
    this.categories = const [],
    this.categoryIds = const [],
    this.instructorId,
    this.instructor,
    this.instructorPhotoUrl,
    this.rating = 0.0,
    this.lessonCount = 0,
    this.enrollmentCount = 0,
    this.isFavorite = false,
    this.sections = const [],
    this.reviews = const [],
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'] as List<dynamic>? ?? [];
    final rawCatIds = json['categoryIds'] as List<dynamic>? ?? [];
    final rawSections = json['sections'] as List<dynamic>? ?? [];
    final rawReviews = json['reviews'] as List<dynamic>? ?? [];

    return CourseModel(
      courseId: json['courseId'] as int? ?? json['id'] as int? ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      overallDuration: json['overallDuration'] ?? json['duration'],
      coverUrl: json['coverUrl'],
      coverPublicId: json['coverPublicId'],
      price: json['price'] as num? ?? 0,
      level: (json['level'] ?? 'ALL_LEVELS').toString(),
      status: (json['status'] ?? 'PUBLISHED').toString(),
      learningOutcomes: json['learningOutcomes'],
      requirements: json['requirements'],
      categories: rawCats.map((c) => c.toString()).toList(),
      categoryIds: rawCatIds.map((c) => (c as num).toInt()).toList(),
      instructorId: json['instructorId'] as int?,
      instructor: json['instructor'] ?? json['instructorName'],
      instructorPhotoUrl: json['instructorPhotoUrl'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      lessonCount: json['lessonCount'] as int? ?? 0,
      enrollmentCount: json['enrollmentCount'] as int? ?? 0,
      isFavorite: json['isFavorite'] ?? json['favorite'] ?? false,
      sections: rawSections.map((s) => SectionModel.fromJson(s)).toList(),
      reviews: rawReviews.map((r) => CourseReview.fromJson(r)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        'title': title,
        'description': description,
        'overallDuration': overallDuration,
        'coverUrl': coverUrl,
        'coverPublicId': coverPublicId,
        'price': price,
        'level': level,
        'status': status,
        'learningOutcomes': learningOutcomes,
        'requirements': requirements,
        'categoryIds': categoryIds,
        if (instructorId != null) 'instructorId': instructorId,
      };

  List<String> get learningOutcomesList {
    if (learningOutcomes == null || learningOutcomes!.trim().isEmpty) return [];
    return learningOutcomes!
        .split('\n')
        .map((s) => s.replaceAll(RegExp(r'^[\s*\-•]+'), '').trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> get requirementsList {
    if (requirements == null || requirements!.trim().isEmpty) return [];
    return requirements!
        .split('\n')
        .map((s) => s.replaceAll(RegExp(r'^[\s*\-•]+'), '').trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  bool get isFree => price == 0;
}
