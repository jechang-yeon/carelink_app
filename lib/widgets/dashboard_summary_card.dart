import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '전체 현황',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            // collectionGroup을 사용하여 모든 보호소의 'animals' 하위 컬렉션을 한번에 가져옵니다.
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collectionGroup('animals').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('보호중인 동물이 없습니다.'));
                }

                // 데이터 분석
                final animals = snapshot.data!.docs;
                final totalAnimals = animals.length;
                final dogs = animals.where((doc) => doc['species'] == '개').length;
                final cats = animals.where((doc) => doc['species'] == '고양이').length;
                final others = totalAnimals - dogs - cats;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.pets,
                      label: '전체 동물',
                      count: totalAnimals,
                      color: const Color(0xFFFF7A00),
                    ),
                    _buildStatItem(
                      icon: Icons.cruelty_free, // 강아지 아이콘 대용
                      label: '개',
                      count: dogs,
                      color: Colors.blueGrey,
                    ),
                    _buildStatItem(
                      icon: Icons.catching_pokemon, // 고양이 아이콘 대용
                      label: '고양이',
                      count: cats,
                      color: Colors.teal,
                    ),
                    _buildStatItem(
                      icon: Icons.more_horiz,
                      label: '기타',
                      count: others,
                      color: Colors.grey,
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
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}