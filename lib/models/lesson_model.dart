class LessonMaterial {
  final int materialId;
  final String title;
  final String? fileUrl;
  final String? fileType;
  final int? fileSize;
  final int? lessonId;

  LessonMaterial({
    required this.materialId,
    required this.title,
    this.fileUrl,
    this.fileType,
    this.fileSize,
    this.lessonId,
  });

  factory LessonMaterial.fromJson(Map<String, dynamic> json) {
    return LessonMaterial(
      materialId: json['materialId'] as int? ?? json['id'] as int? ?? 0,
      title: json['title'] ?? '',
      fileUrl: json['fileUrl'],
      fileType: json['fileType'],
      fileSize: json['fileSize'] as int?,
      lessonId: json['lessonId'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'materialId': materialId,
        'title': title,
        'fileUrl': fileUrl,
        if (lessonId != null) 'lessonId': lessonId,
      };
}

class LessonProgress {
  final int? id;
  final int lessonId;
  final bool isCompleted;
  final int lastPlaybackPositionSeconds;
  final dynamic completedAt;

  LessonProgress({
    this.id,
    required this.lessonId,
    this.isCompleted = false,
    this.lastPlaybackPositionSeconds = 0,
    this.completedAt,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      id: json['id'] as int?,
      lessonId: json['lessonId'] as int? ?? 0,
      isCompleted: json['isCompleted'] ?? json['completed'] ?? false,
      lastPlaybackPositionSeconds:
          json['lastPlaybackPositionSeconds'] as int? ?? 0,
      completedAt: json['completedAt'],
    );
  }
}

class LessonNavigation {
  final int? previousLessonId;
  final int? nextLessonId;

  LessonNavigation({this.previousLessonId, this.nextLessonId});

  factory LessonNavigation.fromJson(Map<String, dynamic> json) {
    return LessonNavigation(
      previousLessonId: json['previousLessonId'] as int?,
      nextLessonId: json['nextLessonId'] as int?,
    );
  }
}

class LessonModel {
  final int lessonId;
  final String title;
  final String? videoUrl;
  final String? videoPublicId;
  final String? videoDir;
  final String? description;
  final String? textContent;
  final int orderIndex;
  final String? duration;
  final bool isFree;
  final int? sectionId;
  final List<LessonMaterial> materials;
  final bool isCompleted;

  LessonModel({
    required this.lessonId,
    required this.title,
    this.videoUrl,
    this.videoPublicId,
    this.videoDir,
    this.description,
    this.textContent,
    this.orderIndex = 0,
    this.duration,
    this.isFree = false,
    this.sectionId,
    this.materials = const [],
    this.isCompleted = false,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final rawMaterials = json['materials'] as List<dynamic>? ?? [];
    return LessonModel(
      lessonId: json['lessonId'] as int? ?? json['id'] as int? ?? 0,
      title: json['title'] ?? '',
      videoUrl: json['videoUrl'],
      videoPublicId: json['videoPublicId']?.toString(),
      videoDir: json['videoDir'],
      description: json['description'],
      textContent: json['textContent'],
      orderIndex: json['orderIndex'] as int? ?? json['order'] as int? ?? 0,
      duration: json['duration']?.toString(),
      isFree: json['isFree'] ?? json['free'] ?? false,
      sectionId: json['sectionId'] as int?,
      materials: rawMaterials.map((m) => LessonMaterial.fromJson(m)).toList(),
      isCompleted: json['isCompleted'] ?? json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'title': title,
        'videoUrl': videoUrl,
        'videoPublicId': videoPublicId,
        'description': description,
        'textContent': textContent,
        'orderIndex': orderIndex,
        'duration': duration,
        'isFree': isFree,
        if (sectionId != null) 'sectionId': sectionId,
      };

  String get playableVideoUrl => (videoUrl != null && videoUrl!.isNotEmpty)
      ? videoUrl!
      : (videoDir ?? '');
}
