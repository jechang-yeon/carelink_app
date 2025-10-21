import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    // main.dart에 정의된 CardTheme을 자동으로 적용받음
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '전체 현황 요약',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream:
              FirebaseFirestore.instance.collectionGroup('animals').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: CircularProgressIndicator(),
                      ));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text('보호중인 동물이 없습니다.'),
                      ));
                }

                final animals = snapshot.data!.docs;
                final totalAnimals = animals.length;
                final dogs =
                    animals.where((doc) => doc['species'] == '개').length;
                final cats =
                    animals.where((doc) => doc['species'] == '고양이').length;
                final others = totalAnimals - dogs - cats;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.inventory_2_outlined,
                      label: '전체',
                      count: totalAnimals,
                    ),
                    _buildStatItem(
                      icon: Icons.pets_outlined,
                      label: '개',
                      count: dogs,
                    ),
                    _buildStatItem(
                      icon: Icons.sentiment_very_satisfied_outlined,
                      label: '고양이',
                      count: cats,
                    ),
                    _buildStatItem(
                      icon: Icons.favorite_border,
                      label: '기타',
                      count: others,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 통계 항목 UI를 만드는 헬퍼 위젯
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4A4A4A), size: 28),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8A8A8E),
          ),
        ),
      ],
    );
  }
}