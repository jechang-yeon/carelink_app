import 'package:carelink_app/services/map_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../search/address_search_screen.dart';

class AddShelterScreen extends StatefulWidget {
  const AddShelterScreen({super.key});

  @override
  State<AddShelterScreen> createState() => _AddShelterScreenState();
}

class _AddShelterScreenState extends State<AddShelterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressDetailController = TextEditingController();
  String _status = '운영중';
  bool _isLoading = false;

  // 좌표 저장을 위한 변수
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  Future<void> _saveShelter() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // 만약 좌표가 없고(주소 검색을 안했고) 주소 텍스트만 있다면,
      // 지오코딩 API를 통해 주소를 좌표로 변환 시도
      if ((_latitude == null || _longitude == null) &&
          _addressController.text.isNotEmpty) {
        final coords =
        await MapService.getCoordinatesFromAddress(_addressController.text);
        if (coords != null) {
          _latitude = coords['latitude'];
          _longitude = coords['longitude'];
        }
      }

      try {
        await FirebaseFirestore.instance.collection('shelters').add({
          'name': _nameController.text,
          'address': _addressController.text,
          'addressDetail': _addressDetailController.text,
          'latitude': _latitude, // 위도 저장
          'longitude': _longitude, // 경도 저장
          'status': _status,
          'createdAt': Timestamp.now(),
          'managerUid': '', // 초기에는 담당자 없음
          'staffUids': [], // 초기에는 소속 직원 없음
        });

        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신규 보호소가 등록되었습니다.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('신규 보호소 개설'),
        backgroundColor: const Color(0xFFFF7A00),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '보호소 이름',
                ),
                validator: (value) =>
                value!.isEmpty ? '보호소 이름을 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: '주소',
                            hintText: '검색 또는 직접 입력',
                          ),
                          validator: (value) =>
                          value!.isEmpty ? '주소를 입력해주세요.' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AddressSearchScreen(),
                            ),
                          );

                          if (result != null &&
                              result is Map<String, dynamic>) {
                            setState(() {
                              _addressController.text = result['address'] ?? '';
                              _latitude =
                                  double.tryParse(result['latitude'].toString());
                              _longitude = double.tryParse(
                                  result['longitude'].toString());
                            });
                          }
                        },
                        child: const Text('검색'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressDetailController,
                    decoration: const InputDecoration(
                      labelText: '상세 주소',
                      hintText: '동, 호수 등 상세 주소를 입력하세요.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: '운영 상태',
                ),
                items: ['운영중', '종료']
                    .map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(label),
                ))
                    .toList(),
                onChanged: (value) {
                  _status = value!;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveShelter,
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : const Text('등록하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}