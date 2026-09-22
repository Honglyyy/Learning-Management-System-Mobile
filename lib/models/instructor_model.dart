class InstructorModel {
  final int id;
  final String fullName;
  final String? phoneNumber;
  final String? email;
  final String? profilePhotoUrl;
  final String? biography;
  final String? expertise;
  final double averageRating;
  final int? totalCourses;

  InstructorModel({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.email,
    this.profilePhotoUrl,
    this.biography,
    this.expertise,
    this.averageRating = 0.0,
    this.totalCourses,
  });

  factory InstructorModel.fromJson(Map<String, dynamic> json) {
    return InstructorModel(
      id: json['id'] as int? ?? json['instructorId'] as int? ?? 0,
      fullName: json['fullName'] ?? json['instructor'] ?? 'Instructor',
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      profilePhotoUrl: json['profilePhotoUrl'] ?? json['photoUrl'],
      biography: json['biography'] ?? json['bio'],
      expertise: json['expertise'],
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalCourses: json['totalCourses'] as int? ?? json['courseCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'biography': biography,
        'expertise': expertise,
      };

  List<String> get expertiseList {
    if (expertise == null || expertise!.isEmpty) return [];
    return expertise!
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
