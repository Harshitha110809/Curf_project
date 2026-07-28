import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class OutPassRequestScreen extends StatefulWidget {
  const OutPassRequestScreen({super.key});

  @override
  State<OutPassRequestScreen> createState() => _OutPassRequestScreenState();
}

class _OutPassRequestScreenState extends State<OutPassRequestScreen> {
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedReason = 'Select reason';

  DateTime? _outDate;
  DateTime? _inDate;
  TimeOfDay? _exitTime;
  TimeOfDay? _returnTime;
  bool _isLoading = false;

  final _supabase = Supabase.instance.client;
  final Color _primaryPurple = const Color(0xFF5A4FCF);

  Future<void> _selectDate(BuildContext context, bool isOutDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        if (isOutDate) {
          _outDate = picked;
        } else {
          _inDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isExitTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isExitTime) {
          _exitTime = picked;
        } else {
          _returnTime = picked;
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    final dest = _destinationController.text.trim();

    // 1. Check for complete inputs
    if (dest.isEmpty || _outDate == null || _inDate == null || _exitTime == null || _returnTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please populate all parameters.")),
      );
      return;
    }

    // 2. Out-Time Validation (Cannot be before 6:00 AM)
    if (_exitTime!.hour < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Out Time cannot be set before 6:00 AM.")),
      );
      return;
    }

    // 3. Out-Time Validation (Cannot be after 8:30 PM Curfew)
    if (_exitTime!.hour > 20 || (_exitTime!.hour == 20 && _exitTime!.minute > 30)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Out Time cannot exceed the 8:30 PM curfew.")),
      );
      return;
    }

    // 4. In-Time Validation (Cannot be after 8:30 PM Curfew)
    if (_returnTime!.hour > 20 || (_returnTime!.hour == 20 && _returnTime!.minute > 30)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("In Time cannot exceed the 8:30 PM curfew.")),
      );
      return;
    }

    // Combine Dates and Times into DateTime structures
    final exitDateTime = DateTime(_outDate!.year, _outDate!.month, _outDate!.day, _exitTime!.hour, _exitTime!.minute);
    final returnDateTime = DateTime(_inDate!.year, _inDate!.month, _inDate!.day, _returnTime!.hour, _returnTime!.minute);

    // 5. Logical validation check
    if (returnDateTime.isBefore(exitDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Expected return timeline cannot happen before your out timeline.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      final profile = await _supabase.from('users').select('id').eq('auth_user_id', user?.id ?? '').single();

      await _supabase.from('out_pass_requests').insert({
        'student_id': profile['id'],
        'destination': dest,
        'reason': "$_selectedReason. Details: ${_notesController.text.trim()}",
        // FIX: Converted to UTC before sending to Supabase
        'departure_time': exitDateTime.toUtc().toIso8601String(),
        'expected_return_time': returnDateTime.toUtc().toIso8601String(),
        'status': 'pending'
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Posted!"), backgroundColor: Colors.green));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submission Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("New Out-Pass Request", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: _primaryPurple,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _destinationController,
            decoration: InputDecoration(labelText: "Destination Location", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),

          // Split Date Picker Layout Fields
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Out Date", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  subtitle: Text(_outDate == null ? "Select" : DateFormat('yyyy-MM-dd').format(_outDate!), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("In Date", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  subtitle: Text(_inDate == null ? "Select" : DateFormat('yyyy-MM-dd').format(_inDate!), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          const Divider(),

          // Split Time Picker Layout Fields
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Out Time (Min: 6 AM)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  subtitle: Text(_exitTime == null ? "Select" : _exitTime!.format(context), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                  trailing: const Icon(Icons.access_time, size: 18),
                  onTap: () => _selectTime(context, true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("In Time (Max: 8:30 PM)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  subtitle: Text(_returnTime == null ? "Select" : _returnTime!.format(context), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                  trailing: const Icon(Icons.access_time, size: 18),
                  onTap: () => _selectTime(context, false),
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),

          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(labelText: "Reason Notes Context", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _submitRequest,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Outpass Request", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}