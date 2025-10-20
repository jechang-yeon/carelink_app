import 'package:cloud_firestore/cloud_firestore.dart';

class StaffModel {
  final String uid;
  final String email;
  final String name;
  final String role;

  StaffModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  factory StaffModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StaffModel(
      uid: doc.id,
      email: data['email'] ?? '이메일 없음',
      name: data['name'] ?? '이름 없음',
      role: data['role'] ?? 'Viewer', // 역할 정보가 없으면 기본값 'Viewer'
    );
  }
}