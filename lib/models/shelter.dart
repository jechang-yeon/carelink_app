import 'package:cloud_firestore/cloud_firestore.dart';

class Shelter {
  final String id; // 문서 ID
  final String name; // 보호소 이름
  final String address; // 주소
  final String status; // 상태 (운영중, 종료 등)

  Shelter({
    required this.id,
    required this.name,
    required this.address,
    required this.status,
  });

  // Firestore 문서(Map)를 Shelter 객체로 변환하는 팩토리 생성자
  factory Shelter.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Shelter(
      id: doc.id,
      name: data['name'] ?? '이름 없음',
      address: data['address'] ?? '주소 정보 없음',
      status: data['status'] ?? '상태 미지정',
    );
  }
}