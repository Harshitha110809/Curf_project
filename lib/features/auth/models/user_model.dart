class UserModel {
  final String? id;
  final String authUserId;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? registrationNumber;
  final String? roomDetails;
  final bool isVerified;

  UserModel({
    this.id,
    required this.authUserId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.registrationNumber,
    this.roomDetails,
    this.isVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      authUserId: json['auth_user_id'],
      fullName: json['full_name'] ?? 'Unknown User',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'student',
      registrationNumber: json['registration_number'],
      roomDetails: json['room_details'],
      isVerified: json['verified'] ?? false,
    );
  }

  // ADDED THIS: This allows you to save updates to the database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_user_id': authUserId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'registration_number': registrationNumber,
      'room_details': roomDetails,
      'verified': isVerified,
    };
  }
}