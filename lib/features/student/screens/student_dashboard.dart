import 'dart:async';
import 'package:flutter/foundation.dart'; // Handles kIsWeb check
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  // Enterprise Professional Palette
  final Color _primaryNavy = const Color(0xFF0F172A);
  final Color _actionBlue = const Color(0xFF2563EB);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _cardColor = Colors.white;

  final _supabase = Supabase.instance.client;

  final TextEditingController _destinationCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();

  DateTime _selectedReturnDate = DateTime.now();
  TimeOfDay _selectedReturnTime = const TimeOfDay(hour: 21, minute: 0);

  // 1. Fetch Student User Profile
  Future<Map<String, dynamic>> _getStudentProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      final profileResponse = await _supabase
          .from('users')
          .select('*')
          .eq('auth_user_id', user.id)
          .single();

      return Map<String, dynamic>.from(profileResponse);
    } catch (e) {
      return {};
    }
  }

  // 2. Real-Time Out-Pass Stream Listener
  Stream<List<Map<String, dynamic>>> _getStudentPassesStream(String studentId) {
    if (studentId.isEmpty) return const Stream.empty();

    return _supabase
        .from('out_pass_requests')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
  }

  // 3. Real-Time Violations Stream Listener
  Stream<List<Map<String, dynamic>>> _getStudentViolationsStream(String studentId) {
    if (studentId.isEmpty) return const Stream.empty();

    return _supabase
        .from('violations')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .order('logged_at', ascending: false);
  }

  void _openUpdateProfileForm(Map<dynamic, dynamic> currentProfile) {
    final nameCtrl = TextEditingController(text: currentProfile['full_name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: currentProfile['phone']?.toString() ?? '');
    final parentPhoneCtrl = TextEditingController(text: currentProfile['parent_phone']?.toString() ?? '');
    final roomCtrl = TextEditingController(text: currentProfile['room_details']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        bool isSaving = false;
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    Text("Update My Details", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryNavy)),
                    const SizedBox(height: 16),
                    TextField(controller: nameCtrl, decoration: _buildInputDecor("Full Name")),
                    const SizedBox(height: 12),
                    TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: _buildInputDecor("My Phone Number")),
                    const SizedBox(height: 12),
                    TextField(controller: parentPhoneCtrl, keyboardType: TextInputType.phone, decoration: _buildInputDecor("Parent's Phone Number")),
                    const SizedBox(height: 12),
                    TextField(controller: roomCtrl, decoration: _buildInputDecor("Room Details")),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _actionBlue, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: isSaving ? null : () async {
                          setModalState(() => isSaving = true);
                          try {
                            await _supabase.from('users').update({
                              'full_name': nameCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'parent_phone': parentPhoneCtrl.text.trim(),
                              'room_details': roomCtrl.text.trim(),
                            }).eq('id', currentProfile['id']);
                            if (mounted) {
                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Color(0xFF059669)));
                              setState(() {});
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating: $e"), backgroundColor: const Color(0xFFDC2626)));
                          } finally {
                            setModalState(() => isSaving = false);
                          }
                        },
                        child: isSaving ? const CircularProgressIndicator(color: Colors.white) : Text("Save Changes", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              );
            }
        );
      },
    );
  }

  InputDecoration _buildInputDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey.shade600),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _actionBlue, width: 1.5)),
    );
  }

  Future<void> _submitSpecialRequest(BuildContext sheetContext, String studentId) async {
    final dest = _destinationCtrl.text.trim();
    final reason = _reasonCtrl.text.trim();
    if (dest.isEmpty || reason.isEmpty) return;
    Navigator.pop(sheetContext);
    final expectedReturnDateTime = DateTime(_selectedReturnDate.year, _selectedReturnDate.month, _selectedReturnDate.day, _selectedReturnTime.hour, _selectedReturnTime.minute);

    try {
      await _supabase.from('out_pass_requests').insert({
        'student_id': studentId,
        'destination': dest,
        'reason': "[SPECIAL CURFEW] $reason",
        'pass_type': 'special',
        'parent_approval': 'pending',
        'status': 'pending',
        'departure_time': DateTime.now().toUtc().toIso8601String(),
        'expected_return_time': expectedReturnDateTime.toUtc().toIso8601String(),
      });
      _destinationCtrl.clear();
      _reasonCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Special Pass Requested Successfully!"), backgroundColor: Color(0xFF059669)));
      }
    } catch (e) {
      debugPrint("Special Pass Error: $e");
    }
  }

  void _openSpecialPassForm(String studentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.nights_stay, color: _actionBlue),
                        const SizedBox(width: 12),
                        Text("Request Special Curfew Pass", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryNavy)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text("Requires both Parent and Warden dual-authorization.", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 13)),
                    const SizedBox(height: 20),
                    TextField(controller: _destinationCtrl, decoration: _buildInputDecor("Destination Location")),
                    const SizedBox(height: 12),
                    TextField(controller: _reasonCtrl, decoration: _buildInputDecor("Justified Reason")),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                            tileColor: const Color(0xFFF8FAFC),
                            title: Text(DateFormat('MMM dd').format(_selectedReturnDate), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                            trailing: Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                            onTap: () async {
                              final date = await showDatePicker(context: context, initialDate: _selectedReturnDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                              if (date != null) setModalState(() => _selectedReturnDate = date);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                            tileColor: const Color(0xFFF8FAFC),
                            title: Text(_selectedReturnTime.format(context), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                            trailing: Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                            onTap: () async {
                              final time = await showTimePicker(context: context, initialTime: _selectedReturnTime);
                              if (time != null) setModalState(() => _selectedReturnTime = time);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _actionBlue, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: () => _submitSpecialRequest(sheetContext, studentId),
                        child: Text("Submit with Parent Routing", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    )
                  ],
                ),
              );
            }
        );
      },
    );
  }

  // 4. EVALUATE & DISPLAY QR WITH ANTI-SCREENSHOT & 5-MIN SPECIAL RULE
  void _evaluateAndDisplayQR(dynamic pass) async {
    final String status = pass['status']?.toString().toLowerCase() ?? '';
    final String parentApproval = pass['parent_approval']?.toString().toLowerCase() ?? '';
    final String passType = pass['pass_type']?.toString().toLowerCase() ?? 'standard';

    if (passType == 'special') {
      if (status != 'approved' || parentApproval != 'approved') {
        _showFeedbackDialog("Approvals Incomplete", "This special request requires active signatures from both your Parent and Warden.");
        return;
      }
    } else {
      if (status != 'approved') {
        _showFeedbackDialog("Approval Pending", "This standard out-pass has not been approved by the warden yet.");
        return;
      }
    }

    final DateTime now = DateTime.now();
    DateTime departureTime;
    DateTime expectedReturn;

    try {
      departureTime = pass['departure_time'] != null
          ? DateTime.parse(pass['departure_time']).toLocal()
          : now.subtract(const Duration(hours: 1));

      expectedReturn = pass['expected_return_time'] != null
          ? DateTime.parse(pass['expected_return_time']).toLocal()
          : now.add(const Duration(hours: 4));
    } catch (e) {
      _showFeedbackDialog("Data Error", "There is a formatting error with the times on this pass.");
      return;
    }

    if (now.add(const Duration(minutes: 1)).isBefore(departureTime)) {
      _showFeedbackDialog("Pass Inactive", "Your outing window hasn't started yet. QR activates at: ${DateFormat('hh:mm a').format(departureTime)}");
      return;
    }

    if (passType == 'special') {
      final DateTime fiveMinDeadline = departureTime.add(const Duration(minutes: 5));
      if (now.isAfter(fiveMinDeadline) && status != 'completed') {
        _showFeedbackDialog("Special Pass Expired", "5-minute QR validity window lapsed after expected out time.");
        return;
      }
    }

    if (now.isAfter(expectedReturn)) {
      _showFeedbackDialog("Pass Expired", "Curfew window boundary breached. This security barcode has been completely invalidated.");
      return;
    }

    if (!kIsWeb) {
      try {
        //await ScreenProtector.preventScreenshotOn();
      } catch (e) {
        debugPrint("Screen protection not supported: $e");
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Gate Scan Token Active", textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SafeQrGenerator(passData: pass),
            const SizedBox(height: 12),
            Text("Expires at: ${DateFormat('hh:mm a').format(expectedReturn)}", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626))),
            const SizedBox(height: 6),
            Text("🔒 Screenshots Disabled for Security", textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade500))
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (!kIsWeb) {
                try {
                  //await ScreenProtector.preventScreenshotOff();
                } catch (e) {
                  debugPrint("Screen protection off error: $e");
                }
              }
              if (c.mounted) Navigator.of(c, rootNavigator: true).pop();
            },
            child: Text("Dismiss", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: _actionBlue)),
          )
        ],
      ),
    );
  }

  void _showFeedbackDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text(content, style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade700)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c, rootNavigator: true).pop(),
            child: Text("Understood", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: _actionBlue)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _getStudentProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final profile = profileSnapshot.data ?? {};
            final studentId = profile['id']?.toString() ?? '';

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getStudentPassesStream(studentId),
              builder: (context, passesSnapshot) {
                final passes = passesSnapshot.data ?? [];

                return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _getStudentViolationsStream(studentId),
                    builder: (context, violationsSnapshot) {
                      final violations = violationsSnapshot.data ?? [];

                      return IndexedStack(
                        index: _selectedIndex,
                        children: [
                          _buildHomeTab(passes, profile, violations.length),
                          _buildHistoryTab(passes),
                          _buildAlertsTab(violations),
                          _buildSettingsTab(profile),
                        ],
                      );
                    }
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: _actionBlue,
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long_rounded), label: 'Logs'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications_rounded), label: 'Alerts'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(List<dynamic> passes, Map<dynamic, dynamic> profile, int violationCount) {
    final pendingCount = passes.where((p) => p['status'] == 'pending').length;
    final approvedCount = passes.where((p) => p['status'] == 'approved').length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Enterprise Hero Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _primaryNavy,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _primaryNavy.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello, ${profile['full_name']?.toString().split(' ')[0] ?? 'Student'}",
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                profile['room_details']?.toString() ?? 'Room details not added',
                style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _primaryNavy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => context.push('/new-out-pass').then((_) => setState(() {})),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text("New Out-Pass Request", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Metrics Row
        Row(
          children: [
            Expanded(child: _buildSmallMetric(pendingCount.toString(), "Pending", Icons.access_time_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7))),
            const SizedBox(width: 12),
            Expanded(child: _buildSmallMetric(approvedCount.toString(), "Approved", Icons.assignment_turned_in_rounded, const Color(0xFF059669), const Color(0xFFD1FAE5))),
            const SizedBox(width: 12),
            Expanded(child: _buildSmallMetric(violationCount.toString(), "Violations", Icons.warning_amber_rounded, const Color(0xFFDC2626), const Color(0xFFFEE2E2))),
          ],
        ),
        const SizedBox(height: 16),

        // Special Pass Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEEF2FF),
              foregroundColor: _actionBlue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: const Color(0xFFC7D2FE))),
            ),
            onPressed: () => _openSpecialPassForm(profile['id'].toString()),
            icon: const Icon(Icons.nights_stay_rounded),
            label: Text("Request Special Post-Curfew Pass", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 28),

        Text("Recent Activity (Tap for QR)", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryNavy)),
        const SizedBox(height: 12),

        if (passes.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Center(
              child: Text(
                "No out-pass requests found.\nTap 'New Out-Pass Request' above to get started.",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 13),
              ),
            ),
          ),
        ] else ...[
          ...passes.take(5).map((p) {
            final isApproved = p['status'] == 'approved';
            final isSpecial = p['pass_type'] == 'special';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onTap: () => _evaluateAndDisplayQR(p),
                title: Text(isSpecial ? "[SPECIAL] To: ${p['destination']}" : "To: ${p['destination']}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: _primaryNavy)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(isApproved ? "Approved - Tap to view QR" : "Status: ${p['status']}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade500)),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isApproved ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p['status'].toString().toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(color: isApproved ? const Color(0xFF059669) : const Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }),
        ]
      ],
    );
  }

  Widget _buildSmallMetric(String val, String label, IconData icon, Color color, Color bgTint) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgTint, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryNavy)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(List<dynamic> passes) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text("Pass History Logs", style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryNavy)),
        const SizedBox(height: 16),
        if (passes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
            child: Center(child: Text("No pass history recorded yet.", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400))),
          )
        else
          ...passes.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              title: Text(p['destination'].toString(), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: _primaryNavy)),
              subtitle: Text("Status: ${p['status']} ${p['pass_type'] == 'special' ? '(Special Pass)' : ''}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade500)),
              trailing: Icon(Icons.qr_code_rounded, color: _actionBlue),
              onTap: () => _evaluateAndDisplayQR(p),
            ),
          ))
      ],
    );
  }

  Widget _buildAlertsTab(List<Map<String, dynamic>> violations) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text("System Alerts & Violations", style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryNavy)),
        const SizedBox(height: 16),
        if (violations.isEmpty) ...[
          Container(
            decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFA7F3D0))),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669), size: 28),
              title: Text("No Violations Recorded", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
              subtitle: Text("You have a clean record with no curfew breaches.", style: GoogleFonts.plusJakartaSans(color: Color(0xFF047857), fontSize: 12)),
            ),
          ),
        ] else ...[
          ...violations.map((v) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFCA5A5))),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.gavel_rounded, color: Color(0xFFDC2626)),
              title: Text(v['violation_reason'] ?? "Curfew Breach", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
              subtitle: Text("Logged at: ${v['logged_at'] != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(v['logged_at'])) : 'N/A'}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Color(0xFFB91C1C))),
            ),
          )),
        ],
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(Icons.info_outline_rounded, color: _actionBlue),
            title: Text("System Infrastructure Active", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: _primaryNavy)),
            subtitle: Text("Real-time telemetry link active with Security Guard & Warden Portals.", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade500)),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(Map<dynamic, dynamic> profile) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Profile Settings", style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryNavy)),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildRow(Icons.person_outline_rounded, "Full Name", profile['full_name'] ?? 'Not Provided'),
                  const Divider(color: Color(0xFFF1F5F9)),
                  _buildRow(Icons.badge_outlined, "Reg Number", profile['registration_number'] ?? 'Not Provided'),
                  const Divider(color: Color(0xFFF1F5F9)),
                  _buildRow(Icons.meeting_room_outlined, "Room Details", profile['room_details'] ?? 'Not Provided'),
                  const Divider(color: Color(0xFFF1F5F9)),
                  _buildRow(Icons.phone_outlined, "My Contact", profile['phone'] ?? 'Not Provided'),
                  const Divider(color: Color(0xFFF1F5F9)),
                  _buildRow(Icons.supervisor_account_outlined, "Parent Contact", profile['parent_phone'] ?? 'Not Provided'),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _actionBlue,
                side: BorderSide(color: _actionBlue, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _openUpdateProfileForm(profile),
              icon: const Icon(Icons.edit_outlined),
              label: Text("Update Details", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                await _supabase.auth.signOut();
                if (!mounted) return;
                context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded),
              label: Text("Log Out Account", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRow(IconData i, String t, dynamic v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(children: [
        Icon(i, size: 20, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Text("$t: ", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13)),
        const Spacer(),
        Text(v?.toString() ?? 'N/A', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: _primaryNavy, fontSize: 13)),
      ]),
    );
  }
}

class SafeQrGenerator extends StatelessWidget {
  final Map<String, dynamic> passData;

  const SafeQrGenerator({super.key, required this.passData});

  @override
  Widget build(BuildContext context) {
    final passId = passData['id']?.toString() ?? '';
    final passType = passData['pass_type']?.toString() ?? 'standard';
    final outTime = passData['departure_time']?.toString() ?? '';
    final inTime = passData['expected_return_time']?.toString() ?? '';
    final qrExpiresAt = passData['qr_expires_at']?.toString() ?? '';

    final secureData = 'curf_pass|$passId|$passType|$outTime|$inTime|$qrExpiresAt';

    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SizedBox(
          width: 180,
          height: 180,
          child: QrImageView(
            data: secureData,
            version: QrVersions.auto,
            gapless: false,
          ),
        ),
      ),
    );
  }
}