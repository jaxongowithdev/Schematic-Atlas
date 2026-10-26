class UserStats {
  final int symbolsViewed;
  final int favoriteCount;
  final int quizzesTaken;
  final int correctAnswers;
  final int totalQuestions;
  final DateTime? lastQuizDate;

  UserStats({
    this.symbolsViewed = 0,
    this.favoriteCount = 0,
    this.quizzesTaken = 0,
    this.correctAnswers = 0,
    this.totalQuestions = 0,
    this.lastQuizDate,
  });

  double get accuracy {
    if (totalQuestions == 0) return 0.0;
    return (correctAnswers / totalQuestions) * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'symbols_viewed': symbolsViewed,
      'favorite_count': favoriteCount,
      'quizzes_taken': quizzesTaken,
      'correct_answers': correctAnswers,
      'total_questions': totalQuestions,
      'last_quiz_date': lastQuizDate?.millisecondsSinceEpoch,
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      symbolsViewed: map['symbols_viewed'] as int? ?? 0,
      favoriteCount: map['favorite_count'] as int? ?? 0,
      quizzesTaken: map['quizzes_taken'] as int? ?? 0,
      correctAnswers: map['correct_answers'] as int? ?? 0,
      totalQuestions: map['total_questions'] as int? ?? 0,
      lastQuizDate: map['last_quiz_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_quiz_date'] as int)
          : null,
    );
  }

  UserStats copyWith({
    int? symbolsViewed,
    int? favoriteCount,
    int? quizzesTaken,
    int? correctAnswers,
    int? totalQuestions,
    DateTime? lastQuizDate,
  }) {
    return UserStats(
      symbolsViewed: symbolsViewed ?? this.symbolsViewed,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      quizzesTaken: quizzesTaken ?? this.quizzesTaken,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      lastQuizDate: lastQuizDate ?? this.lastQuizDate,
    );
  }
}
