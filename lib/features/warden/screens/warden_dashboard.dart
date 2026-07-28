import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({super.key});

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  int _selectedIndex = 0;
  String _selectedFilter = 'all';
  final Color _primaryBlue = const Color(0xFF1E275D);
  final _supabase = Supabase.instance.client;
  bool _isProcessing = false;

  // ---------------------------------------------------------------------------
  // REAL-TIME DATABASE STREAMS
  // ---------------------------------------------------------------------------
  Stream<List<Map<String, dynamic>>> _getRequestsStream() {
    return _supabase
        .from('out_pass_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> _getStudentsStream() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('role', 'student')
        .order('full_name', ascending: true);
  }

  Future<Map<String, dynamic>> _getWardenProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('auth_user_id', user.id)
          .maybeSingle();
      return response ?? {};
    } catch (e) {
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // DETAILED STUDENT INSPECTION MODAL
  // ---------------------------------------------------------------------------
  void _showStudentDetailsModal(Map<dynamic, dynamic> student) {
    final String studentId = student['id']?.toString() ?? '';
    final int violationCount = student['violation_count'] ?? 0;
    final String? profilePhotoUrl = student['profile_photo_url'];
    final bool isOut = student['is_out'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
                              ? NetworkImage(profilePhotoUrl)
                              : null,
                          child: (profilePhotoUrl == null || profilePhotoUrl.isEmpty)
                              ? Icon(Icons.person, size: 50, color: _primaryBlue)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          student['full_name']?.toString() ?? 'N/A',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _primaryBlue,
                          ),
                        ),
                        Text(
                          "Reg No: ${student['registration_number']?.toString() ?? 'N/A'}",
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        if (isOut) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                            child: Text("⚠️ CURRENTLY OFF-CAMPUS", style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Violation Badge
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: violationCount >= 5 ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: violationCount >= 5 ? Colors.red.shade300 : Colors.green.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          violationCount >= 5 ? Icons.warning_amber_rounded : Icons.verified_user,
                          color: violationCount >= 5 ? Colors.red.shade800 : Colors.green.shade800,
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Curfew Violations: $violationCount",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: violationCount >= 5 ? Colors.red.shade900 : Colors.green.shade900,
                                ),
                              ),
                              Text(
                                violationCount >= 5
                                    ? "⚠️ Critical Risk: Exceeds 5 violation limit!"
                                    : "Good standing",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: violationCount >= 5 ? Colors.red.shade700 : Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Complete Info Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.meeting_room, "Room Details", student['room_details']),
                          const Divider(),
                          _buildDetailRow(Icons.phone, "Student Contact", student['phone']),
                          const Divider(),
                          _buildDetailRow(Icons.supervisor_account, "Parent Contact", student['parent_phone']),
                          const Divider(),
                          _buildDetailRow(Icons.email, "Email Address", student['email']),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Student's Personal Out-Pass History
                  Text(
                    "Student Pass History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryBlue),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<dynamic>>(
                    future: _supabase
                        .from('out_pass_requests')
                        .select('*')
                        .eq('student_id', studentId)
                        .order('created_at', ascending: false),
                    builder: (context, historySnapshot) {
                      if (historySnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final passes = historySnapshot.data ?? [];
                      if (passes.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text("No pass history found for this student.", style: TextStyle(color: Colors.grey)),
                        );
                      }
                      return Column(
                        children: passes.map((p) {
                          final isApproved = p['status'] == 'approved' || p['status'] == 'exited' || p['status'] == 'completed';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text("To: ${p['destination'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Type: ${p['pass_type']?.toString().toUpperCase()}"),
                              trailing: Text(
                                p['status']?.toString().toUpperCase() ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isApproved ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // PROFILE UPDATE FORM FOR WARDEN
  // ---------------------------------------------------------------------------
  void _openUpdateProfileForm(Map<dynamic, dynamic> currentProfile) {
    final nameCtrl = TextEditingController(text: currentProfile['full_name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: currentProfile['phone']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text("Update Warden Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryBlue)),
                  const SizedBox(height: 16),
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Full Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "Phone Number", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: isSaving ? null : () async {
                        setModalState(() => isSaving = true);
                        try {
                          await _supabase.from('users').update({
                            'full_name': nameCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                          }).eq('id', currentProfile['id']);
                          if (mounted) {
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green));
                            setState(() {});
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating: $e"), backgroundColor: Colors.red));
                        } finally {
                          setModalState(() => isSaving = false);
                        }
                      },
                      child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updatePassStatus(String id, String status) async {
    setState(() => _isProcessing = true);
    try {
      await _supabase.from('out_pass_requests').update({'status': status}).eq('id', id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pass verification updated to $status"), backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint("Warden update failed: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // UPDATED: Now strictly filters the students stream for people marked is_out == true
  List<dynamic> _getOutNow(List<dynamic> students) =>
      students.where((s) => s['is_out'] == true).toList();

  List<dynamic> _getLateReturns(List<dynamic> requests) {
    final now = DateTime.now();
    return requests.where((r) {
      if (r['status'] != 'exited') return false; // Only check people who actually left
      if (r['expected_return_time'] == null) return false;
      return now.isAfter(DateTime.parse(r['expected_return_time']));
    }).toList();
  }

  // UPDATED: Handles displaying generic lists whether it's Student Data or Request Data
  void _showFilteredList(String title, List<dynamic> listData, Color accentColor, {bool isStudentList = false}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text("$title (${listData.length})", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accentColor)),
              const SizedBox(height: 16),
              if (listData.isEmpty) const Text("No records available currently.", style: TextStyle(color: Colors.grey)),
              Expanded(
                child: ListView.builder(
                  itemCount: listData.length,
                  itemBuilder: (context, index) {
                    final item = listData[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.person, color: accentColor),
                        title: Text(
                            isStudentList
                                ? (item['full_name'] ?? 'Unknown Student')
                                : "Pass Destination: ${item['destination']}",
                            style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                        subtitle: Text(
                            isStudentList
                                ? "Room: ${item['room_details'] ?? 'N/A'}"
                                : "Status: ${item['status']}"
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _getWardenProfile(),
          builder: (context, profileSnapshot) {
            final wardenProfile = profileSnapshot.data ?? {};

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getRequestsStream(),
              builder: (context, requestsSnapshot) {
                final requests = requestsSnapshot.data ?? [];

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getStudentsStream(),
                  builder: (context, studentsSnapshot) {
                    final students = studentsSnapshot.data ?? [];

                    return IndexedStack(
                      index: _selectedIndex,
                      children: [
                        _buildAnalysisHomeTab(requests, students), // Passing both now
                        _buildRequestsManagerTab(requests),
                        _buildAlertsTab(students),
                        _buildStudentsDirectoryTab(students),
                        _buildSettingsTab(wardenProfile),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: _primaryBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: ANALYTICS & HOME DASHBOARD
  // ---------------------------------------------------------------------------
  Widget _buildAnalysisHomeTab(List<dynamic> requests, List<dynamic> students) {
    final pendingCount = requests.where((r) => r['status'] == 'pending').length;
    final todayCount = requests.where((r) {
      if (r['created_at'] == null) return false;
      return DateTime.parse(r['created_at']).day == DateTime.now().day;
    }).length;

    // Using the new explicit is_out boolean for absolute accuracy
    final outNowList = _getOutNow(students);
    final lateList = _getLateReturns(requests);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text("Warden Dashboard", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _primaryBlue)),
        const Text("Real-Time Infrastructure Desk", style: TextStyle(color: Colors.grey, fontSize: 15)),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.3,
          children: [
            _buildInteractiveCard(pendingCount.toString(), "Pending", Icons.access_time, Colors.orange, null),
            _buildInteractiveCard(outNowList.length.toString(), "Out Now", Icons.people_outline, Colors.blue, () => _showFilteredList("Students Out Now", outNowList, Colors.blue, isStudentList: true)),
            _buildInteractiveCard(lateList.length.toString(), "Late Returns", Icons.warning_amber_rounded, Colors.red, () => _showFilteredList("Late Return Violators", lateList, Colors.red)),
            _buildInteractiveCard(todayCount.toString(), "Passes Today", Icons.check_circle_outline, Colors.green, null),
          ],
        ),
        const SizedBox(height: 28),
        Text("Live Activity Feed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryBlue)),
        const SizedBox(height: 16),
        if (requests.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("No activity recorded yet.", style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...requests.take(5).map((req) {
            final isSpecial = req['pass_type'] == 'special';
            return Card(
              child: ListTile(
                title: Text("Destination: ${req['destination'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(isSpecial ? "Special Curfew Pass (Parent: ${req['parent_approval']})" : "Standard Out-Pass"),
                trailing: Text(
                  req['status'].toString().toUpperCase(),
                  style: TextStyle(
                    color: req['status'] == 'approved' ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          })
      ],
    );
  }

  Widget _buildInteractiveCard(String val, String label, IconData icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10))
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: REQUESTS MANAGER
  // ---------------------------------------------------------------------------
  Widget _buildRequestsManagerTab(List<dynamic> allRequests) {
    final filters = ['all', 'pending', 'approved', 'rejected', 'special'];
    List<dynamic> filtered = allRequests;
    if (_selectedFilter != 'all') {
      filtered = _selectedFilter == 'special'
          ? allRequests.where((r) => r['pass_type'] == 'special').toList()
          : allRequests.where((r) => r['status'] == _selectedFilter).toList();
    }

    return Column(
      children: [
        Container(
          height: 50,
          margin: const EdgeInsets.only(top: 10),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: filters.map((f) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(f.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                selected: _selectedFilter == f,
                onSelected: (v) => setState(() => _selectedFilter = f),
              ),
            )).toList(),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text("No pass requests found for this filter.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
            itemCount: filtered.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final req = filtered[index];
              final isSpecial = req['pass_type'] == 'special';
              final isParentApproved = req['parent_approval'] == 'approved';

              return Card(
                color: isSpecial ? const Color(0xFFF9F6FF) : Colors.white,
                child: ListTile(
                  title: Text("Destination: ${req['destination'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Type: ${isSpecial ? 'CURFEW BYPASS' : 'STANDARD'}\nParent Signature: ${req['parent_approval'].toString().toUpperCase()}"),
                  isThreeLine: true,
                  trailing: req['status'] == 'pending'
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: (isSpecial && !isParentApproved) ? Colors.grey : Colors.green),
                        onPressed: (isSpecial && !isParentApproved)
                            ? () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("Cannot approve. Waiting for parent co-signature authorization."),
                            backgroundColor: Colors.orange,
                          ));
                        }
                            : () => _updatePassStatus(req['id'].toString(), 'approved'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _updatePassStatus(req['id'].toString(), 'rejected'),
                      ),
                    ],
                  )
                      : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: req['status'] == 'approved' ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      req['status'].toString().toUpperCase(),
                      style: TextStyle(
                        color: req['status'] == 'approved' ? Colors.green.shade900 : Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: SYSTEM ALERTS & HIGH-RISK VIOLATORS
  // ---------------------------------------------------------------------------
  Widget _buildAlertsTab(List<Map<String, dynamic>> students) {
    final highRiskStudents = students.where((s) => (s['violation_count'] ?? 0) >= 5).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text("High-Risk Violations Radar", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryBlue)),
        const SizedBox(height: 16),
        if (highRiskStudents.isEmpty) ...[
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text("All Clear - No Critical Violators", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              subtitle: Text("No students have breached the 5-violation threshold."),
            ),
          ),
        ] else ...[
          ...highRiskStudents.map((student) => Card(
            color: Colors.red.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade300),
            ),
            child: ListTile(
              onTap: () => _showStudentDetailsModal(student),
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.warning, color: Colors.white),
              ),
              title: Text(student['full_name'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              subtitle: Text("Violations: ${student['violation_count']} | Room: ${student['room_details'] ?? 'N/A'}\nTap to inspect profile details"),
              isThreeLine: true,
            ),
          )),
        ]
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: STUDENTS DIRECTORY (TAP NAME TO VIEW PROFILE & VIOLATIONS)
  // ---------------------------------------------------------------------------
  Widget _buildStudentsDirectoryTab(List<Map<String, dynamic>> students) {
    if (students.isEmpty) {
      return const Center(child: Text("No registered students found.", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final int violationCount = student['violation_count'] ?? 0;
        final String? photoUrl = student['profile_photo_url'];
        final bool isOut = student['is_out'] == true;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () => _showStudentDetailsModal(student),
            leading: CircleAvatar(
              backgroundColor: _primaryBlue,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
              child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, color: Colors.white) : null,
            ),
            title: Text(
              student['full_name']?.toString() ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Reg No: ${student['registration_number'] ?? 'N/A'} | Room: ${student['room_details'] ?? 'N/A'}"),
                if (isOut)
                  const Text("⚠️ Currently Off-Campus", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: violationCount >= 5 ? Colors.red.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$violationCount Violations",
                style: TextStyle(
                  color: violationCount >= 5 ? Colors.red.shade900 : Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 5: WARDEN PROFILE SETTINGS
  // ---------------------------------------------------------------------------
  Widget _buildSettingsTab(Map<dynamic, dynamic> profile) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Warden Profile Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryBlue)),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow(Icons.person_outline, "Warden Name", profile['full_name']),
                  const Divider(),
                  _buildDetailRow(Icons.email_outlined, "Email", profile['email']),
                  const Divider(),
                  _buildDetailRow(Icons.phone_outlined, "Contact Desk", profile['phone']),
                  const Divider(),
                  _buildDetailRow(Icons.assignment_ind_outlined, "System Role", "CHIEF WARDEN - HOSTEL DESK"),
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
                foregroundColor: _primaryBlue,
                side: BorderSide(color: _primaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _openUpdateProfileForm(profile),
              icon: const Icon(Icons.edit),
              label: const Text("Update Details", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await _supabase.auth.signOut();
                if (!mounted) return;
                context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text("Sign Out of Session", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData i, String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(i, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value?.toString() ?? 'Not Provided', textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}