import 'package:carelink_app/widgets/delete_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/animal.dart';
import '../models/care_log.dart';
import '../widgets/add_care_log_dialog.dart';
import 'edit_animal_screen.dart';

class AnimalDetailScreen extends StatelessWidget {
  final String shelterId;
  final Animal animal;
  const AnimalDetailScreen(
      {super.key, required this.shelterId, required this.animal});

  Future<void> _deleteAnimal(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('shelters')
          .doc(shelterId)
          .collection('animals')
          .doc(animal.id)
          .delete();
      if (!context.mounted) return;
      Navigator.of(context).pop(); // 상세 화면 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${animal.name} 정보가 삭제되었습니다.')),
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
        title: Text(animal.name),
        backgroundColor: const Color(0xFFFF7A00),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditAnimalScreen(
                    shelterId: shelterId,
                    animal: animal,
                  ),
                ),
              );
            },
            tooltip: '정보 수정',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => DeleteConfirmationDialog(
                  title: '동물 정보 삭제',
                  content:
                  '정말로 ${animal.name}의 정보를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
                  onConfirm: () => _deleteAnimal(context),
                ),
              );
            },
            tooltip: '정보 삭제',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('기본 정보',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildInfoRow('현재 상태', animal.status),
            _buildInfoRow('입소 유형', animal.intakeType),
            _buildInfoRow('이름', animal.name),
            _buildInfoRow('종류', animal.species),
            _buildInfoRow('성별', animal.gender),
            _buildInfoRow('몸무게', '${animal.weight} kg'),
            _buildInfoRow('중성화 여부', animal.isNeutered ? '완료' : '미완료'),
            _buildInfoRow('동물 등록 여부', animal.isRegistered ? '완료' : '미완료'),
            const SizedBox(height: 24),
            const Text('보호자 정보',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildInfoRow('이름', animal.ownerName),
            _buildInfoRow('연락처', animal.ownerContact),
            _buildInfoRow('주소', animal.ownerAddress),
            const SizedBox(height: 24),
            const Text('데일리 케어 기록',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shelters')
                  .doc(shelterId)
                  .collection('animals')
                  .doc(animal.id)
                  .collection('careLogs')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text('아직 케어 기록이 없습니다.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                final careLogs = snapshot.data!.docs
                    .map((doc) => CareLog.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: careLogs.length,
                  itemBuilder: (context, index) {
                    final log = careLogs[index];
                    final formattedDate =
                    DateFormat('yyyy-MM-dd').format(log.date.toDate());
                    return Card(
                      margin: const EdgeInsets.only(top: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formattedDate,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const Divider(),
                            Text('오전 배식: ${log.amMeal}'),
                            Text('오후 배식: ${log.pmMeal}'),
                            Text('급수: ${log.water}'),
                            Text('운동: ${log.exercise}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AddCareLogDialog(
                shelterId: shelterId,
                animalId: animal.id,
              );
            },
          );
        },
        backgroundColor: const Color(0xFFFF7A00),
        tooltip: '케어 기록 추가',
        child: const Icon(Icons.note_add, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}