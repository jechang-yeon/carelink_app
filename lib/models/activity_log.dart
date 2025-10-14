import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLog {
  final String id;
  final String message;
  final String userEmail; // 활동을 수행한 사용자 이메일
  final Timestamp timestamp;

  ActivityLog({
    required this.id,
    required this.message,
    required this.userEmail,
    required this.timestamp,
  });

  factory ActivityLog.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ActivityLog(
      id: doc.id,
      message: data['message'] ?? '내용 없음',
      userEmail: data['userEmail'] ?? '알 수 없음', // userEmail 필드 추가
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}