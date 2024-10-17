import 'package:flutter/material.dart';
import 'package:parcial_habitos/pages/CalendarScreen.dart';
import 'package:parcial_habitos/providers/db_habits.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const HabitTrackerScreen();
  }
}

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  _HabitTrackerScreenState createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  List<String> habits = [];
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Map<String, HabitTracking> _habitTrackings = {};

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    habits = await _databaseHelper.getHabits();

    // Cargar las fechas de cumplimiento de la base de datos
    Map<String, List<DateTime>> habitsWithDates =
        await _databaseHelper.getHabitsWithCompletionDates();

    // Inicializar el seguimiento de hábitos con los días cumplidos
    for (String habit in habits) {
      List<DateTime> completionDates = habitsWithDates[habit] ?? [];
      _habitTrackings[habit] = HabitTracking(
        habitName: habit,
        completedDays: completionDates.length,
        lastCompletionDate:
            completionDates.isNotEmpty ? completionDates.last : null,
      );
    }

    setState(() {});
  }

  void _initializeHabitTrackings() {
    for (String habit in habits) {
      _habitTrackings[habit] = HabitTracking(habitName: habit);
    }
  }

  void _addHabit(String habit) async {
    await _databaseHelper.insertHabit(habit);
    _loadHabits();
    Navigator.of(context).pop();
  }

  void _showAddHabitDialog() {
    String newHabit = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Hábito'),
          content: TextField(
            onChanged: (value) {
              newHabit = value;
            },
            decoration: const InputDecoration(hintText: 'Escribe tu hábito'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (newHabit.isNotEmpty) {
                  _addHabit(newHabit);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Mis Hábitos'),
    ),
    body: habits.isEmpty
        ? const Center(
            child: Text('No hay hábitos agregados.'),
          )
        : ListView.builder(
            itemCount: habits.length,
            itemBuilder: (context, index) {
              String habit = habits[index];
              HabitTracking? tracking = _habitTrackings[habit];

              // Verificar si el hábito tiene 21 o más días cumplidos
              bool isHabitComplete = tracking != null && tracking.completedDays >= 21;

              return ListTile(
                title: Text(habit),
                subtitle: Text(tracking != null
                    ? 'Días cumplidos: ${tracking.completedDays}'
                    : 'No hay datos de seguimiento'),
                tileColor: isHabitComplete ? Colors.green[100] : null, // Cambiar el color de fondo si cumple la condición
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _showDeleteConfirmationDialog(habit); // Mostrar el diálogo de confirmación para eliminar
                  },
                ),
              );
            },
          ),
    floatingActionButton: FloatingActionButton(
      onPressed: _showAddHabitDialog,
      child: const Icon(Icons.add),
    ),
    bottomNavigationBar: BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: 'Hábitos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Calendario',
        ),
      ],
      currentIndex: 0,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 10,
      onTap: (index) async {
        if (index == 1) {
          // Navegar a la pantalla del calendario y esperar el resultado
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalendarScreen(habits: habits),
            ),
          );

          // Recargar los hábitos cuando regresas a la pantalla principal
          _loadHabits(); // Esto recargará los datos cuando vuelvas
        }
      },
    ),
  );
}

void _showDeleteConfirmationDialog(String habit) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Eliminar Hábito'),
        content: Text('¿Estás seguro de que deseas eliminar el hábito "$habit"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar el diálogo
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _deleteHabit(habit); // Llamar a la función de eliminación
              Navigator.of(context).pop(); // Cerrar el diálogo después de eliminar
            },
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );
}


void _deleteHabit(String habit) async {
  await _databaseHelper.deleteHabit(habit); // Eliminar de la base de datos
  _loadHabits(); // Recargar la lista de hábitos después de eliminar
}


}
