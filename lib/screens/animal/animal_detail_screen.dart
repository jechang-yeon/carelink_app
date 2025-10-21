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
  bool _canPerformActions = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  void _checkPermissions() {
    final user = widget.user;
    final shelter = widget.shelter;
    if (user.role == 'SystemAdmin' || shelter.managerUid == user.uid) {
      _canEditOrDelete = true;
    }
    if (_canEditOrDelete ||
        user.role == 'AreaManager' ||
        shelter.staffUids.contains(user.uid)) {
      _canPerformActions = true;
    }
    setState(() {});
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
      queryParameters: <String, String>{'body': messageContent},
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF4A4A4A),
            actions: [
              if (_canEditOrDelete)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
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
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => DeleteConfirmationDialog(
                        title: '동물 정보 삭제',
                        content:
                        '정말로 ${widget.animal.name}의 정보를 삭제하시겠습니까?',
                        onConfirm: () => _deleteAnimal(context),
                      ),
                    );
                  },
                  tooltip: '정보 삭제',
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.animal.name,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              background: widget.animal.photoUrls.isNotEmpty
                  ? Image.network(
                widget.animal.photoUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderImage(),
              )
                  : _buildPlaceholderImage(),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildInfoCard(
                title: '기본 정보',
                children: [
                  _buildInfoRow('현재 상태', widget.animal.status),
                  _buildInfoRow('입소 유형', widget.animal.intakeType),
                  _buildInfoRow('종류', widget.animal.species),
                  _buildInfoRow('성별', widget.animal.gender),
                  _buildInfoRow('몸무게', '${widget.animal.weight} kg'),
                  _buildInfoRow(
                      '중성화 여부', widget.animal.isNeutered ? '완료' : '미완료'),
                  _buildInfoRow(
                      '동물 등록 여부', widget.animal.isRegistered ? '완료' : '미완료'),
                ],
              ),
              _buildInfoCard(
                title: '보호자 정보',
                children: [
                  _buildInfoRow('이름', widget.animal.ownerName),
                  _buildInfoRow('연락처', widget.animal.ownerContact),
                  _buildInfoRow(
                      '주소',
                      '${widget.animal.ownerAddress} ${widget.animal.ownerAddressDetail}'),
                ],
              ),
              _buildCareLogSection(),
            ]),
          ),
        ],
      ),
      floatingActionButton: _canPerformActions
          ? FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddCareLogDialog(
              shelterId: widget.shelterId,
              animalId: widget.animal.id,
            ),
          );
        },
        tooltip: '케어 기록 추가',
        child: const Icon(Icons.note_add_outlined),
      )
          : null,
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child:
      const Center(child: Icon(Icons.pets, size: 80, color: Colors.white)),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8A8A8E))),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildCareLogSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('데일리 케어 기록',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (_canPerformActions)
                  TextButton.icon(
                    onPressed: () => _sendCareUpdateToOwner(context),
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: const Text('알림 전송'),
                  ),
              ],
            ),
            const Divider(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shelters')
                  .doc(widget.shelterId)
                  .collection('animals')
                  .doc(widget.animal.id)
                  .collection('careLogs')
                  .orderBy('date', descending: true)
                  .limit(10)
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
                          style: TextStyle(color: Color(0xFF8A8A8E))),
                    ),
                  );
                }
                final careLogs = snapshot.data!.docs
                    .map((doc) => CareLog.fromFirestore(doc))
                    .toList();
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: careLogs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final log = careLogs[index];
                    final formattedDate =
                    DateFormat('yyyy-MM-dd').format(log.date.toDate());
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(formattedDate,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(log.recordedByEmail,
                                  style: const TextStyle(
                                      color: Color(0xFF8A8A8E), fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('오전: ${log.amMeal} / 오후: ${log.pmMeal}'),
                          Text('급수: ${log.water}'),
                          Text('운동: ${log.exercise}'),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

