import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
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
                      count: totalAnimals,
                    ),
                    _buildStatItem(
                      icon: Icons.pets_outlined,
                      count: dogs,
                    ),
                    _buildStatItem(
                      icon: Icons.sentiment_very_satisfied_outlined,
                      count: cats,
                    ),
                    _buildStatItem(
                      icon: Icons.favorite_border,
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

  Widget _buildStatItem({
    required IconData icon,
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
      ],
    );
  }
}