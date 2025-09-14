import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// A simple data model to hold the state for each dynamic class form.
class ClassEntry {
  final UniqueKey id = UniqueKey();
  final TextEditingController classNameController = TextEditingController();
  final TextEditingController roomNumberController = TextEditingController();
  final TextEditingController teacherNameController = TextEditingController();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool isLabClass = false; // false = Theory (1hr), true = Lab (1.5hr)

  // Disposes the controllers when the form is removed
  void dispose() {
    classNameController.dispose();
    roomNumberController.dispose();
    teacherNameController.dispose();
  }
}

class AddTimetablePage extends StatefulWidget {
  const AddTimetablePage({super.key});

  @override
  State<AddTimetablePage> createState() => _AddTimetablePageState();
}

class _AddTimetablePageState extends State<AddTimetablePage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedDay;
  List<ClassEntry> _classEntries = [ClassEntry()];
  bool _isLoading = false;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void dispose() {
    for (var entry in _classEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addClassForm() {
    setState(() {
      _classEntries.add(ClassEntry());
    });
  }

  void _removeClassForm(UniqueKey id) {
    if (_classEntries.length > 1) {
      setState(() {
        final entryToRemove =
            _classEntries.firstWhere((entry) => entry.id == id);
        entryToRemove.dispose();
        _classEntries.remove(entryToRemove);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must have at least one class.")),
      );
    }
  }

  Future<void> _selectStartTime(ClassEntry entry) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: entry.startTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != entry.startTime) {
      setState(() {
        entry.startTime = picked;
        _calculateEndTime(entry);
      });
    }
  }

  void _calculateEndTime(ClassEntry entry) {
    if (entry.startTime == null) return;

    final now = DateTime.now();
    final startTimeDateTime = DateTime(now.year, now.month, now.day,
        entry.startTime!.hour, entry.startTime!.minute);
    final duration =
        entry.isLabClass ? const Duration(minutes: 100) : const Duration(minutes: 50);
    final endTimeDateTime = startTimeDateTime.add(duration);

    setState(() {
      entry.endTime = TimeOfDay.fromDateTime(endTimeDateTime);
    });
  }

  void _toggleClauseType(ClassEntry entry) {
    setState(() {
      entry.isLabClass = !entry.isLabClass;
      _calculateEndTime(entry);
    });
  }

  Future<void> _submitTimetable() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_classEntries.any((entry) => entry.startTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a start time for all classes.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User is not logged in.');
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('User data not found in Firestore. Please relogin.');
      }
      final batch = FirebaseFirestore.instance.batch();

      final collectionRef = FirebaseFirestore.instance
          .collection('timetable')
          .doc(userDoc['id'])
          .collection(_selectedDay!);

      for (final entry in _classEntries) {
        final docRef = collectionRef.doc();
        batch.set(docRef, {
          'className': entry.classNameController.text.trim(),
          'roomNumber': entry.roomNumberController.text.trim(),
          'teacherName': entry.teacherNameController.text.trim(),
          'startTime': '${entry.startTime!.hour.toString().padLeft(2, '0')}:${entry.startTime!.minute.toString().padLeft(2, '0')}',
          'endTime': '${entry.endTime!.hour.toString().padLeft(2, '0')}:${entry.endTime!.minute.toString().padLeft(2, '0')}',
          'classType': entry.isLabClass ? 'Lab' : 'Theory',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Timetable for $_selectedDay saved successfully!')),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save timetable: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5ECED),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5ECED),
        title: const Text('Add Daily Timetable'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDaySelector(),
              const SizedBox(height: 20),
              ..._buildClassForms(),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Another Class'),
                onPressed: _addClassForm,
              ),
              const SizedBox(height: 24),
              // *** MODIFIED WIDGET HERE ***
              ElevatedButton(
                onPressed: (_isLoading || _selectedDay == null) ? null : _submitTimetable,
                style: ElevatedButton.styleFrom(
                  // We removed the hardcoded backgroundColor and foregroundColor.
                  // The button will now use the colors from the ThemeData.
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(),
                      )
                    : Text('Save Timetable for $_selectedDay'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return DropdownButtonFormField<String>(
      value: _selectedDay,
      decoration: const InputDecoration(
        labelText: 'Day of the Week',
      ),
      hint: const Text('Select a day'),
      items: _daysOfWeek.map((String day) {
        return DropdownMenuItem<String>(
          value: day,
          child: Text(day),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedDay = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select a day' : null,
    );
  }

  List<Widget> _buildClassForms() {
    return _classEntries.map((entry) {
      return Card(
        color: Color(0xFFF5ECED),
        margin: const EdgeInsets.only(bottom: 16.0),
        key: entry.id,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Class Details',
                      style: Theme.of(context).textTheme.titleLarge),
                  if (_classEntries.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeClassForm(entry.id),
                    ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              TextFormField(
                controller: entry.classNameController,
                decoration: const InputDecoration(labelText: 'Class Name'),
                validator: (value) => value!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: entry.roomNumberController,
                decoration: const InputDecoration(labelText: 'Room Number'),
                validator: (value) => value!.trim().isEmpty ? 'Required' : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: entry.teacherNameController,
                decoration:
                    const InputDecoration(labelText: 'Teacher\'s Name (Optional)'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Start Time'),
                subtitle: Text(entry.startTime?.format(context) ?? 'Not set'),
                onTap: () => _selectStartTime(entry),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: const Icon(Icons.hourglass_bottom_outlined),
                title: const Text('End Time'),
                subtitle:
                    Text(entry.endTime?.format(context) ?? 'Auto-calculated'),
                trailing: OutlinedButton(
                  onPressed: () => _toggleClauseType(entry),
                  child: Text(entry.isLabClass ? 'Lab (100m)' : 'Theory (50m)'),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}