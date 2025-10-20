import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/staff_model.dart'; // UserModel -> StaffModel로 변경

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 현재 로그인한 사용자의 역할 정보를 StaffModel로 가져오는 함수
  Future<StaffModel?> getCurrentUserModel() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    try {
      final userDoc =
      await _firestore.collection('staffs').doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        // Firestore 문서로부터 StaffModel 생성
        return StaffModel.fromFirestore(userDoc);
      } else {
        // staffs 컬렉션에 문서가 없는 비정상적인 경우, 기본 'Viewer' 역할 부여
        return StaffModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '이메일 없음',
          name: '미지정 사용자',
          role: 'Viewer',
        );
      }
    } catch (e) {
      print('사용자 정보 가져오기 오류: $e');
      return null;
    }
  }

  // --- 추가된 함수: 모든 직원 목록을 실시간으로 가져오기 ---
  Stream<List<StaffModel>> getAllStaff() {
    return _firestore.collection('staffs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => StaffModel.fromFirestore(doc)).toList();
    });
  }
}