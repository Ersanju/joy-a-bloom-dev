import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/reminder_model.dart';
import 'reminder_list_page.dart';

class ReminderPage extends StatefulWidget {
  final Reminder? reminder;

  const ReminderPage({super.key, this.reminder});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  String? selectedRelation;
  String? selectedOccasion;
  DateTime? selectedDate;

  final List<String> relations = [
    'Partner',
    'Boyfriend',
    'Girlfriend',
    'Husband',
    'Wife',
    'Brother',
    'Sister',
    'Mother',
    'Son',
    'Daughter',
    'Friend',
  ];

  final List<String> occasions = [
    'Birthday',
    'Anniversary',
    'Graduation',
    'Promotion',
    'Retirement',
    'Farewell',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat('d-MMMM').format(picked);
      });
    }
  }

  void _showBottomSheet(
    BuildContext context,
    String title,
    List<String> options,
    Function(String) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                ), // You can adjust the value
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(thickness: 0.5),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    options.map((option) {
                      return ChoiceChip(
                        label: Text(option),
                        selected: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onSelected: (_) {
                          onSelected(option);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveReminder() async {
    if (_nameController.text.isNotEmpty &&
        selectedRelation != null &&
        selectedOccasion != null &&
        selectedDate != null) {
      final reminder = Reminder(
        id: '',
        name: _nameController.text.trim(),
        relation: selectedRelation!,
        occasion: selectedOccasion!,
        date: selectedDate!,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc('ersanjay') // Replace with dynamic user ID
          .collection('reminders')
          .add(reminder.toMap());

      if (!mounted) return; // ✅ This ensures widget is still in tree

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder saved')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ReminderListPage()),
      );
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reminder')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: RichText(
                text: TextSpan(
                  text: "Save important occasions with us 👋\n",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text:
                          "We will remind you a week prior to plan your perfect gifts 🎁",
                      style: TextStyle(fontSize: 13.0, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Add A Quick Reminder ⚡',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Gift Receiver's Name",
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap:
                        () => _showBottomSheet(
                          context,
                          'Select Relation',
                          relations,
                          (val) {
                            setState(() => selectedRelation = val);
                          },
                        ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(selectedRelation ?? 'Relation'),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap:
                        () => _showBottomSheet(
                          context,
                          'Select Occasion',
                          occasions,
                          (val) {
                            setState(() => selectedOccasion = val);
                          },
                        ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cake, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(selectedOccasion ?? 'Occasion'),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: const InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade400,
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saveReminder,
              child: Text(
                'Save',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
