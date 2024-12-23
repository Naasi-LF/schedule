import 'package:flutter/material.dart';
import 'package:notes/models/event.dart';
import 'package:notes/models/event_database.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:notes/components/drawer.dart';
import 'package:notes/pages/calendar_page.dart';
import 'package:notes/animations/page_route_animation.dart';
import 'package:notes/models/user_database.dart';
import 'package:notes/pages/create_event_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _notificationMinutesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  EventType _selectedType = EventType.other;
  bool _hasNotification = false;
  int? _selectedColor;

  final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    context.read<EventDatabase>().fetchEvents();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.inversePrimary,
                  onPrimary: Theme.of(context).colorScheme.surface,
                  surface: Theme.of(context).colorScheme.surface,
                  onSurface: Theme.of(context).colorScheme.inversePrimary,
                ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.inversePrimary,
                  onPrimary: Theme.of(context).colorScheme.surface,
                  surface: Theme.of(context).colorScheme.surface,
                  onSurface: Theme.of(context).colorScheme.inversePrimary,
                ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _showColorPicker() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Select Color',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color.value;
                  });
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color.value
                          ? Theme.of(context).colorScheme.inversePrimary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _createEvent() {
    _resetEventInputs(); // Reset all inputs before showing dialog
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Create Event',
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<EventType>(
                      value: _selectedType,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: InputDecoration(
                        labelText: 'Event Type',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      items: EventType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.toString().split('.').last,
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        'Event Color',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      trailing: GestureDetector(
                        onTap: _showColorPicker,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _selectedColor != null
                                ? Color(_selectedColor!)
                                : Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .inversePrimary
                              .withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    icon: Icon(
                                      Icons.calendar_today,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                    ),
                                    onPressed: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2101),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: Theme.of(context)
                                                  .colorScheme
                                                  .copyWith(
                                                    primary: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary,
                                                    onPrimary: Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                                    surface: Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                                    onSurface: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary,
                                                  ),
                                              textButtonTheme:
                                                  TextButtonThemeData(
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .inversePrimary,
                                                ),
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (date != null) {
                                        setState(() {
                                          _selectedDate = date;
                                        });
                                      }
                                    },
                                    label: Text(
                                      'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inversePrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton.icon(
                                    icon: Icon(
                                      Icons.access_time,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                    ),
                                    onPressed: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: _selectedTime,
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: Theme.of(context)
                                                  .colorScheme
                                                  .copyWith(
                                                    primary: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary,
                                                    onPrimary: Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                                    surface: Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                                    onSurface: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary,
                                                  ),
                                              textButtonTheme:
                                                  TextButtonThemeData(
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .inversePrimary,
                                                ),
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _selectedTime = time;
                                        });
                                      }
                                    },
                                    label: Text(
                                      'Time: ${_selectedTime.format(context)}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inversePrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationController,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Location',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .inversePrimary
                              .withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Enable Notification',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary,
                                ),
                              ),
                              Switch(
                                value: _hasNotification,
                                onChanged: (value) {
                                  setState(() {
                                    _hasNotification = value;
                                  });
                                },
                                activeColor: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                              ),
                            ],
                          ),
                          if (_hasNotification) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Notify before (minutes):',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: _notificationMinutesController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.inversePrimary,
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final userId = context.read<UserDatabase>().currentUser?.id;
                    if (userId == null) return;

                    final dateTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );

                    final event = Event(
                      userId: userId,
                      title: _titleController.text,
                      type: _selectedType,
                      dateTime: dateTime,
                      location: _locationController.text,
                      notes: _notesController.text,
                      hasNotification: _hasNotification,
                      notificationMinutesBefore: _hasNotification
                          ? int.tryParse(_notificationMinutesController.text)
                          : null,
                      color: _selectedColor,
                    );

                    context.read<EventDatabase>().addEvent(event);

                    // Clear form
                    _titleController.clear();
                    _locationController.clear();
                    _notesController.clear();
                    _notificationMinutesController.clear();

                    Navigator.pop(context);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _resetEventInputs() {
    _titleController.clear();
    _locationController.clear();
    _notesController.clear();
    _notificationMinutesController.clear();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _selectedType = EventType.other;
    _hasNotification = false;
    _selectedColor = null;
  }

  void _deleteEvent(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Delete Event',
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this event?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<EventDatabase>().deleteEvent(id);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editEvent(Event event) {
    // Pre-fill the form with event data
    _titleController.text = event.title;
    _locationController.text = event.location ?? '';
    _notesController.text = event.notes ?? '';
    _selectedDate = event.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(event.dateTime);
    _selectedType = event.type;
    _hasNotification = event.hasNotification;
    if (_hasNotification) {
      _notificationMinutesController.text =
          (event.notificationMinutesBefore ?? 0).toString();
    }
    _selectedColor = event.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Edit Event',
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<EventType>(
                      value: _selectedType,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: InputDecoration(
                        labelText: 'Event Type',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      items: EventType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.toString().split('.').last,
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        'Event Color',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      trailing: GestureDetector(
                        onTap: _showColorPicker,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _selectedColor != null
                                ? Color(_selectedColor!)
                                : Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .inversePrimary
                              .withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    icon: Icon(
                                      Icons.calendar_today,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                    ),
                                    onPressed: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2101),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: Theme.of(context)
                                                  .colorScheme
                                                  .copyWith(
                                                    primary: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary,
                                                    onPrimary: Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                                    surface: Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                                    onSurface: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary,
                                                  ),
                                              textButtonTheme:
                                                  TextButtonThemeData(
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .inversePrimary,
                                                ),
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (date != null) {
                                        setState(() {
                                          _selectedDate = date;
                                        });
                                      }
                                    },
                                    label: Text(
                                      'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inversePrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton.icon(
                                    icon: Icon(
                                      Icons.access_time,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                    ),
                                    onPressed: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: _selectedTime,
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: Theme.of(context)
                                                  .colorScheme
                                                  .copyWith(
                                                    primary: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary,
                                                    onPrimary: Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                                    surface: Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                                    onSurface: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary,
                                                  ),
                                              textButtonTheme:
                                                  TextButtonThemeData(
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .inversePrimary,
                                                ),
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _selectedTime = time;
                                        });
                                      }
                                    },
                                    label: Text(
                                      'Time: ${_selectedTime.format(context)}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inversePrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationController,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Location',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .inversePrimary
                              .withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Enable Notification',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary,
                                ),
                              ),
                              Switch(
                                value: _hasNotification,
                                onChanged: (value) {
                                  setState(() {
                                    _hasNotification = value;
                                  });
                                },
                                activeColor: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                              ),
                            ],
                          ),
                          if (_hasNotification) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Notify before (minutes):',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: _notificationMinutesController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.inversePrimary,
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final userId = context.read<UserDatabase>().currentUser?.id;
                    if (userId == null) return;

                    final dateTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );

                    final updatedEvent = Event(
                      id: event.id,
                      userId: userId,
                      title: _titleController.text,
                      type: _selectedType,
                      dateTime: dateTime,
                      location: _locationController.text,
                      notes: _notesController.text,
                      hasNotification: _hasNotification,
                      notificationMinutesBefore: _hasNotification
                          ? int.tryParse(_notificationMinutesController.text)
                          : null,
                      color: _selectedColor,
                    );

                    context.read<EventDatabase>().updateEvent(updatedEvent);

                    // Clear form
                    _titleController.clear();
                    _locationController.clear();
                    _notesController.clear();
                    _notificationMinutesController.clear();

                    Navigator.pop(context);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Schedule App',
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                SlidePageRoute(
                  page: const CalendarPage(),
                  direction: SlideDirection.left,
                ),
              );
            },
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: Consumer<EventDatabase>(
        builder: (context, eventDatabase, child) {
          final events = eventDatabase.currentEvents;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 500 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        // 左侧彩色边框
                        Container(
                          width: 6,
                          decoration: BoxDecoration(
                            color: event.color != null
                                ? Color(event.color!).withOpacity(0.8)
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surface,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                  ),
                                  builder: (context) => Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              event.title,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .inversePrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.edit,
                                                    color: event.color != null
                                                        ? Color(event.color!)
                                                            .withOpacity(0.8)
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _editEvent(event);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    color: event.color != null
                                                        ? Color(event.color!)
                                                            .withOpacity(0.8)
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _deleteEvent(event.id!);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        if (event.location?.isNotEmpty ??
                                            false) ...[
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .inversePrimary
                                                    .withOpacity(0.7),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  event.location!,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        if (event.notes?.isNotEmpty ??
                                            false) ...[
                                          Text(
                                            event.notes!,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .inversePrimary
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        if (event.hasNotification) ...[
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.notifications_active,
                                                size: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .inversePrimary
                                                    .withOpacity(0.7),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${event.notificationMinutesBefore} minutes before',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .inversePrimary
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getEventIcon(event.type),
                                      color: event.color != null
                                          ? Color(event.color!).withOpacity(0.8)
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            event.title,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .inversePrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('MMM dd, yyyy • HH:mm')
                                                .format(event.dateTime),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .inversePrimary
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEventPage(),
            ),
          ).then((_) {
            // 刷新事件列表
            _loadEvents();
          });
        },
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.birthday:
        return Icons.cake;
      case EventType.meeting:
        return Icons.people;
      case EventType.homework:
        return Icons.assignment;
      case EventType.exam:
        return Icons.school;
      case EventType.other:
        return Icons.event;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _notificationMinutesController.dispose();
    super.dispose();
  }
}
