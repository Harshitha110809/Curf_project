import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;
  final Color _primaryGreen = const Color(0xFF10A37F);
  final _supabase = Supabase.instance.client;
  bool _isSigning = false;

  Future<Map<String, dynamic>> _getParentData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {'requests': [], 'student': {}, 'profile': {}};

    try {
      final parentProfile = await _supabase.from('users').select('*').eq('auth_user_id', user.id).maybeSingle();

      String childId = '';
      Map<String, dynamic> studentData = {};

      if (parentProfile != null && parentProfile['linked_student_id'] != null) {
        childId = parentProfile['linked_student_id'].toString();
        studentData = await _supabase.from('users').select('*').eq('id', childId).maybeSingle() ?? {};
      }

      List<dynamic> passes = [];
      if (childId.isNotEmpty) {
        passes = await _supabase.from('out_pass_requests').select('*').eq('student_id', childId).order('created_at', ascending: false);
      }

      if (passes.isEmpty) {
        passes = await _supabase.from('out_pass_requests').select('*').order('created_at', ascending: false).limit(6);
      }

      return {
        'requests': passes,
        'student': studentData,
        'profile': parentProfile ?? {}
      };
    } catch (e) {
      return {'requests': [], 'student': {}, 'profile': {}};
    }
  }

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
                padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    Text("Update Parent Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryGreen)),
                    const SizedBox(height: 16),
                    TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Full Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 12),
                    TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "Phone Number", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
            }
        );
      },
    );
  }

  // --- UPGRADED: APPROVAL LOGIC WITH 5-MINUTE WARNING MODAL ---
  void _confirmParentAuthorization(String passId, String destination) {
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Confirm Authorization", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("You are about to authorize a Special Curfew bypass for:", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text(destination, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.timer, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          "Once the Warden co-signs this, your ward will only have exactly 5 MINUTES to scan out at the main gate before the pass self-destructs.",
                          style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen),
              onPressed: () {
                Navigator.pop(c);
                _executeSign(passId, 'approved');
              },
              child: const Text("I Understand, Approve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        )
    );
  }

  Future<void> _executeSign(String passId, String statusDecision) async {
    setState(() => _isSigning = true);
    try {
      await _supabase.from('out_pass_requests').update({'parent_approval': statusDecision}).eq('id', passId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pass authorization marked as $statusDecision!"), backgroundColor: _primaryGreen));
      setState(() {});
    } catch (e) {
      debugPrint("Parent signing error: $e");
    } finally {
      if (mounted) setState(() => _isSigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _getParentData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !_isSigning) return const Center(child: CircularProgressIndicator());

            final data = snapshot.data ?? {'requests': [], 'student': {}, 'profile': {}};
            final List<dynamic> requests = data['requests'] ?? [];
            final Map<dynamic, dynamic> student = data['student'] is Map ? data['student'] as Map : {};
            final Map<dynamic, dynamic> profile = data['profile'] is Map ? data['profile'] as Map : {};

            return IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeTab(student, requests),
                _buildHistoryTab(requests),
                _buildAlertsTab(),
                _buildSettingsTab(profile, student),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: _primaryGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(Map<dynamic, dynamic> student, List<dynamic> requests) {
    final studentName = student['full_name']?.toString() ?? 'Rahul Kumar';
    final initials = studentName.isNotEmpty ? studentName.substring(0, 2).toUpperCase() : 'RK';

    final currentMonth = DateTime.now().month;
    final thisMonthCount = requests.where((r) {
      if (r['created_at'] == null) return false;
      return DateTime.parse(r['created_at']).month == currentMonth;
    }).length;

    final specialPendingRequests = requests.where((r) => r['pass_type'] == 'special' && r['parent_approval'] == 'pending').toList();

    // UPGRADED: Using absolute source of truth for Gate Telemetry
    final bool isOut = student['is_out'] == true;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Parent Dashboard", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text("$studentName - ${student['room_details'] ?? 'Block A, Room 204'}", style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _primaryGreen, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Current Status", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Text(isOut ? "⚠️ OUT OF CAMPUS" : "✅ SECURE IN HOSTEL", style: TextStyle(color: isOut ? Colors.orange.shade800 : _primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  CircleAvatar(radius: 26, backgroundColor: Colors.white24, child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(student['room_details']?.toString() ?? "Block A, Room 204", style: const TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(thisMonthCount > 0 ? thisMonthCount.toString() : "0", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text("Passes This Month", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(student['violation_count'] != null && student['violation_count'] > 0 ? Icons.warning_amber_rounded : Icons.check_circle, color: student['violation_count'] != null && student['violation_count'] > 0 ? Colors.red : Colors.green, size: 20),
                        const SizedBox(width: 6),
                        Text(student['violation_count']?.toString() ?? "0", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Text("Curfew Violations", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        if (specialPendingRequests.isNotEmpty) ...[
          const Text("Action Required: Curfew Approvals", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 12),
          ...specialPendingRequests.map((pass) => Card(
            color: const Color(0xFFFFF5F5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFFFD1D1))),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Destination: ${pass['destination']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text("Reason Context: ${pass['reason']}", style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => _executeSign(pass['id'].toString(), 'rejected'), child: const Text("Deny", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 12),
                      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen), onPressed: () => _confirmParentAuthorization(pass['id'].toString(), pass['destination'].toString()), child: const Text("Co-Sign Approve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
                    ],
                  )
                ],
              ),
            ),
          )),
          const SizedBox(height: 16),
        ],

        const Text("All Recent Movements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (requests.isEmpty) ...[
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            margin: const EdgeInsets.only(bottom: 12),
            child: const ListTile(
              title: Text("No pass history recorded.", style: TextStyle(color: Colors.grey)),
            ),
          )
        ],
        ...requests.take(5).map((r) {
          final isSpecial = r['pass_type'] == 'special';
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text("To: ${r['destination']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(isSpecial ? "Special Curfew Request • Parent: ${r['parent_approval']}" : "Standard Out-Pass"),
              trailing: Text(r['status'].toString().toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: (r['status'] == 'approved' || r['status'] == 'exited') ? Colors.green : Colors.orange)),
            ),
          );
        })
      ],
    );
  }

  Widget _buildHistoryTab(List<dynamic> requests) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Full Pass History Logs", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (requests.isEmpty) const Card(child: ListTile(title: Text("No pass history found."))),
        ...requests.map((r) => Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(title: Text(r['destination'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("Final Status: ${r['status'].toString().toUpperCase()}"))
        )).toList()
      ],
    );
  }

  Widget _buildAlertsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text("Safety Alerts", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        Card(child: ListTile(leading: Icon(Icons.info_outline, color: Colors.blue), title: Text("System Infrastructure Sync"), subtitle: Text("Your guardian dashboard is actively receiving tracking metrics from the campus main gate."))),
      ],
    );
  }

  Widget _buildSettingsTab(Map<dynamic, dynamic> profile, Map<dynamic, dynamic> student) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Parent Profile Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryGreen)),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow(Icons.person, "Parent Name", profile['full_name'] ?? 'Not Provided'),
                  const Divider(),
                  _buildRow(Icons.email, "Parent Email", profile['email'] ?? 'Not Provided'),
                  const Divider(),
                  _buildRow(Icons.phone, "Parent Phone", profile['phone'] ?? 'Not Provided'),
                  const SizedBox(height: 16),
                  const Text("LINKED WARD INFO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  _buildRow(Icons.child_care, "Student Name", student['full_name'] ?? 'Not Linked'),
                  const Divider(),
                  _buildRow(Icons.badge, "Reg Number", student['registration_number'] ?? 'N/A'),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: _primaryGreen, side: BorderSide(color: _primaryGreen), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                await _supabase.auth.signOut();
                if (!mounted) return;
                context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text("Log Out Account", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRow(IconData i, String t, dynamic v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(children: [
        Icon(i, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text("$t: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(v?.toString() ?? 'N/A', overflow: TextOverflow.ellipsis))
      ]),
    );
  }
}