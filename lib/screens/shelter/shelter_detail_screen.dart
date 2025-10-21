import 'dart:async';
import 'package:carelink_app/models/staff_model.dart';
import 'package:carelink_app/screens/animal/add_animal_screen.dart';
import 'package:carelink_app/screens/animal/animal_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carelink_app/models/shelter.dart';
import 'package:carelink_app/models/animal.dart';
import 'package:carelink_app/services/map_service.dart';

class ShelterDetailScreen extends StatefulWidget {
  final StaffModel user;
  final Shelter shelter;

  const ShelterDetailScreen(
      {super.key, required this.user, required this.shelter});

  @override
  State<ShelterDetailScreen> createState() => _ShelterDetailScreenState();
}

class _ShelterDetailScreenState extends State<ShelterDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  bool _canManageAnimals = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _checkPermissions();
  }

  void _checkPermissions() {
    final user = widget.user;
    final shelter = widget.shelter;

    if (user.role == 'SystemAdmin' ||
        user.role == 'AreaManager' ||
        shelter.managerUid == user.uid ||
        shelter.staffUids.contains(user.uid)) {
      setState(() {
        _canManageAnimals = true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapUrl =
    (widget.shelter.latitude != null && widget.shelter.longitude != null)
        ? MapService.getStaticMapUrl(
      latitude: widget.shelter.latitude!,
      longitude: widget.shelter.longitude!,
      height: 300,
    )
        : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF4A4A4A),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.shelter.name,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              background: mapUrl != null
                  ? Image.network(
                mapUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                      child:
                      Text('지도를 불러올 수 없습니다.', style: TextStyle(color: Colors.white70))),
                ),
              )
                  : Container(
                color: Colors.grey[300],
                child: const Center(
                    child: Text('위치 정보가 없습니다.', style: TextStyle(color: Colors.white70))),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.shelter.address} ${widget.shelter.addressDetail}',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF8A8A8E)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '상태: ${widget.shelter.status}',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.shelter.status == '운영중'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '동물 이름으로 검색...',
                      prefixIcon: const Icon(Icons.search_outlined),
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
                  const SizedBox(height: 16),
                  const Text(
                    '보호중인 동물',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          // --- 수정: StreamBuilder로 실제 동물 목록 표시 ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('shelters')
                .doc(widget.shelter.id)
                .collection('animals')
                .where('nameLowercase', isGreaterThanOrEqualTo: _searchQuery.toLowerCase())
                .where('nameLowercase', isLessThanOrEqualTo: '${_searchQuery.toLowerCase()}\uf8ff')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _searchQuery.isEmpty ? '아직 등록된 동물이 없습니다.' : '검색 결과가 없습니다.',
                        style: const TextStyle(color: Color(0xFF8A8A8E)),
                      ),
                    ),
                  ),
                );
              }

              final animals = snapshot.data!.docs.map((doc) => Animal.fromFirestore(doc)).toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final animal = animals[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.pets_outlined, color: Color(0xFF8A8A8E)),
                        title: Text(animal.name),
                        subtitle: Text('${animal.species} / ${animal.gender}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF8A8A8E)),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AnimalDetailScreen(
                                user: widget.user,
                                shelter: widget.shelter,
                                shelterId: widget.shelter.id,
                                animal: animal,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: animals.length,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _canManageAnimals
          ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  AddAnimalScreen(shelterId: widget.shelter.id),
            ),
          );
        },
        tooltip: '신규 동물 등록',
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}
