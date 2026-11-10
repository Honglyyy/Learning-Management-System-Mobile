import 'package:flutter_test/flutter_test.dart';
import 'package:lms_flutter/models/course_model.dart';
import 'package:lms_flutter/models/user_model.dart';
import 'package:lms_flutter/models/quiz_model.dart';
import 'package:lms_flutter/models/assignment_model.dart';
import 'package:lms_flutter/models/category_model.dart';
import 'package:lms_flutter/models/enrollment_model.dart';
import 'package:lms_flutter/models/payment_model.dart';

void main() {
  group('Model Deserialization Tests', () {
    test('CourseModel parses from JSON correctly', () {
      final json = {
        'courseId': 101,
        'title': 'Flutter Mastery',
        'description': 'From zero to hero in Flutter',
        'price': 29.99,
        'status': 'PUBLISHED',
        'level': 'INTERMEDIATE',
        'overallDuration': '12 hours',
        'categories': ['Mobile Development'],
        'categoryIds': [1],
        'instructorId': 5,
        'instructor': 'Jane Doe',
        'sections': [],
        'rating': 4.8,
      };

      final course = CourseModel.fromJson(json);
      expect(course.courseId, 101);
      expect(course.title, 'Flutter Mastery');
      expect(course.price, 29.99);
      expect(course.isFree, isFalse);
      expect(course.categories, contains('Mobile Development'));
      expect(course.instructor, 'Jane Doe');
      expect(course.rating, 4.8);
    });

    test('UserModel parses from JSON correctly', () {
      final json = {
        'id': 1,
        'username': 'admin_user',
        'email': 'admin@lumen.edu',
        'fullName': 'Admin Master',
        'role': 'ADMIN',
        'phoneNumber': '+123456789',
        'isActive': true,
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 1);
      expect(user.username, 'admin_user');
      expect(user.role, 'ADMIN');
      expect(user.isActive, isTrue);
    });

    test('QuizModel parses from JSON correctly with questions key', () {
      final json = {
        'quizId': 12,
        'quizTitle': 'Dart Basics Quiz',
        'totalPoint': 10,
        'questions': [
          {
            'questionId': 1,
            'questionText': 'What keyword defines a constant?',
            'point': 10,
            'answers': [
              {'answerId': 1, 'answerText': 'const', 'isCorrect': true},
              {'answerId': 2, 'answerText': 'var', 'isCorrect': false},
            ]
          }
        ]
      };

      final quiz = QuizModel.fromJson(json);
      expect(quiz.quizId, 12);
      expect(quiz.quizTitle, 'Dart Basics Quiz');
      expect(quiz.totalPoint, 10);
      expect(quiz.questions.length, 1);
      expect(quiz.questions.first.answers.length, 2);
      expect(quiz.questions.first.answers.first.isCorrect, isTrue);
    });

    test('QuizModel parses backend response using question key', () {
      final json = {
        'quizId': 1,
        'title': 'Quiz 1.1: Container Fundamentals Check',
        'totalPoints': 10.0,
        'question': [
          {
            'questionId': 1,
            'questionText': 'What is the primary architectural difference?',
            'point': 3,
            'answers': [
              {'answerId': 2, 'answerText': 'Containers share host kernel', 'isCorrect': null},
              {'answerId': 1, 'answerText': 'VMs emulate memory', 'isCorrect': null},
            ]
          }
        ]
      };

      final quiz = QuizModel.fromJson(json);
      expect(quiz.quizId, 1);
      expect(quiz.quizTitle, 'Quiz 1.1: Container Fundamentals Check');
      expect(quiz.totalPoint, 10);
      expect(quiz.questions.length, 1);
      expect(quiz.questions.first.answers.length, 2);
      expect(quiz.questions.first.point, 3);
      expect(quiz.questions.first.answers.first.isCorrect, isFalse);
    });

    test('AssignmentModel parses from JSON correctly', () {
      final json = {
        'assignmentId': 33,
        'title': 'Build a Weather App',
        'description': 'Implement OpenWeatherMap API in Flutter',
        'dueDate': '2026-10-01T23:59:59Z',
        'maxScore': 100,
      };

      final assignment = AssignmentModel.fromJson(json);
      expect(assignment.assignmentId, 33);
      expect(assignment.title, 'Build a Weather App');
      expect(assignment.maxScore, 100);
      expect(assignment.dueDate, isNotNull);
    });

    test('CategoryModel parses from JSON correctly', () {
      final json = {
        'categoryId': 3,
        'category': 'Cloud Computing',
      };

      final cat = CategoryModel.fromJson(json);
      expect(cat.categoryId, 3);
      expect(cat.category, 'Cloud Computing');
    });

    test('EnrollmentModel parses from JSON and copyWith populates course cover', () {
      final json = {
        'enrollmentId': 5,
        'courseId': 1,
        'courseTitle': 'Docker & Containerization Mastery',
        'status': 'ACTIVE',
        'progressPercent': 0.0,
      };

      final enrollment = EnrollmentModel.fromJson(json);
      expect(enrollment.enrollmentId, 5);
      expect(enrollment.courseId, 1);
      expect(enrollment.courseTitle, 'Docker & Containerization Mastery');
      expect(enrollment.courseCoverUrl, isNull);

      final updated = enrollment.copyWith(
        courseCoverUrl: 'https://res.cloudinary.com/lyxxfhot/image/upload/sample.png',
        instructorName: 'Lay Hongly',
      );
      expect(updated.courseCoverUrl, 'https://res.cloudinary.com/lyxxfhot/image/upload/sample.png');
      expect(updated.instructorName, 'Lay Hongly');
      expect(updated.courseTitle, 'Docker & Containerization Mastery');
    });

    test('PaymentModel defaults provider to empty string when missing', () {
      final payment = PaymentModel.fromJson({
        'paymentId': 12,
        'courseId': 3,
        'courseTitle': 'Clean Architecture',
        'amount': 49.0,
        'status': 'PENDING',
      });

      expect(payment.paymentId, 12);
      expect(payment.provider, '');
      expect(payment.isPending, isTrue);

      final assigned = PaymentModel.fromJson({
        'paymentId': 13,
        'courseId': 4,
        'amount': 25.0,
        'provider': 'BAKONG',
        'status': 'PAID',
      });
      expect(assigned.provider, 'BAKONG');
      expect(assigned.isPaid, isTrue);
    });
  });
}
