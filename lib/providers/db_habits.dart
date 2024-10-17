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
        // Crear tabla de hábitos
        await db.execute(
          'CREATE TABLE habits(id INTEGER PRIMARY KEY AUTOINCREMENT, habit TEXT)',
        );
        // Crear tabla para registrar días cumplidos
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

  Future<List<String>> getHabitsForDate(DateTime date) async {
  final db = await database;
  
  // Convertir la fecha a formato de texto para hacer coincidir con la base de datos
  String formattedDate = date.toIso8601String().split('T')[0];
  
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT habits.habit FROM habits
    INNER JOIN habit_days ON habits.id = habit_days.habit_id
    WHERE habit_days.date LIKE ?
  ''', ['$formattedDate%']);

  return List.generate(maps.length, (i) {
    return maps[i]['habit'] as String;
  });
}

Future<int?> getHabitIdByName(String habitName) async {
  final db = await database;
  final List<Map<String, dynamic>> result = await db.query(
    'habits',
    columns: ['id'],
    where: 'habit = ?',
    whereArgs: [habitName],
  );

  if (result.isNotEmpty) {
    return result.first['id'] as int;
  } else {
    return null; // Si no se encuentra, devolver null
  }
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

  Future<void> deleteHabit(String habit) async {
    final db = await database;
    await db.delete(
      'habits', // Nombre de la tabla
      where:
          'habit = ?', // Condición para eliminar, usando el nombre correcto de la columna
      whereArgs: [habit], // Argumento para la condición
    );
  }

  Future<void> printAllHabits() async {
  final db = await database;
  
  // Consulta todos los hábitos en la tabla 'habits'
  final List<Map<String, dynamic>> result = await db.query('habits');

  // Itera sobre los resultados y los imprime
  print('---- Lista de hábitos en la base de datos ----');
  result.forEach((row) {
    print('ID: ${row['id']}, Habit: ${row['habit']}');
  });

  // Para imprimir también los días cumplidos
  final List<Map<String, dynamic>> habitDays = await db.query('habit_days');
  print('---- Días de hábitos registrados ----');
  habitDays.forEach((row) {
    print('Habit ID: ${row['habit_id']}, Habit ID_ref: ${row['id']} , Date: ${row['date']}');
  });
}

Future<void> clearDatabase() async {
  final db = await database;

  // Eliminar todos los registros de ambas tablas
  await db.delete('habit_days');
  await db.delete('habits');
}


}
