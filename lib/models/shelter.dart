import 'package:cloud_firestore/cloud_firestore.dart';

class Shelter {
  final String id;
  final String name;
  final String address;
  final String addressDetail; // 상세 주소
  final double? latitude;      // 위도
  final double? longitude;     // 경도
  final String status;
  final String managerUid;
  final String managerContact;
  final List<String> staffUids;
  final Timestamp createdAt;

  Shelter({
    required this.id,
    required this.name,
    required this.address,
    required this.addressDetail,
    this.latitude,
    this.longitude,
    required this.status,
    required this.managerUid,
    this.managerContact = '',
    required this.staffUids,
    required this.createdAt,
  });

  factory Shelter.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Shelter(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      addressDetail: data['addressDetail'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      status: data['status'] ?? '운영중',
      managerUid: data['managerUid'] ?? '',
      managerContact: data['managerContact'] ?? '',
      staffUids: List<String>.from(data['staffUids'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
