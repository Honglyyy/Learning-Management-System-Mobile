class AnswerModel {
  final int answerId;
  final String answerText;
  final bool isCorrect;
  final int? questionId;

  AnswerModel({
    required this.answerId,
    required this.answerText,
    this.isCorrect = false,
    this.questionId,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      answerId: json['answerId'] as int? ?? json['id'] as int? ?? 0,
      answerText: json['answerText'] ?? json['text'] ?? '',
      isCorrect: json['isCorrect'] ?? json['correct'] ?? false,
      questionId: json['questionId'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'answerId': answerId,
        'answerText': answerText,
        'isCorrect': isCorrect,
        if (questionId != null) 'questionId': questionId,
      };
}

class QuestionModel {
  final int questionId;
  final String questionText;
  final int point;
  final int? quizId;
  final List<AnswerModel> answers;

  QuestionModel({
    required this.questionId,
    required this.questionText,
    this.point = 1,
    this.quizId,
    this.answers = const [],
  });

  int get points => point;

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as List<dynamic>? ?? [];
    return QuestionModel(
      questionId: json['questionId'] as int? ?? json['id'] as int? ?? 0,
      questionText: json['questionText'] ?? json['text'] ?? '',
      point: json['point'] as int? ?? 1,
      quizId: json['quizId'] as int?,
      answers: rawAnswers.map((a) => AnswerModel.fromJson(a)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'questionText': questionText,
        'point': point,
        if (quizId != null) 'quizId': quizId,
      };
}

class QuizModel {
  final int quizId;
  final String quizTitle;
  final int totalPoint;
  final int? lessonId;
  final List<QuestionModel> questions;

  QuizModel({
    required this.quizId,
    required this.quizTitle,
    this.totalPoint = 0,
    this.lessonId,
    this.questions = const [],
  });

  String get title => quizTitle;
  int get totalPoints => totalPoint;

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    return QuizModel(
      quizId: json['quizId'] as int? ?? json['id'] as int? ?? 0,
      quizTitle: json['quizTitle'] ?? json['title'] ?? '',
      totalPoint: (json['totalPoint'] ?? json['totalPoints'] as num?)?.toInt() ?? 0,
      lessonId: json['lessonId'] as int?,
      questions: rawQuestions.map((q) => QuestionModel.fromJson(q)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'quizId': quizId,
        'title': quizTitle,
        'quizTitle': quizTitle,
        'totalPoint': totalPoint,
        'totalPoints': totalPoint,
        if (lessonId != null) 'lessonId': lessonId,
      };
}

class QuizAttemptModel {
  final int? attemptId;
  final int earnedPoints;
  final int totalPoints;
  final int correctAnswers;
  final int totalQuestions;
  final dynamic submittedAt;

  QuizAttemptModel({
    this.attemptId,
    required this.earnedPoints,
    required this.totalPoints,
    required this.correctAnswers,
    required this.totalQuestions,
    this.submittedAt,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      attemptId: json['attemptId'] as int? ?? json['id'] as int?,
      earnedPoints: json['earnedPoints'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      submittedAt: json['submittedAt'],
    );
  }

  double get percent =>
      totalPoints > 0 ? (earnedPoints / totalPoints) * 100 : 0.0;
}
