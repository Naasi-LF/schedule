import 'package:flutter/material.dart';
import 'package:notes/models/event.dart';
import 'package:notes/models/event_database.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadEvents();
  }

  void _loadEvents() {
    final eventDatabase = context.read<EventDatabase>();
    final events = eventDatabase.currentEvents;
    _events = {};
    
    for (var event in events) {
      final date = DateTime(
        event.dateTime.year,
        event.dateTime.month,
        event.dateTime.day,
      );
      if (_events[date] == null) _events[date] = [];
      _events[date]!.add(event);
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.birthday:
        return Colors.pink;
      case EventType.meeting:
        return Colors.blue;
      case EventType.homework:
        return Colors.orange;
      case EventType.exam:
        return Colors.red;
      case EventType.other:
        return Colors.purple;
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.birthday:
        return Icons.cake;
      case EventType.meeting:
        return Icons.people;
      case EventType.homework:
        return Icons.book;
      case EventType.exam:
        return Icons.school;
      case EventType.other:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Calendar',
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              markerDecoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<EventDatabase>(
              builder: (context, eventDatabase, child) {
                _loadEvents();
                final dayEvents = _getEventsForDay(_selectedDay);
                if (dayEvents.isEmpty) {
                  return Center(
                    child: Text(
                      'No events for ${DateFormat('yyyy-MM-dd').format(_selectedDay)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: dayEvents.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final event = dayEvents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getEventTypeColor(event.type),
                          child: Icon(
                            _getEventTypeIcon(event.type),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          event.title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(event.dateTime),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.inversePrimary,
                              ),
                            ),
                            if (event.location != null && event.location!.isNotEmpty)
                              Text(
                                '📍 ${event.location!}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.inversePrimary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
