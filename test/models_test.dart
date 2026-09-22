import 'package:flutter_test/flutter_test.dart';
import 'package:lms_flutter/models/course_model.dart';
import 'package:lms_flutter/models/user_model.dart';
import 'package:lms_flutter/models/quiz_model.dart';
import 'package:lms_flutter/models/assignment_model.dart';
import 'package:lms_flutter/models/category_model.dart';

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

    test('QuizModel parses from JSON correctly', () {
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
  });
}
