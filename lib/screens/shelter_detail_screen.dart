import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shelter.dart';
import '../models/animal.dart';
import 'add_animal_screen.dart';

class ShelterDetailScreen extends StatelessWidget {
  final Shelter shelter;

  const ShelterDetailScreen({super.key, required this.shelter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(shelter.name),
        backgroundColor: const Color(0xFFFF7A00),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shelter.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  shelter.address,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '상태: ${shelter.status}',
                  style: TextStyle(
                    fontSize: 16,
                    color: shelter.status == '운영중'
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              '보호중인 동물 목록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            // --- 주요 변경 사항 ---
            // Firestore에서 이 보호소에 속한 동물 목록을 실시간으로 불러옵니다.
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shelters')
                  .doc(shelter.id)
                  .collection('animals')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      '아직 등록된 동물이 없습니다.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                final animals = snapshot.data!.docs
                    .map((doc) => Animal.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final animal = animals[index];
                    return ListTile(
                      leading: const Icon(Icons.pets),
                      title: Text(animal.name),
                      subtitle: Text('${animal.species} / ${animal.gender}'),
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
              builder: (context) => AddAnimalScreen(shelterId: shelter.id),
            ),
          );
        },
        backgroundColor: const Color(0xFFFF7A00),
        tooltip: '신규 동물 등록',
        // --- 코드 스타일 경고 해결 ---
        // child 속성을 마지막으로 이동
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}