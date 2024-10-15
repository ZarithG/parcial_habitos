import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class CalendarScreen extends StatefulWidget {
  final List<String> habits; // Nueva propiedad para recibir hábitos

  const CalendarScreen(
      {super.key, required this.habits}); // Constructor modificado

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Map para guardar eventos con sus respectivos colores
  Map<DateTime, Map<String, Color>> _events = {};

  final TextEditingController _eventController = TextEditingController();
  Color _selectedColor = Colors.blue; // Color por defecto
  final FocusNode _focusNode = FocusNode();

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
                },
                calendarFormat: CalendarFormat.month,
                eventLoader: (day) {
                  // Muestra eventos para ese día
                  return _events[day]?.keys.toList() ?? [];
                },
                // Personaliza el estilo del calendario para días con eventos
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (_events[date] != null && _events[date]!.isNotEmpty) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _events[date]!.entries.map((entry) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: entry.value, // Color del evento
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedDay != null)
                ElevatedButton(
                  onPressed: () {
                    _showAddEventDialog(context);
                  },
                  child: const Text('Agregar evento'),
                ),
              const SizedBox(height: 20),

              // Mostrar lista de hábitos
              Text('Hábitos:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.habits.length, // Usar la lista de hábitos
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(widget.habits[index]),
                    );
                  },
                ),
              ),
              _buildEventList(), // Mantener la lista de eventos
            ],
          ),
        );
      },
    );
  }

  // Diálogo para agregar eventos con colores
  void _showAddEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Si tienes eventos en la base de datos, pásalos a una lista de Strings
            List<String> availableEvents =
                widget.habits; // Lista de hábitos/eventos guardados

            String?
                selectedEvent; // Variable para almacenar el evento seleccionado

            return AlertDialog(
              title: const Text('Agregar Evento con Color'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Combobox para seleccionar evento
                  DropdownButton<String>(
                    hint: const Text('Selecciona un evento'),
                    value: selectedEvent,
                    items: availableEvents.map((String event) {
                      return DropdownMenuItem<String>(
                        value: event,
                        child: Text(event),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedEvent = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  // Dropdown para seleccionar color
                  DropdownButton<Color>(
                    value: _selectedColor,
                    items: [
                      DropdownMenuItem(
                        value: Colors.red,
                        child:
                            Text('Rojo', style: TextStyle(color: Colors.red)),
                      ),
                      DropdownMenuItem(
                        value: Colors.green,
                        child: Text('Verde',
                            style: TextStyle(color: Colors.green)),
                      ),
                      DropdownMenuItem(
                        value: Colors.blue,
                        child:
                            Text('Azul', style: TextStyle(color: Colors.blue)),
                      ),
                    ],
                    onChanged: (color) {
                      setState(() {
                        _selectedColor = color!;
                      });
                    },
                  ),
                ],
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
                    if (selectedEvent == null) return;

                    setState(() {
                      // Agregar el evento con su color
                      if (_events[_selectedDay] != null) {
                        _events[_selectedDay]![selectedEvent!] = _selectedColor;
                      } else {
                        _events[_selectedDay!] = {
                          selectedEvent!: _selectedColor,
                        };
                      }
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Lista de eventos del día seleccionado
  Widget _buildEventList() {
    if (_selectedDay == null || _events[_selectedDay] == null) {
      return const Text('No hay eventos para este día.');
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _events[_selectedDay]!.length,
        itemBuilder: (context, index) {
          String event = _events[_selectedDay]!.keys.elementAt(index);
          Color color = _events[_selectedDay]!.values.elementAt(index);
          return ListTile(
            title: Text(event),
            leading: CircleAvatar(
              backgroundColor: color,
            ),
          );
        },
      ),
    );
  }
}
