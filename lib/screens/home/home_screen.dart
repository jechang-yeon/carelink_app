import 'package:carelink_app/widgets/dashboard_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/shelter.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../shelter/add_shelter_screen.dart';
import '../shelter/edit_shelter_screen.dart';
import '../shelter/shelter_detail_screen.dart';
import '../logs/activity_log_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _deleteShelter(BuildContext context, Shelter shelter) async {
    try {
      // 참고: 실제 앱에서는 Cloud Functions를 이용해 하위 컬렉션을 삭제해야 합니다.
      await FirebaseFirestore.instance
          .collection('shelters')
          .doc(shelter.id)
          .delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${shelter.name} 보호소 정보가 삭제되었습니다.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('케어링크 대시보드'),
        backgroundColor: const Color(0xFF4A4A4A),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ActivityLogScreen(),
                ),
              );
            },
            tooltip: '전체 활동 기록',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            tooltip: '로그아웃',
          ),
        ],
      ),
      // --- 화면 구조를 Column으로 변경 ---
      body: Column(
        children: [
          // --- 1. 상단에 대시보드 요약 카드 추가 ---
          const DashboardSummaryCard(),

          // --- 2. 하단에 보호소 목록을 Expanded로 감싸서 추가 ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shelters')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      '아직 운영중인 보호소가 없습니다.\n아래 + 버튼을 눌러 새 보호소를 추가하세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                final shelters = snapshot.data!.docs
                    .map((doc) => Shelter.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: shelters.length,
                  itemBuilder: (context, index) {
                    final shelter = shelters[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ListTile(
                        contentPadding:
                        const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        leading: Icon(
                          Icons.home_work_rounded,
                          color: shelter.status == '운영중'
                              ? const Color(0xFFFF7A00)
                              : Colors.grey,
                          size: 40,
                        ),
                        title: Text(
                          shelter.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(shelter.address),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditShelterScreen(shelter: shelter),
                                ),
                              );
                            } else if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (context) => DeleteConfirmationDialog(
                                  title: '보호소 삭제',
                                  content:
                                  '정말로 ${shelter.name} 보호소를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
                                  onConfirm: () =>
                                      _deleteShelter(context, shelter),
                                ),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('수정'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('삭제'),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ShelterDetailScreen(shelter: shelter),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddShelterScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFFFF7A00),
        tooltip: '신규 보호소 개설',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}