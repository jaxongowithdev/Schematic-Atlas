enum QuizMode {
  symbolToName, // Show symbol, select name
  nameToSymbol, // Show name, select symbol
  trueFalse, // True/False statement
}

class QuizQuestion {
  final int? id;
  final String question;
  final QuizMode mode;
  final int correctAnswer; // Index or symbolId
  final List<int> options; // Symbol IDs for options
  final String? explanation;
  final String category;

  QuizQuestion({
    this.id,
    required this.question,
    required this.mode,
    required this.correctAnswer,
    required this.options,
    this.explanation,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'mode': mode.toString().split('.').last,
      'correct_answer': correctAnswer,
      'options': options.join(','),
      'explanation': explanation,
      'category': category,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as int?,
      question: map['question'] as String,
      mode: QuizMode.values.firstWhere(
        (e) => e.toString().split('.').last == map['mode'],
        orElse: () => QuizMode.symbolToName,
      ),
      correctAnswer: map['correct_answer'] as int,
      options: (map['options'] as String)
          .split(',')
          .map((e) => int.parse(e))
          .toList(),
      explanation: map['explanation'] as String?,
      category: map['category'] as String,
    );
  }

  QuizQuestion copyWith({
    int? id,
    String? question,
    QuizMode? mode,
    int? correctAnswer,
    List<int>? options,
    String? explanation,
    String? category,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      mode: mode ?? this.mode,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      options: options ?? this.options,
      explanation: explanation ?? this.explanation,
      category: category ?? this.category,
    );
  }
}
