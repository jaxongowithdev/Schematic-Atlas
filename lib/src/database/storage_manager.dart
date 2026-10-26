import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/symbol_model.dart';
import '../models/category_model.dart';
import '../models/quiz_question.dart';
import '../models/user_stats.dart';
import '../models/config_model.dart';
import 'symbol_data.dart';

class StorageManager {
  static final StorageManager instance = StorageManager._init();
  static Database? _database;

  StorageManager._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('engineering_symbols.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Symbols table
    await db.execute('''
      CREATE TABLE symbols(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_name TEXT NOT NULL,
        code TEXT NOT NULL,
        description TEXT NOT NULL,
        usage TEXT NOT NULL,
        keywords TEXT NOT NULL,
        related_ids TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        standard TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        last_viewed INTEGER
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon_path TEXT NOT NULL,
        description TEXT NOT NULL,
        symbol_count INTEGER DEFAULT 0
      )
    ''');

    // Quiz questions table
    await db.execute('''
      CREATE TABLE quiz_questions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        mode TEXT NOT NULL,
        correct_answer INTEGER NOT NULL,
        options TEXT NOT NULL,
        explanation TEXT,
        category TEXT NOT NULL
      )
    ''');

    // User stats table
    await db.execute('''
      CREATE TABLE user_stats(
        id INTEGER PRIMARY KEY,
        symbols_viewed INTEGER DEFAULT 0,
        favorite_count INTEGER DEFAULT 0,
        quizzes_taken INTEGER DEFAULT 0,
        correct_answers INTEGER DEFAULT 0,
        total_questions INTEGER DEFAULT 0,
        last_quiz_date INTEGER
      )
    ''');

    // Config table
    await db.execute('''
      CREATE TABLE config(
        id INTEGER PRIMARY KEY,
        theme TEXT NOT NULL DEFAULT 'system',
        show_welcome INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Insert default config
    await db.insert('config', {
      'id': 1,
      'theme': 'system',
      'show_welcome': 1,
    });

    // Insert default user stats
    await db.insert('user_stats', {
      'id': 1,
      'symbols_viewed': 0,
      'favorite_count': 0,
      'quizzes_taken': 0,
      'correct_answers': 0,
      'total_questions': 0,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Drop all tables and recreate
    await db.execute('DROP TABLE IF EXISTS symbols');
    await db.execute('DROP TABLE IF EXISTS categories');
    await db.execute('DROP TABLE IF EXISTS quiz_questions');
    await db.execute('DROP TABLE IF EXISTS user_stats');
    await db.execute('DROP TABLE IF EXISTS config');

    // Recreate tables
    await _createDB(db, newVersion);
  }

  Future<void> seedDatabase() async {
    final db = await database;

    // Check if already seeded
    final symbolCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM symbols'),
    );

    if (symbolCount != null && symbolCount > 0) {
      return; // Already seeded
    }

    // Seed categories
    final categories = SymbolData.getCategories();
    final categoryBatch = db.batch();
    for (final category in categories) {
      categoryBatch.insert('categories', category.toMap());
    }
    await categoryBatch.commit(noResult: true);

    // Seed symbols
    final symbols = SymbolData.getSymbols();
    final symbolBatch = db.batch();
    for (final symbol in symbols) {
      symbolBatch.insert('symbols', symbol.toMap());
    }
    await symbolBatch.commit(noResult: true);

    // Seed quiz questions
    final questions = SymbolData.getQuizQuestions();
    final quizBatch = db.batch();
    for (final question in questions) {
      quizBatch.insert('quiz_questions', question.toMap());
    }
    await quizBatch.commit(noResult: true);

    // Update category counts
    for (final category in categories) {
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM symbols WHERE category_name = ?',
          [category.name],
        ),
      );
      await db.update(
        'categories',
        {'symbol_count': count},
        where: 'name = ?',
        whereArgs: [category.name],
      );
    }
  }

  // CRUD operations for Symbols
  Future<List<SymbolModel>> getAllSymbols() async {
    final db = await database;
    final result = await db.query('symbols', orderBy: 'name ASC');
    return result.map((map) => SymbolModel.fromMap(map)).toList();
  }

  Future<SymbolModel?> getSymbolById(int id) async {
    final db = await database;
    final result = await db.query(
      'symbols',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return SymbolModel.fromMap(result.first);
  }

  Future<List<SymbolModel>> getSymbolsByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'symbols',
      where: 'category_name = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return result.map((map) => SymbolModel.fromMap(map)).toList();
  }

  Future<List<SymbolModel>> searchSymbols(String query) async {
    final db = await database;
    final lowerQuery = query.toLowerCase();
    final result = await db.query(
      'symbols',
      where: 'LOWER(name) LIKE ? OR LOWER(code) LIKE ? OR LOWER(keywords) LIKE ?',
      whereArgs: ['%$lowerQuery%', '%$lowerQuery%', '%$lowerQuery%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => SymbolModel.fromMap(map)).toList();
  }

  Future<List<SymbolModel>> getFavoriteSymbols() async {
    final db = await database;
    final result = await db.query(
      'symbols',
      where: 'is_favorite = 1',
      orderBy: 'name ASC',
    );
    return result.map((map) => SymbolModel.fromMap(map)).toList();
  }

  Future<List<SymbolModel>> getRecentlyViewed({int limit = 5}) async {
    final db = await database;
    final result = await db.query(
      'symbols',
      where: 'last_viewed IS NOT NULL',
      orderBy: 'last_viewed DESC',
      limit: limit,
    );
    return result.map((map) => SymbolModel.fromMap(map)).toList();
  }

  Future<void> updateSymbol(SymbolModel symbol) async {
    final db = await database;
    await db.update(
      'symbols',
      symbol.toMap(),
      where: 'id = ?',
      whereArgs: [symbol.id],
    );
  }

  Future<void> toggleFavorite(int symbolId) async {
    final db = await database;
    final symbol = await getSymbolById(symbolId);
    if (symbol != null) {
      await db.update(
        'symbols',
        {'is_favorite': symbol.isFavorite ? 0 : 1},
        where: 'id = ?',
        whereArgs: [symbolId],
      );
    }
  }

  Future<void> markAsViewed(int symbolId) async {
    final db = await database;
    await db.update(
      'symbols',
      {'last_viewed': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [symbolId],
    );
  }

  // CRUD operations for Categories
  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((map) => CategoryModel.fromMap(map)).toList();
  }

  // Quiz operations
  Future<List<QuizQuestion>> getQuizQuestions({String? category, int? limit}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (category != null) {
      where = 'category = ?';
      whereArgs = [category];
    }

    final result = await db.query(
      'quiz_questions',
      where: where,
      whereArgs: whereArgs,
      limit: limit,
    );
    return result.map((map) => QuizQuestion.fromMap(map)).toList();
  }

  Future<List<QuizQuestion>> getRandomQuizQuestions(int count) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT * FROM quiz_questions ORDER BY RANDOM() LIMIT ?',
      [count],
    );
    return result.map((map) => QuizQuestion.fromMap(map)).toList();
  }

  // User stats operations
  Future<UserStats> getUserStats() async {
    final db = await database;
    final result = await db.query('user_stats', where: 'id = 1');
    if (result.isEmpty) {
      return UserStats();
    }
    return UserStats.fromMap(result.first);
  }

  Future<void> updateUserStats(UserStats stats) async {
    final db = await database;
    await db.update(
      'user_stats',
      stats.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> incrementSymbolsViewed() async {
    final stats = await getUserStats();
    await updateUserStats(stats.copyWith(
      symbolsViewed: stats.symbolsViewed + 1,
    ));
  }

  Future<void> updateQuizStats({
    required int correct,
    required int total,
  }) async {
    final stats = await getUserStats();
    await updateUserStats(stats.copyWith(
      quizzesTaken: stats.quizzesTaken + 1,
      correctAnswers: stats.correctAnswers + correct,
      totalQuestions: stats.totalQuestions + total,
      lastQuizDate: DateTime.now(),
    ));
  }

  // Config operations
  Future<ConfigModel> getConfig() async {
    final db = await database;
    final result = await db.query('config', where: 'id = 1');
    if (result.isEmpty) {
      return ConfigModel();
    }
    return ConfigModel.fromMap(result.first);
  }

  Future<void> updateConfig(ConfigModel config) async {
    final db = await database;
    await db.update(
      'config',
      config.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // Clean up
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> resetData() async {
    final db = await database;
    await db.delete('symbols');
    await db.delete('categories');
    await db.delete('quiz_questions');
    await db.update('user_stats', {
      'symbols_viewed': 0,
      'favorite_count': 0,
      'quizzes_taken': 0,
      'correct_answers': 0,
      'total_questions': 0,
      'last_quiz_date': null,
    }, where: 'id = 1');
    await seedDatabase();
  }
}
