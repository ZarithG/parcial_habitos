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
    _initializeHabitTrackings();
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

                return ListTile(
                  title: Text(habit),
                  subtitle: Text(tracking != null
                      ? 'Días cumplidos: ${tracking.completedDays}'
                      : 'No hay datos de seguimiento'),
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
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CalendarScreen(
                          habits: habits,
                        )),
              );
              break;
          }
        },
      ),
    );
  }
}
