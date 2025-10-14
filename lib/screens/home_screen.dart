import 'package:carelink_app/screens/add_shelter_screen.dart';
import 'package:carelink_app/screens/shelter_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shelter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('케어링크 대시보드'),
        backgroundColor: const Color(0xFF4A4A4A),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            padding: const EdgeInsets.all(8.0),
            itemCount: shelters.length,
            itemBuilder: (context, index) {
              final shelter = shelters[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
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
                  trailing: Icon(
                    Icons.circle,
                    color: shelter.status == '운영중' ? Colors.green : Colors.red,
                    size: 12,
                  ),
                  onTap: () {
                    // --- 바로 이 부분입니다! ---
                    // 탭하면 Navigator를 사용해 ShelterDetailScreen으로 이동합니다.
                    // shelter 객체를 파라미터로 넘겨주어, 상세 화면에서
                    // 어떤 보호소의 정보를 보여줄지 알려줍니다.
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