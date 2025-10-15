import 'package:cloud_firestore/cloud_firestore.dart';

class Animal {
  final String id;
  final String name;
  final String intakeType;
  final String species;
  final String gender;
  final double weight;
  final bool isNeutered;
  final bool isRegistered;
  final List<String> photoUrls;
  final String ownerName;
  final String ownerContact;
  final String ownerAddress;
  final String ownerAddressDetail; // 보호자 상세 주소
  final Map<String, bool> consents;
  final String status;
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
    required this.ownerAddressDetail,
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
      ownerAddressDetail: data['ownerAddressDetail'] ?? '',
      consents: Map<String, bool>.from(data['consents'] ?? {}),
      status: data['status'] ?? '보호중',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}