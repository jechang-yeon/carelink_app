import 'package:carelink_app/screens/animal/add_animal_screen.dart';
import 'package:carelink_app/screens/animal/animal_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/shelter.dart';
import '../../models/animal.dart';
import '../../services/map_service.dart';

// --- StatefulWidget으로 변경 ---
class ShelterDetailScreen extends StatefulWidget {
  final Shelter shelter;

  const ShelterDetailScreen({super.key, required this.shelter});

  @override
  State<ShelterDetailScreen> createState() => _ShelterDetailScreenState();
}

class _ShelterDetailScreenState extends State<ShelterDetailScreen> {
  // --- 검색 기능에 필요한 변수 추가 ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapUrl = (widget.shelter.latitude != null && widget.shelter.longitude != null)
        ? MapService.getStaticMapUrl(
      latitude: widget.shelter.latitude!,
      longitude: widget.shelter.longitude!,
    )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shelter.name),
        backgroundColor: const Color(0xFFFF7A00),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  widget.shelter.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.shelter.address} ${widget.shelter.addressDetail}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '상태: ${widget.shelter.status}',
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.shelter.status == '운영중'
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // --- 검색창 UI 추가 ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '동물 이름으로 검색',
                hintText: '이름을 입력하세요...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '보호중인 동물 목록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // --- 검색 쿼리에 따라 Firestore 쿼리 변경 ---
              stream: FirebaseFirestore.instance
                  .collection('shelters')
                  .doc(widget.shelter.id)
                  .collection('animals')
                  .where('name', isGreaterThanOrEqualTo: _searchQuery)
                  .where('name', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? '아직 등록된 동물이 없습니다.'
                          : '검색 결과가 없습니다.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                final animals = snapshot.data!.docs
                    .map((doc) => Animal.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                              shelterId: widget.shelter.id,
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
              builder: (context) => AddAnimalScreen(shelterId: widget.shelter.id),
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