import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'habits.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        
        await db.execute(
          'CREATE TABLE habits(id INTEGER PRIMARY KEY AUTOINCREMENT, habit TEXT)',
        );
        
        await db.execute(
          'CREATE TABLE habit_days(id INTEGER PRIMARY KEY AUTOINCREMENT, habit_id INTEGER, date TEXT, FOREIGN KEY(habit_id) REFERENCES habits(id))',
        );
      },
    );
  }

  
  Future<void> insertHabit(String habit) async {
    final db = await database;
    await db.insert('habits', {'habit': habit});
  }

  
  Future<List<String>> getHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('habits');

    return List.generate(maps.length, (i) {
      return maps[i]['habit'] as String;
    });
  }

  
  Future<void> insertHabitCompletion(int habitId, DateTime date) async {
    final db = await database;
    await db.insert('habit_days', {
      'habit_id': habitId,
      'date': date.toIso8601String(),
    });
  }

  
  Future<List<DateTime>> getHabitCompletionDates(int habitId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'habit_days',
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );

    return List.generate(maps.length, (i) {
      return DateTime.parse(maps[i]['date'] as String);
    });
  }

  
  Future<Map<String, List<DateTime>>> getHabitsWithCompletionDates() async {
    final db = await database;

  
    final List<Map<String, dynamic>> habits = await db.query('habits');

  
    Map<String, List<DateTime>> habitsWithDates = {};

    for (var habit in habits) {
      int habitId = habit['id'];
      String habitName = habit['habit'];

      List<DateTime> completionDates = await getHabitCompletionDates(habitId);

      habitsWithDates[habitName] = completionDates;
    }

    return habitsWithDates;
  }
}
