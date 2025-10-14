import 'package:cloud_firestore/cloud_firestore.dart';

class Animal {
  final String id;
  final String name;
  final String intakeType; // 입소 유형 (입소/구조)
  final String species; // 종 (개, 고양이 등)
  final String gender; // 성별
  final double weight; // 몸무게
  final bool isNeutered; // 중성화 여부
  final bool isRegistered; // 동물 등록 여부
  final List<String> photoUrls; // 사진 URL 목록
  final String ownerName; // 보호자 이름
  final String ownerContact; // 보호자 연락처
  final String ownerAddress; // 보호자 주소
  final Map<String, bool> consents; // 동의 항목
  final String status; // 동물의 현재 상태 ('보호중', '퇴소' 등)
  final Timestamp createdAt;

  Animal({
    required this.id,
    required this.name,
    required this.intakeType,
    required this.species,
    required this.gender,
    required this.weight,
    required this.isNeutered,
    required this.isRegistered,
    required this.photoUrls,
    required this.ownerName,
    required this.ownerContact,
    required this.ownerAddress,
    required this.consents,
    required this.status,
    required this.createdAt,
  });

  factory Animal.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Animal(
      id: doc.id,
      name: data['name'] ?? '',
      intakeType: data['intakeType'] ?? '입소',
      species: data['species'] ?? '',
      gender: data['gender'] ?? '',
      weight: (data['weight'] ?? 0.0).toDouble(),
      isNeutered: data['isNeutered'] ?? false,
      isRegistered: data['isRegistered'] ?? false,
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      ownerName: data['ownerName'] ?? '',
      ownerContact: data['ownerContact'] ?? '',
      ownerAddress: data['ownerAddress'] ?? '',
      consents: Map<String, bool>.from(data['consents'] ?? {}),
      status: data['status'] ?? '보호중', // Firestore에 status 필드가 없을 경우 기본값을 '보호중'으로 설정
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}