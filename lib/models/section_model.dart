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
    final lessons = rawLessons.map((l) => LessonModel.fromJson(l)).toList()
      ..sort((a, b) {
        final cmp = a.orderIndex.compareTo(b.orderIndex);
        if (cmp != 0) return cmp;
        return a.lessonId.compareTo(b.lessonId);
      });
    return SectionModel(
      sectionId: json['sectionId'] as int? ?? json['id'] as int? ?? 0,
      title: json['title'] ?? '',
      duration: json['duration']?.toString(),
      courseId: json['courseId'] as int?,
      orderIndex: json['orderIndex'] as int? ?? json['order'] as int? ?? 0,
      lessons: lessons,
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
