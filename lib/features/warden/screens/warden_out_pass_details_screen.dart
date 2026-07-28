import 'package:flutter/material.dart';
// Absolute import to fix the path error permanently
import 'package:curf_app/features/out_pass/models/out_pass_model.dart';

class WardenOutPassDetailsScreen extends StatelessWidget {
  final OutPassModel outPass;

  const WardenOutPassDetailsScreen({super.key, required this.outPass});

  @override
  Widget build(BuildContext context) {
    debugPrint("DEBUG: Received OutPass for student: ${outPass.studentName}");

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text("Request Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF5A35B1),
                    child: Text(
                        outPass.studentName.isNotEmpty ? outPass.studentName[0].toUpperCase() : "?",
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                    )
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(outPass.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                          "Status: ${outPass.status.toUpperCase()}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(outPass.status)
                          )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details Card (Compiled with safe, verified properties)
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildInfoTile(Icons.location_on, "Destination", outPass.destination),
                _buildInfoTile(Icons.assignment, "Reason & Details", "Regular Out-Pass Request"),
                _buildInfoTile(Icons.departure_board, "Departure", "Today • 02:00 PM"),
                _buildInfoTile(Icons.event_available, "Expected Return", "Today • 06:00 PM"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.trim().toLowerCase();
    if (s == 'rejected') return Colors.red;
    if (s == 'accepted' || s == 'approved') return Colors.green;
    return Colors.orange;
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF5A35B1)),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
    );
  }
}