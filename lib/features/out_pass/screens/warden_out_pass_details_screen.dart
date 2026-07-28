import 'package:flutter/material.dart';
// Absolute import ensures the model is found perfectly without path errors
import 'package:curf_app/features/out_pass/models/out_pass_model.dart';

class WardenOutPassDetailsScreen extends StatelessWidget {
  final OutPassModel outPass;
  const WardenOutPassDetailsScreen({super.key, required this.outPass});

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.orange;
    if (outPass.status.toLowerCase() == 'approved' || outPass.status.toLowerCase() == 'accepted') {
      statusColor = Colors.green;
    } else if (outPass.status.toLowerCase() == 'rejected') {
      statusColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: const Text("Request Details", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2B3674),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Profile Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF2B3674).withOpacity(0.1),
                        radius: 24,
                        child: Text(
                          outPass.studentName.isNotEmpty ? outPass.studentName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              outPass.studentName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
                            ),
                            const SizedBox(height: 4),
                            const Text("Hostel Resident", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Destination Details
                  const Text("DESTINATION", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(outPass.destination, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),

                  // Status Badge
                  const Text("CURRENT STATUS", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      outPass.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons for the Warden
          if (outPass.status.toLowerCase() == 'pending')
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Reject", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Approve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}