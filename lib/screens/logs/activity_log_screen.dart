import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/activity_log.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전체 활동 기록'),
        backgroundColor: const Color(0xFF4A4A4A),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activityLogs')
            .orderBy('timestamp', descending: true)
            .limit(100) // 최근 100개 기록만 표시
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                '활동 기록이 없습니다.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final logs = snapshot.data!.docs
              .map((doc) => ActivityLog.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss')
                  .format(log.timestamp.toDate());

              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(log.message),
                // --- 수정된 부분 ---
                // 부제목(subtitle)에 날짜와 함께 담당자 이메일(userEmail)을 표시합니다.
                subtitle: Text('$formattedDate by ${log.userEmail}'),
              );
            },
          );
        },
      ),
    );
  }
}