import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'qr_scanner_screen.dart';

class GateSecurityDashboard extends StatefulWidget {
  const GateSecurityDashboard({super.key});

  @override
  State<GateSecurityDashboard> createState() => _GateSecurityDashboardState();
}

class _GateSecurityDashboardState extends State<GateSecurityDashboard> {
  int _selectedIndex = 0;
  final _supabase = Supabase.instance.client;
  final Color _securityOrange = const Color(0xFFE67E22);

  // UPDATED: Now fetches BOTH pending exits and active outings so they don't vanish!
  Future<Map<String, dynamic>> _getSecurityData() async {
    try {
      final user = _supabase.auth.currentUser;
      final res = await _supabase
          .from('out_pass_requests')
          .select('*, student:users!out_pass_requests_student_id_fkey(*)')
          .inFilter('status', ['approved', 'exited']); // <--- THE FIX IS HERE

      dynamic profileResponse = {};
      if (user != null) {
        profileResponse = await _supabase.from('users').select('*').eq('auth_user_id', user.id).maybeSingle() ?? {};
      }

      return {
        'passes': List<dynamic>.from(res as Iterable),
        'profile': profileResponse
      };
    } catch (e) {
      return {'passes': [], 'profile': {}};
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
                    Text("Update Security Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _securityOrange)),
                    const SizedBox(height: 16),
                    TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Officer Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 12),
                    TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "Phone Number", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _securityOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  void _showScanDetails(Map<dynamic, dynamic> pass) {
    final student = pass['student'] is Map ? pass['student'] as Map : {};
    final isSpecial = pass['pass_type'] == 'special';
    final isAlreadyOut = pass['status'] == 'exited';

    String expectedReturnStr = "Standard Curfew";
    if (pass['expected_return_time'] != null) {
      expectedReturnStr = DateFormat('MMM dd, hh:mm a').format(DateTime.parse(pass['expected_return_time']));
    }

    final String? photoUrl = student['profile_photo_url'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Student Clearance Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _securityOrange)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: isAlreadyOut ? Colors.orange.shade100 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(isAlreadyOut ? "OUT ON CAMPUS" : "WAITING FOR EXIT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isAlreadyOut ? Colors.orange.shade800 : Colors.green.shade800)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: isSpecial ? Colors.purple.shade50 : Colors.blue.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSpecial ? Colors.purple.shade200 : Colors.blue.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: _securityOrange.withOpacity(0.2),
                                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                                child: (photoUrl == null || photoUrl.isEmpty) ? Icon(Icons.person, color: _securityOrange, size: 30) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(student['full_name']?.toString() ?? 'Unknown Identity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text("Reg No: ${student['registration_number'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text("Room Assigned: ${student['room_details'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade800)),
                          Text("Student Contact: ${student['phone'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade800)),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text("Destination Clearance: ${pass['destination']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Must Return By: $expectedReturnStr", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // REMOVED THE MANUAL BUTTONS. GUARD MUST USE SCANNER NOW.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, color: Colors.grey),
                        SizedBox(width: 8),
                        Text("Use the Scanner to log Entry/Exit", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _getSecurityData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data ?? {'passes': [], 'profile': {}};

            return IndexedStack(
              index: _selectedIndex,
              children: [
                _buildMainControlTab(data['passes'] ?? []),
                _buildSettingsTab(data['profile'] ?? {}),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: _securityOrange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Gate Control'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildMainControlTab(List<dynamic> passes) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QRScannerScreen()),
            ).then((_) => setState((){})); // Refresh list when returning from scanner
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _securityOrange, borderRadius: BorderRadius.circular(16)),
            child: const Column(
                children: [
                  Icon(Icons.qr_code_scanner, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text("Tap to Scan Student QR Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                ]
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text("Live Gate Monitor", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 12),
        if (passes.isEmpty) ...[
          const Card(child: ListTile(title: Text("System Clear"), subtitle: Text("No students currently active.")))
        ],
        ...passes.map((p) {
          final student = p['student'] is Map ? p['student'] as Map : {};
          final isAlreadyOut = p['status'] == 'exited';
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(
              onTap: () => _showScanDetails(p),
              leading: Icon(
                  isAlreadyOut ? Icons.directions_walk : Icons.timer,
                  color: isAlreadyOut ? Colors.orange : Colors.green
              ),
              title: Text(student['full_name']?.toString() ?? 'Student Check', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(isAlreadyOut ? "Currently Out (Tap for Details)" : "Pending Exit (Tap for Details)"),
            ),
          );
        })
      ],
    );
  }

  Widget _buildSettingsTab(Map<dynamic, dynamic> profile) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Security Checkpoint Portal", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _securityOrange)),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildRow(Icons.person, "Officer Name", profile['full_name'] ?? 'Gate Point Officer'),
                  const Divider(),
                  _buildRow(Icons.email, "Officer Email", profile['email'] ?? 'N/A'),
                  const Divider(),
                  _buildRow(Icons.phone, "Gate Phone", profile['phone'] ?? 'N/A'),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: _securityOrange, side: BorderSide(color: _securityOrange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
              label: const Text("Log Out Subsystem", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRow(IconData i, String t, dynamic v) => Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [Icon(i, size: 20, color: Colors.grey), const SizedBox(width: 12), Text("$t: ", style: const TextStyle(fontWeight: FontWeight.bold)), Text(v?.toString() ?? 'N/A')]));
}