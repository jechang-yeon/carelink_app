import 'package:carelink_app/models/shelter.dart';
import 'package:carelink_app/models/staff_model.dart';
import 'package:carelink_app/widgets/delete_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/animal.dart';
import '../../models/care_log.dart';
import '../../widgets/add_care_log_dialog.dart';
import 'edit_animal_screen.dart';

class AnimalDetailScreen extends StatefulWidget {
  final StaffModel user;
  final Shelter shelter;
  final String shelterId;
  final Animal animal;

  const AnimalDetailScreen({
    super.key,
    required this.user,
    required this.shelter,
    required this.shelterId,
    required this.animal,
  });

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  bool _canEditOrDelete = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  void _checkPermissions() {
    final user = widget.user;
    final shelter = widget.shelter;
    if (user.role == 'SystemAdmin' || shelter.managerUid == user.uid) {
      setState(() {
        _canEditOrDelete = true;
      });
    }
  }

  Future<void> _deleteAnimal(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('shelters')
          .doc(widget.shelterId)
          .collection('animals')
          .doc(widget.animal.id)
          .delete();
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.animal.name} 정보가 삭제되었습니다.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _sendCareUpdateToOwner(BuildContext context) async {
    final logSnapshot = await FirebaseFirestore.instance
        .collection('shelters')
        .doc(widget.shelterId)
        .collection('animals')
        .doc(widget.animal.id)
        .collection('careLogs')
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (logSnapshot.docs.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전송할 케어 기록이 없습니다.')),
      );
      return;
    }

    final latestLog = CareLog.fromFirestore(logSnapshot.docs.first);
    final formattedDate =
    DateFormat('yyyy-MM-dd').format(latestLog.date.toDate());
    final messageContent =
        "안녕하세요 ${widget.animal.ownerName}님, [$formattedDate] ${widget.animal.name}의 케어 기록입니다.\n- 오전 배식: ${latestLog.amMeal}\n- 오후 배식: ${latestLog.pmMeal}\n- 급수: ${latestLog.water}\n- 운동: ${latestLog.exercise}";

    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: widget.animal.ownerContact,
      queryParameters: <String, String>{
        'body': messageContent,
      },
    );

    if (await canLaunchUrl(smsLaunchUri)) {
      await launchUrl(smsLaunchUri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문자 메시지를 보낼 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.animal.name),
        backgroundColor: const Color(0xFFFF7A00),
        actions: [
          if (_canEditOrDelete)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditAnimalScreen(
                      shelterId: widget.shelterId,
                      animal: widget.animal,
                    ),
                  ),
                );
              },
              tooltip: '정보 수정',
            ),
          if (_canEditOrDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => DeleteConfirmationDialog(
                    title: '동물 정보 삭제',
                    content:
                    '정말로 ${widget.animal.name}의 정보를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
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
            if (widget.animal.photoUrls.isNotEmpty)
              SizedBox(
                height: 250,
                child: PageView.builder(
                  itemCount: widget.animal.photoUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.animal.photoUrls[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : const Center(child: CircularProgressIndicator()),
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(Icons.camera_alt, color: Colors.grey, size: 60)),
              ),
            const SizedBox(height: 24),
            const Text('기본 정보',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildInfoRow('현재 상태', widget.animal.status),
            _buildInfoRow('입소 유형', widget.animal.intakeType),
            _buildInfoRow('이름', widget.animal.name),
            _buildInfoRow('종류', widget.animal.species),
            _buildInfoRow('성별', widget.animal.gender),
            _buildInfoRow('몸무게', '${widget.animal.weight} kg'),
            _buildInfoRow('중성화 여부', widget.animal.isNeutered ? '완료' : '미완료'),
            _buildInfoRow('동물 등록 여부', widget.animal.isRegistered ? '완료' : '미완료'),
            const SizedBox(height: 24),
            const Text('보호자 정보',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildInfoRow('이름', widget.animal.ownerName),
            _buildInfoRow('연락처', widget.animal.ownerContact),
            _buildInfoRow('주소', '${widget.animal.ownerAddress} ${widget.animal.ownerAddressDetail}'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('데일리 케어 기록',
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _sendCareUpdateToOwner(context),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('알림 전송'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                )
              ],
            ),
            const Divider(),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shelters')
                  .doc(widget.shelterId)
                  .collection('animals')
                  .doc(widget.animal.id)
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(formattedDate,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(log.recordedByEmail,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
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
                shelterId: widget.shelterId,
                animalId: widget.animal.id,
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

