import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_flutter/core/utils/validators.dart';
import 'package:lms_flutter/models/auth_model.dart';
import 'package:lms_flutter/features/auth/screens/login_screen.dart';

void main() {
  group('Auth Unit Tests - Models & Claims', () {
    test('LoginRequest converts to JSON map correctly', () {
      final req = LoginRequest(email: 'student@example.com', password: 'Password123');
      final json = req.toJson();
      expect(json['email'], 'student@example.com');
      expect(json['password'], 'Password123');
    });

    test('RegisterRequest formats JSON with optional and required fields', () {
      final reqWithPhone = RegisterRequest(
        fullName: 'Jane Doe',
        username: 'janedoe',
        email: 'jane@example.com',
        phoneNumber: '+1234567890',
        password: 'Password123!',
        role: 'STUDENT',
      );
      final json1 = reqWithPhone.toJson();
      expect(json1['fullName'], 'Jane Doe');
      expect(json1['username'], 'janedoe');
      expect(json1['email'], 'jane@example.com');
      expect(json1['phoneNumber'], '+1234567890');
      expect(json1['role'], 'STUDENT');

      final reqWithoutPhone = RegisterRequest(
        fullName: 'John Smith',
        username: 'johnsmith',
        email: 'john@example.com',
        password: 'Password123!',
        role: 'INSTRUCTOR',
      );
      final json2 = reqWithoutPhone.toJson();
      expect(json2.containsKey('phoneNumber'), isFalse);
      expect(json2['role'], 'INSTRUCTOR');
    });

    test('AuthClaims properly identifies Student, Instructor, and Admin roles', () {
      final studentClaims = AuthClaims.fromMap({'sub': '1', 'email': 'student@lms.com', 'role': 'STUDENT'});
      expect(studentClaims.isStudent, isTrue);
      expect(studentClaims.isInstructor, isFalse);
      expect(studentClaims.isAdmin, isFalse);

      final userRoleClaims = AuthClaims.fromMap({'sub': '2', 'email': 'user@lms.com', 'role': 'USER'});
      expect(userRoleClaims.isStudent, isTrue);

      final instructorClaims = AuthClaims.fromMap({'sub': '3', 'email': 'prof@lms.com', 'role': 'INSTRUCTOR'});
      expect(instructorClaims.isInstructor, isTrue);
      expect(instructorClaims.isStudent, isFalse);
      expect(instructorClaims.isAdmin, isFalse);

      final adminClaims = AuthClaims.fromMap({'sub': '4', 'email': 'admin@lms.com', 'role': 'ADMIN'});
      expect(adminClaims.isAdmin, isTrue);
      expect(adminClaims.isInstructor, isFalse);
      expect(adminClaims.isStudent, isFalse);
    });

    test('SessionResponse handles session serialization and expiration', () {
      final activeSession = SessionResponse.fromJson({
        'authenticated': true,
        'userId': '42',
        'email': 'active@lms.com',
        'username': 'active_user',
        'role': 'STUDENT',
        'expiresInSeconds': 3600,
      });
      expect(activeSession.authenticated, isTrue);
      expect(activeSession.userId, '42');
      expect(activeSession.expiresInSeconds, 3600);

      final emptySession = SessionResponse.fromJson({});
      expect(emptySession.authenticated, isFalse);
      expect(emptySession.userId, isNull);
    });
  });

  group('Auth Unit Tests - Validators', () {
    test('Email validator enforces valid formats', () {
      expect(Validators.email(null), 'Email is required');
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('   '), 'Email is required');
      expect(Validators.email('not-an-email'), 'Please enter a valid email address');
      expect(Validators.email('user@'), 'Please enter a valid email address');
      expect(Validators.email('user@example.com'), isNull);
    });

    test('Password validator enforces minimum length', () {
      expect(Validators.password(null), 'Password is required');
      expect(Validators.password(''), 'Password is required');
      expect(Validators.password('1234567'), 'Password must be at least 8 characters');
      expect(Validators.password('12345678'), isNull);
    });

    test('Required field validator rejects empty values', () {
      expect(Validators.required(null, 'Username is required'), 'Username is required');
      expect(Validators.required('', 'Username is required'), 'Username is required');
      expect(Validators.required('valid_name'), isNull);
    });
  });

  group('Auth Widget Tests - LoginScreen UI', () {
    testWidgets('LoginScreen renders fields, button, and reason banner', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(reason: 'inactivity'),
          ),
        ),
      );

      // Verify reason banner is displayed
      expect(find.text('You have been signed out due to 15 minutes of inactivity.'), findsOneWidget);

      // Verify input fields
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email, Username, or Phone'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Verify Login button exists
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);

      // Verify Register and Forgot Password navigation links exist
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('LoginScreen shows validation errors when submitted empty', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Tap Sign In button with empty form
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      // Form validation errors should show up
      expect(find.text('Email, username, or phone is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });
  });
}
