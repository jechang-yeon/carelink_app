import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // --- 추가: debugPrint를 사용하기 위한 import ---
import '../models/staff_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<StaffModel?> getCurrentUserModel() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    try {
      final userDoc =
      await _firestore.collection('staffs').doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        return StaffModel.fromFirestore(userDoc);
      } else {
        return StaffModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '이메일 없음',
          name: '미지정 사용자',
          role: 'Viewer',
        );
      }
    } catch (e) {
      // --- 수정: print -> debugPrint ---
      debugPrint('사용자 정보 가져오기 오류: $e');
      return null;
    }
  }

  Stream<List<StaffModel>> getAllStaff() {
    return _firestore.collection('staffs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => StaffModel.fromFirestore(doc)).toList();
    });
  }
}
