import 'package:flutter/material.dart';
import 'package:parcial_habitos/providers/db_habits.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class CalendarScreen extends StatefulWidget {
  final List<String> habits;

  const CalendarScreen({super.key, required this.habits});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class HabitTracking {
  String habitName;
  int completedDays;
  DateTime? lastCompletionDate;

  HabitTracking(
      {required this.habitName,
      this.completedDays = 0,
      this.lastCompletionDate});
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<String> _habitsForSelectedDay = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, HabitTracking> _habitTrackings = {};

  @override
  void initState() {
    super.initState();
    for (String habit in widget.habits) {
      _habitTrackings[habit] = HabitTracking(habitName: habit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Calendario de Rutinas'),
          ),
          body: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _loadHabitsForSelectedDay();
                },
                calendarFormat: CalendarFormat.month,
                eventLoader: (day) {
                  return _habitTrackings.entries
                      .where((entry) =>
                          entry.value.lastCompletionDate != null &&
                          isSameDay(entry.value.lastCompletionDate!, day))
                      .map((entry) => entry.key)
                      .toList();
                },
              ),
              const SizedBox(height: 20),
              if (_selectedDay != null)
                ElevatedButton(
                  onPressed: () {
                    _showAddEventDialog(context);
                  },
                  child: const Text('Marcar hábito como cumplido'),
                ),
              const SizedBox(height: 20),
              const Text('Hábitos:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: _habitsForSelectedDay.isEmpty
                    ? const Center(
                        child: Text('No hay hábitos cumplidos en esta fecha.'),
                      )
                    : ListView.builder(
                        itemCount: _habitsForSelectedDay.length,
                        itemBuilder: (context, index) {
                          String habit = _habitsForSelectedDay[index];
                          return ListTile(
                            title: Text(habit),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

 void _loadHabitsForSelectedDay() async {
  if (_selectedDay == null) return;

  // Reiniciar la lista de hábitos para el día seleccionado
  _habitsForSelectedDay.clear();

  // Obtener todas las fechas de cumplimiento de la base de datos
  Map<String, List<DateTime>> habitsWithCompletionDates = await DatabaseHelper().getHabitsWithCompletionDates();

  // Filtrar los hábitos que coinciden con la fecha seleccionada
  for (var entry in habitsWithCompletionDates.entries) {
    String habitName = entry.key;
    List<DateTime> completionDates = entry.value;

    if (completionDates.any((date) => isSameDay(date, _selectedDay!))) {
      _habitsForSelectedDay.add(habitName);
    }
  }

  // Actualizar la UI
  setState(() {});
}

void _showAddEventDialog(BuildContext context) {
  String? selectedHabit;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Selecciona un hábito'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Si la lista de hábitos está vacía, muestra un mensaje.
                if (widget.habits.isEmpty)
                  const Text('No hay hábitos disponibles para seleccionar'),
                if (widget.habits.isNotEmpty)
                  DropdownButton<String>(
                    hint: const Text('Selecciona un hábito'),
                    value: selectedHabit,
                    items: widget.habits.map((String habit) {
                      return DropdownMenuItem<String>(
                        value: habit,
                        child: Text(habit),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedHabit = newValue;
                      });
                    },
                  ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (selectedHabit == null || _selectedDay == null) {
                return; // No hacer nada si no hay hábito seleccionado
              }

              _updateHabitTracking(selectedHabit!, _selectedDay!);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}


void _updateHabitTracking(String habit, DateTime selectedDay) async {
  HabitTracking tracking = _habitTrackings[habit]!;

  if (tracking.lastCompletionDate != null) {
    if (isSameDay(tracking.lastCompletionDate!.add(Duration(days: 1)), selectedDay)) {
      tracking.completedDays++;
    } else if (tracking.lastCompletionDate!.isBefore(selectedDay)) {
      tracking.completedDays = 1;
    }
  } else {
    tracking.completedDays = 1;
  }

  tracking.lastCompletionDate = selectedDay;

  // Obtener el ID del hábito y guardar la fecha de cumplimiento en la base de datos
  final habitId = await DatabaseHelper().getHabitIdByName(habit);

  if (habitId != null) {
    await DatabaseHelper().insertHabitCompletion(habitId, selectedDay);

    // Aquí actualizas el estado para que se refleje el cambio
    setState(() {
      _habitTrackings[habit] = tracking;
    });

    // Recargar la lista de hábitos cumplidos en la fecha seleccionada
    _loadHabitsForSelectedDay();
  } else {
    print("Error: No se encontró el ID del hábito.");
  }
}


}
