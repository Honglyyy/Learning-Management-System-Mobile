// ignore_for_file: constant_identifier_names
enum UserRole { STUDENT, INSTRUCTOR, ADMIN, USER }

class UserModel {
  final int id;
  final String? userId;
  final String username;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String role;
  final bool? isVerified;
  final bool? isActive;
  final dynamic createdAt;

  UserModel({
    required this.id,
    this.userId,
    required this.username,
    required this.email,
    this.fullName,
    this.phoneNumber,
    required this.role,
    this.isVerified,
    this.isActive,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      userId: json['userId']?.toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['fullname'],
      phoneNumber: json['phoneNumber'],
      role: (json['role'] ?? 'STUDENT').toString(),
      isVerified: json['isVerified'] as bool?,
      isActive: json['isActive'] ?? json['active'] ?? true,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'username': username,
        'email': email,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'role': role,
        'isVerified': isVerified,
        'isActive': isActive,
      };
}
