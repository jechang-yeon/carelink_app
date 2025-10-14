import 'package:cloud_firestore/cloud_firestore.dart';

class CareLog {
  final String id;
  final Timestamp date; // 기록 날짜
  final String amMeal; // 오전 배식
  final String pmMeal; // 오후 배식
  final String water; // 급수
  final String exercise; // 운동
  final String recordedBy; // 기록한 직원 ID (나중에 추가)

  CareLog({
    required this.id,
    required this.date,
    required this.amMeal,
    required this.pmMeal,
    required this.water,
    required this.exercise,
    required this.recordedBy,
  });

  factory CareLog.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CareLog(
      id: doc.id,
      date: data['date'] ?? Timestamp.now(),
      amMeal: data['amMeal'] ?? '',
      pmMeal: data['pmMeal'] ?? '',
      water: data['water'] ?? '',
      exercise: data['exercise'] ?? '',
      recordedBy: data['recordedBy'] ?? '',
    );
  }
}