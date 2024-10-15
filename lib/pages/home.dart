import 'package:flutter/material.dart';

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

  void _addHabit(String habit) {
    setState(() {
      habits.add(habit);
    });
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
                return ListTile(
                  title: Text(habits[index]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
