import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _regNoController = TextEditingController();
  final _roomDetailsController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentPhoneController = TextEditingController();

  String _selectedRole = 'student';
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  String? _uploadedProfilePhotoUrl;

  Future<void> _handleRegistration() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final regNo = _regNoController.text.trim();
    final roomDetails = _roomDetailsController.text.trim();
    final phone = _phoneController.text.trim();
    final parentPhone = _parentPhoneController.text.trim();

    // 1. Mandatory Field Presence Check
    if (name.isEmpty || email.isEmpty || password.isEmpty || regNo.isEmpty || phone.isEmpty) {
      _showSnackBar("All fields, including Phone and Reg No, are mandatory.", Colors.orange);
      return;
    }

    // 2. Exact 10-Digit Phone Number Validation Check
    final RegExp phoneRegExp = RegExp(r'^[0-9]{10}$');
    if (!phoneRegExp.hasMatch(phone)) {
      _showSnackBar("Student Phone Number must be exactly 10 digits.", Colors.orange);
      return;
    }

    if (_selectedRole == 'student') {
      if (roomDetails.isEmpty || parentPhone.isEmpty) {
        _showSnackBar("Room Details and Parent's Phone are mandatory for students.", Colors.orange);
        return;
      }

      if (!phoneRegExp.hasMatch(parentPhone)) {
        _showSnackBar("Parent Phone Number must be exactly 10 digits.", Colors.orange);
        return;
      }

      if (_uploadedProfilePhotoUrl == null) {
        _showSnackBar("❌ Biometric Face Enrollment is mandatory for Students!", Colors.red);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // 3. Unique Registration Number Pre-Check
      if (_selectedRole != 'parent') {
        final existingUser = await _supabase
            .from('users')
            .select('id')
            .eq('registration_number', regNo)
            .maybeSingle();

        if (existingUser != null) {
          throw "Registration Number '$regNo' already exists in the system! Please check and try again.";
        }
      }

      String? linkedStudentUuid;

      if (_selectedRole == 'parent') {
        final List<dynamic> studentLookup = await _supabase
            .from('users')
            .select('id')
            .eq('registration_number', regNo)
            .eq('role', 'student')
            .limit(1);

        if (studentLookup.isEmpty) {
          throw "No student found with Registration Number: $regNo. Let the student register first.";
        }
        linkedStudentUuid = studentLookup.first['id'].toString();
      }

      // 4. Create Authentication Credentials in Supabase Auth
      final authResponse = await _supabase.auth.signUp(email: email, password: password);
      if (authResponse.user == null) throw "Authentication service execution failed.";

      final Map<String, dynamic> userPayload = {
        'auth_user_id': authResponse.user!.id,
        'full_name': name,
        'email': email,
        'phone': phone,
        'role': _selectedRole,
        'registration_number': regNo,
        'verified': false,
      };

      if (_selectedRole == 'student') {
        userPayload['room_details'] = roomDetails;
        userPayload['parent_phone'] = parentPhone;
        userPayload['profile_photo_url'] = _uploadedProfilePhotoUrl;
      } else if (_selectedRole == 'parent' && linkedStudentUuid != null) {
        userPayload['linked_student_id'] = linkedStudentUuid;
      }

      await _supabase.from('users').insert(userPayload);

      if (!mounted) return;
      _showSnackBar("Account registered successfully!", Colors.green);
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _regNoController.dispose();
    _roomDetailsController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1E275D);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: ['student', 'parent', 'warden', 'security']
                  .map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase())))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedRole = val!;
                  _uploadedProfilePhotoUrl = null;
                });
              },
              decoration: _inputDecoration("Account Role Type"),
            ),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: _inputDecoration("Full Name")),
            const SizedBox(height: 16),
            TextField(controller: _emailController, decoration: _inputDecoration("Email Address")),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, obscureText: true, decoration: _inputDecoration("Password")),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: _inputDecoration("Phone Number (10 Digits)").copyWith(counterText: ""),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _regNoController,
              decoration: _inputDecoration(_selectedRole == 'parent' ? "Child's Registration Number" : "Registration Number"),
            ),
            if (_selectedRole == 'student') ...[
              const SizedBox(height: 16),
              TextField(controller: _roomDetailsController, decoration: _inputDecoration("Room Details (e.g. Room A-204)")),
              const SizedBox(height: 16),
              TextField(
                controller: _parentPhoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: _inputDecoration("Parent's Phone Number (10 Digits)").copyWith(counterText: ""),
              ),
              const SizedBox(height: 24),
              MandatoryFaceCaptureField(
                regNoController: _regNoController,
                onPhotoUploaded: (publicUrl) {
                  _uploadedProfilePhotoUrl = publicUrl;
                },
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Complete Registration", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: Colors.white,
  );
}

// =========================================================================
// MANDATORY FACE PROFILE PHOTO FIELD COMPONENT (WEB & MOBILE COMPATIBLE)
// =========================================================================
class MandatoryFaceCaptureField extends StatefulWidget {
  final TextEditingController regNoController;
  final Function(String publicUrl) onPhotoUploaded;

  const MandatoryFaceCaptureField({
    super.key,
    required this.regNoController,
    required this.onPhotoUploaded,
  });

  @override
  State<MandatoryFaceCaptureField> createState() => _MandatoryFaceCaptureFieldState();
}

class _MandatoryFaceCaptureFieldState extends State<MandatoryFaceCaptureField> {
  XFile? _pickedXFile;
  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _pickAndUploadPhoto() async {
    final String regNo = widget.regNoController.text.trim();

    if (regNo.isEmpty) {
      setState(() => _errorMessage = "Please enter your Registration Number first!");
      return;
    }

    setState(() => _errorMessage = null);
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (photo == null) return;

      setState(() {
        _pickedXFile = photo;
        _isUploading = true;
      });

      // READ BYTES CROSS-PLATFORM (Works on Chrome Web and Android/iOS)
      final Uint8List bytes = await photo.readAsBytes();

      final String pathName = 'student_profiles/$regNo.jpg';
      final supabase = Supabase.instance.client;

      // Upload raw binary bytes directly to Supabase 'profiles' storage bucket
      await supabase.storage.from('profiles').uploadBinary(
        pathName,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final String publicUrl = supabase.storage.from('profiles').getPublicUrl(pathName);

      widget.onPhotoUploaded(publicUrl);
      setState(() => _isUploading = false);

    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = "Upload failed: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Biometric Face Profile Photo (Mandatory)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
        ),
        const SizedBox(height: 10),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade200,
                child: _pickedXFile != null
                    ? FutureBuilder<Uint8List>(
                  future: _pickedXFile!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ClipOval(
                        child: Image.memory(
                          snapshot.data!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                )
                    : const Icon(Icons.person, size: 50, color: Colors.grey),
              ),
              if (_isUploading)
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.black45,
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _pickedXFile != null ? Colors.green : const Color(0xFFE67E22),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isUploading ? null : _pickAndUploadPhoto,
            icon: Icon(_pickedXFile != null ? Icons.check_circle : Icons.upload_file),
            label: Text(
              _pickedXFile != null ? "Photo Verified & Uploaded" : "Upload Profile Photo",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}