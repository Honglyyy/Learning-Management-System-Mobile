import 'lesson_model.dart';

class SectionModel {
  final int sectionId;
  final String title;
  final String? duration;
  final int? courseId;
  final int orderIndex;
  final List<LessonModel> lessons;

  SectionModel({
    required this.sectionId,
    required this.title,
    this.duration,
    this.courseId,
    this.orderIndex = 0,
    this.lessons = const [],
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'] as List<dynamic>? ?? [];
    return SectionModel(
      sectionId: json['sectionId'] as int? ?? json['id'] as int? ?? 0,
      title: json['title'] ?? '',
      duration: json['duration']?.toString(),
      courseId: json['courseId'] as int?,
      orderIndex: json['orderIndex'] as int? ?? json['order'] as int? ?? 0,
      lessons: rawLessons.map((l) => LessonModel.fromJson(l)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sectionId': sectionId,
        'title': title,
        'duration': duration,
        'orderIndex': orderIndex,
        if (courseId != null) 'courseId': courseId,
      };
}
