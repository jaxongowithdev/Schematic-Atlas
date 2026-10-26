import 'package:flutter/material.dart';
import 'dart:math';
import '../database/storage_manager.dart';
import '../models/quiz_question.dart';
import '../models/symbol_model.dart';
import '../utils/visual_themes.dart';

class QuizCenter extends StatefulWidget {
  const QuizCenter({super.key});

  @override
  State<QuizCenter> createState() => _QuizCenterState();
}

class _QuizCenterState extends State<QuizCenter> {
  final _storage = StorageManager.instance;
  bool _isLoading = false;

  void _startQuiz({String? category, int count = 10}) async {
    setState(() {
      _isLoading = true;
    });

    List<QuizQuestion> questions;
    if (category != null) {
      questions = await _storage.getQuizQuestions(category: category, limit: count);
    } else {
      questions = await _storage.getRandomQuizQuestions(count);
    }

    setState(() {
      _isLoading = false;
    });

    if (questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No questions available')),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizSession(questions: questions),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Daily Challenge
                Card(
                  color: VisualThemes.industrialOrange,
                  child: InkWell(
                    onTap: () => _startQuiz(count: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bolt,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Challenge',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '10 random questions',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quiz by Category
                Text(
                  'Quiz by Category',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildCategoryQuiz('Electrical', Icons.electric_bolt, Colors.blue),
                _buildCategoryQuiz('Mechanical', Icons.settings, Colors.grey),
                _buildCategoryQuiz('Hydraulic', Icons.water_drop, Colors.cyan),
                _buildCategoryQuiz('Safety', Icons.warning, Colors.amber),
                _buildCategoryQuiz('HVAC', Icons.ac_unit, Colors.teal),
              ],
            ),
    );
  }

  Widget _buildCategoryQuiz(String category, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(category),
        subtitle: const Text('Test your knowledge'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _startQuiz(category: category, count: 10),
      ),
    );
  }
}

// Quiz Session
class QuizSession extends StatefulWidget {
  final List<QuizQuestion> questions;

  const QuizSession({
    super.key,
    required this.questions,
  });

  @override
  State<QuizSession> createState() => _QuizSessionState();
}

class _QuizSessionState extends State<QuizSession> {
  final _storage = StorageManager.instance;
  int _currentIndex = 0;
  int _correctCount = 0;
  Map<int, int?> _answers = {};
  List<SymbolModel> _symbols = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSymbols();
  }

  Future<void> _loadSymbols() async {
    final symbols = await _storage.getAllSymbols();
    setState(() {
      _symbols = symbols;
      _isLoading = false;
    });
  }

  void _answerQuestion(int answer) {
    final question = widget.questions[_currentIndex];
    final isCorrect = answer == question.correctAnswer;

    setState(() {
      _answers[_currentIndex] = answer;
      if (isCorrect) {
        _correctCount++;
      }
    });

    // Wait a moment then move to next
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_currentIndex < widget.questions.length - 1) {
        setState(() {
          _currentIndex++;
        });
      } else {
        _showResults();
      }
    });
  }

  void _showResults() async {
    // Save stats
    await _storage.updateQuizStats(
      correct: _correctCount,
      total: widget.questions.length,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResults(
            totalQuestions: widget.questions.length,
            correctAnswers: _correctCount,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = widget.questions[_currentIndex];
    final answered = _answers.containsKey(_currentIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1}/${widget.questions.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.questions.length,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                VisualThemes.industrialOrange,
              ),
            ),
            const SizedBox(height: 24),

            // Question
            Text(
              question.question,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Options
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  final optionId = question.options[index];
                  final symbol = _symbols.firstWhere(
                    (s) => s.id == optionId,
                    orElse: () => _symbols.first, // Fallback to first symbol if not found
                  );
                  final isSelected = _answers[_currentIndex] == optionId;
                  final isCorrect = optionId == question.correctAnswer;

                  Color? color;
                  if (answered) {
                    if (isCorrect) {
                      color = Colors.green;
                    } else if (isSelected) {
                      color = Colors.red;
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: color?.withOpacity(0.1),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color ?? VisualThemes.industrialOrange,
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(symbol.name),
                      subtitle: Text(symbol.code),
                      trailing: answered
                          ? (isCorrect
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : (isSelected
                                  ? const Icon(Icons.cancel, color: Colors.red)
                                  : null))
                          : null,
                      onTap: answered ? null : () => _answerQuestion(optionId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quiz Results
class QuizResults extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;

  const QuizResults({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (correctAnswers / totalQuestions * 100).round();

    String message;
    IconData icon;
    Color color;

    if (percentage >= 80) {
      message = 'Excellent!';
      icon = Icons.emoji_events;
      color = Colors.amber;
    } else if (percentage >= 60) {
      message = 'Good Job!';
      icon = Icons.thumb_up;
      color = Colors.green;
    } else {
      message = 'Keep Learning!';
      icon = Icons.school;
      color = Colors.blue;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 24),
              Text(
                message,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '$percentage%',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: VisualThemes.industrialOrange,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Accuracy',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(
                          context,
                          'Correct',
                          correctAnswers.toString(),
                          Colors.green,
                        ),
                        _buildStat(
                          context,
                          'Wrong',
                          (totalQuestions - correctAnswers).toString(),
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
