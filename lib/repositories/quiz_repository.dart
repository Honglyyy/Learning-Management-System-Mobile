import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/quiz_model.dart';

class QuizRepository {
  final ApiClient _api;

  QuizRepository(this._api);

  Future<List<QuizModel>> getQuizzes() async {
    final response = await _api.get(ApiEndpoints.quizzes);
    if (response is List) {
      return response
          .map((item) => QuizModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<QuizModel?> getLessonQuiz(int lessonId) async {
    try {
      final response = await _api.get(ApiEndpoints.lessonQuiz(lessonId));
      if (response != null && response is Map<String, dynamic>) {
        return QuizModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  Future<QuizAttemptModel?> getQuizAttemptMe(int quizId) async {
    try {
      final response = await _api.get(ApiEndpoints.quizAttemptMe(quizId));
      if (response != null && response is Map<String, dynamic>) {
        return QuizAttemptModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  Future<QuizAttemptModel> submitQuiz(int quizId, List<int> answerIds) async {
    final response = await _api.post(
      ApiEndpoints.quizSubmit(quizId),
      data: {'answerIds': answerIds},
    );
    return QuizAttemptModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> createQuiz(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.quizzes, data: body);
  }

  Future<void> updateQuiz(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.quizById(id), data: body);
  }

  Future<void> deleteQuiz(int id) async {
    await _api.delete(ApiEndpoints.quizById(id));
  }

  Future<List<QuestionModel>> getQuestions() async {
    final response = await _api.get(ApiEndpoints.questions);
    if (response is List) {
      return response
          .map((item) => QuestionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> createQuestion(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.questions, data: body);
  }

  Future<void> updateQuestion(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.questionById(id), data: body);
  }

  Future<void> deleteQuestion(int id) async {
    await _api.delete(ApiEndpoints.questionById(id));
  }

  Future<List<AnswerModel>> getAnswers() async {
    final response = await _api.get(ApiEndpoints.answers);
    if (response is List) {
      return response
          .map((item) => AnswerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> createAnswer(Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.answers, data: body);
  }

  Future<void> updateAnswer(int id, Map<String, dynamic> body) async {
    await _api.put(ApiEndpoints.answerById(id), data: body);
  }

  Future<void> deleteAnswer(int id) async {
    await _api.delete(ApiEndpoints.answerById(id));
  }
}
