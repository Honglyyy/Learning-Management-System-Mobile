class StudentProfile {
  final int id;
  final String? studentCode;
  final String? fullName;
  final String? phoneNumber;
  final String? gender;
  final String? dateOfBirth;
  final String? educationLevel;
  final String? profilePhotoUrl;
  final int totalPoints;

  StudentProfile({
    required this.id,
    this.studentCode,
    this.fullName,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    this.educationLevel,
    this.profilePhotoUrl,
    this.totalPoints = 0,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as int? ?? 0,
      studentCode: json['studentCode'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'],
      educationLevel: json['educationLevel'],
      profilePhotoUrl: json['profilePhotoUrl'],
      totalPoints: json['totalPoints'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'educationLevel': educationLevel,
      };
}
