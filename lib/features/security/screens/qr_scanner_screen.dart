import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;

  Future<void> _verifyPassLocallyAndLog(String rawData) async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    try {
      final parts = rawData.split('|');
      if (parts.length < 6 || parts[0] != 'curf_pass') {
        _showErrorPopup("❌ Invalid or Unrecognized QR Code format.");
        return;
      }

      final passId = parts[1];
      final passType = parts[2];
      final outTimeStr = parts[3];
      final inTimeStr = parts[4];
      final qrExpiresAtStr = parts[5];

      // 1. Fetch current pass status (SIMPLE QUERY)
      final passResponse = await Supabase.instance.client
          .from('out_pass_requests')
          .select('status, student_id')
          .eq('id', passId)
          .maybeSingle();

      if (passResponse == null) {
        _showErrorPopup("❌ Pass record completely missing from database.");
        return;
      }

      final status = passResponse['status'];
      final studentId = passResponse['student_id'];

      // 2. Fetch the student profile explicitly (GUARANTEES PHOTO IS FETCHED)
      final studentResponse = await Supabase.instance.client
          .from('users')
          .select('full_name, registration_number, profile_photo_url, room_details')
          .eq('id', studentId)
          .maybeSingle();

      final studentData = studentResponse ?? {};
      final DateTime currentTime = DateTime.now();

      // IF ALREADY COMPLETED
      if (status == 'completed') {
        _showErrorPopup("❌ Pass Expired. This pass has already been used for a full round trip.");
        return;
      }

      // IF STUDENT IS EXITING CAMPUS
      if (status == 'approved') {
        if (outTimeStr.isNotEmpty) {
          final outTime = DateTime.parse(outTimeStr).toLocal();
          if (currentTime.isBefore(outTime)) {
            _showErrorPopup("❌ Too Early: Pass not active until ${DateFormat('hh:mm a').format(outTime)}");
            return;
          }
        }
        if (passType == 'special' && qrExpiresAtStr.isNotEmpty) {
          final outTime = DateTime.parse(outTimeStr).toLocal();
          final expiresAt = outTime.add(const Duration(minutes: 5));
          if (currentTime.isAfter(expiresAt)) {
            _showErrorPopup("❌ Expired: 5-minute special pass window has lapsed.");
            return;
          }
        }

        // Passed rules - Show Action Modal for EXIT
        _showActionModal(true, "Student is verified for EXIT.", passId, studentId, studentData, true);
        return;
      }

      // IF STUDENT IS ENTERING CAMPUS (RETURNING)
      if (status == 'exited') {
        if (inTimeStr.isNotEmpty) {
          final inTime = DateTime.parse(inTimeStr).toLocal();
          if (currentTime.isAfter(inTime)) {
            // They are late, but we still have to let them in! Just note it.
            _showActionModal(false, "⚠️ LATE RETURN: Curfew was breached.", passId, studentId, studentData, false);
            return;
          }
        }
        // Show Action Modal for ENTRY
        _showActionModal(true, "Student is verified for ENTRY.", passId, studentId, studentData, false);
        return;
      }

      _showErrorPopup("❌ Invalid Pass Status: $status");

    } catch (e) {
      _showErrorPopup("⚠️ Security Verification Error: $e");
    }
  }

  void _showErrorPopup(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))));
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => isProcessing = false);
    });
  }

  Future<void> _processGateAction(String passId, String studentId, bool isExit) async {
    try {
      final action = isExit ? 'exit' : 'entry';
      final newPassStatus = isExit ? 'exited' : 'completed';

      await Supabase.instance.client.from('entry_exit_logs').insert({
        'student_id': studentId,
        'out_pass_id': passId,
        'action_type': action
      });

      await Supabase.instance.client.from('users').update({
        'is_out': isExit
      }).eq('id', studentId);

      await Supabase.instance.client.from('out_pass_requests').update({
        'status': newPassStatus
      }).eq('id', passId);

      if (mounted) {
        Navigator.pop(context); // Close Modal
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.green, content: Text("Gate $action logged successfully.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Database Error: $e")));
      }
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  // DYNAMIC MODAL - Shows Photo and creates the Log Entry / Log Exit button
  void _showActionModal(bool isGoodStanding, String message, String passId, String studentId, Map<dynamic, dynamic> student, bool isExit) {
    if (!mounted) return;

    // Grabbing the explicit photo URL from the simplified query
    final String? photoUrl = student['profile_photo_url'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isGoodStanding ? (isExit ? Colors.orange : Colors.blue) : Colors.red, width: 3)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isExit ? "GATE EXIT" : "GATE ENTRY", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isExit ? Colors.orange.shade800 : Colors.blue.shade800)),
            const SizedBox(height: 16),

            // Giant Profile Picture
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
              child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, size: 70, color: Colors.grey) : null,
            ),
            const SizedBox(height: 16),

            Text(student['full_name']?.toString() ?? 'Unknown Student', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text("Reg: ${student['registration_number'] ?? 'N/A'}", style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text("Room: ${student['room_details'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),

            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isGoodStanding ? Colors.green.shade800 : Colors.red.shade800)),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(c);
                    setState(() => isProcessing = false);
                  },
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: isExit ? Colors.orange : Colors.blue, foregroundColor: Colors.white),
                  onPressed: () => _processGateAction(passId, studentId, isExit),
                  child: Text(isExit ? "LOG EXIT" : "LOG ENTRY", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Gate Scanner'),
        backgroundColor: const Color(0xFFE67E22),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? rawData = barcode.rawValue;
                if (rawData != null && rawData.startsWith('curf_pass|')) {
                  _verifyPassLocallyAndLog(rawData);
                }
              }
            },
          ),
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}