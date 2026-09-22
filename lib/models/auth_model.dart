class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class RegisterRequest {
  final String fullName;
  final String username;
  final String email;
  final String? phoneNumber;
  final String password;
  final String role; // 'STUDENT' or 'INSTRUCTOR'

  RegisterRequest({
    required this.fullName,
    required this.username,
    required this.email,
    this.phoneNumber,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'username': username,
        'email': email,
        if (phoneNumber != null && phoneNumber!.isNotEmpty)
          'phoneNumber': phoneNumber,
        'password': password,
        'role': role,
      };
}

class SessionResponse {
  final bool authenticated;
  final String? userId;
  final String? email;
  final String? username;
  final String? role;
  final int? expiresInSeconds;

  SessionResponse({
    required this.authenticated,
    this.userId,
    this.email,
    this.username,
    this.role,
    this.expiresInSeconds,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      authenticated: json['authenticated'] ?? false,
      userId: json['userId']?.toString(),
      email: json['email'],
      username: json['username'],
      role: json['role'],
      expiresInSeconds: json['expiresInSeconds'] as int?,
    );
  }
}

class AuthClaims {
  final String? sub;
  final String? email;
  final String role;
  final int? exp;

  AuthClaims({
    this.sub,
    this.email,
    required this.role,
    this.exp,
  });

  factory AuthClaims.fromMap(Map<String, dynamic> map) {
    return AuthClaims(
      sub: map['sub']?.toString(),
      email: map['email'] ?? map['sub'],
      role: (map['role'] ?? 'STUDENT').toString().toUpperCase(),
      exp: map['exp'] as int?,
    );
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isInstructor => role == 'INSTRUCTOR';
  bool get isStudent => role == 'STUDENT' || role == 'USER';
}
