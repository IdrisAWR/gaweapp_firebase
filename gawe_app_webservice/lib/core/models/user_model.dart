// lib/core/models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'job_seeker' atau 'company'
  final String? phoneNumber;
  final String? companyId; // Khusus untuk company

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.companyId,
  });

  // Mengubah data dari Firestore (Map) ke object Dart
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'job_seeker',
      phoneNumber: data['phone_number'],
      companyId: data['company_id'],
    );
  }

  // Mengubah object Dart ke format Firestore (Map)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'phone_number': phoneNumber,
      'company_id': companyId,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}