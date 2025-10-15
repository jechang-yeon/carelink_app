import 'package:carelink_app/screens/animal/add_animal_screen.dart';
import 'package:carelink_app/screens/animal/animal_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/shelter.dart';
import '../../models/animal.dart';
import '../../services/map_service.dart';

class ShelterDetailScreen extends StatelessWidget {
  final Shelter shelter;

  const ShelterDetailScreen({super.key, required this.shelter});

  @override
  Widget build(BuildContext context) {
    // 지도 이미지 URL 생성
    final mapUrl = (shelter.latitude != null && shelter.longitude != null)
        ? MapService.getStaticMapUrl(
      latitude: shelter.latitude!,
      longitude: shelter.longitude!,
    )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(shelter.name),
        backgroundColor: const Color(0xFFFF7A00),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 지도 표시 UI 추가 ---
          if (mapUrl != null)
            Image.network(
              mapUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 250,
                color: Colors.grey[200],
                child: const Center(child: Text('지도를 불러올 수 없습니다.')),
              ),
            )
          else
            Container(
              height: 250,
              color: Colors.grey[200],
              child: const Center(child: Text('위치 정보가 없습니다.')),
            ),

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
                  '${shelter.address} ${shelter.addressDetail}',
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
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AnimalDetailScreen(
                              shelterId: shelter.id,
                              animal: animal,
                            ),
                          ),
                        );
                      },
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
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}