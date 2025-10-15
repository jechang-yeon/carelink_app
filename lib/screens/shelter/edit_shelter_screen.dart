import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/shelter.dart';
import '../search/address_search_screen.dart';

class EditShelterScreen extends StatefulWidget {
  final Shelter shelter;
  const EditShelterScreen({super.key, required this.shelter});

  @override
  State<EditShelterScreen> createState() => _EditShelterScreenState();
}

class _EditShelterScreenState extends State<EditShelterScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _addressDetailController;
  late String _status;
  bool _isLoading = false;

  // 좌표 저장을 위한 변수
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shelter.name);
    _addressController = TextEditingController(text: widget.shelter.address);
    _addressDetailController =
        TextEditingController(text: widget.shelter.addressDetail);
    _status = widget.shelter.status;
    _latitude = widget.shelter.latitude;
    _longitude = widget.shelter.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  Future<void> _updateShelter() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await FirebaseFirestore.instance
            .collection('shelters')
            .doc(widget.shelter.id)
            .update({
          'name': _nameController.text,
          'address': _addressController.text,
          'addressDetail': _addressDetailController.text,
          'latitude': _latitude,
          'longitude': _longitude,
          'status': _status,
        });

        if (!mounted) return;
        Navigator.of(context).pop(); // 수정 후 대시보드로 복귀
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보호소 정보가 성공적으로 수정되었습니다.')),
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
        title: const Text('보호소 정보 수정'),
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
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? '보호소 이름을 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),
              // --- 수정된 주소 입력 위젯 ---
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: '주소',
                            hintText: '오른쪽 버튼으로 주소를 검색하세요.',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                          value!.isEmpty ? '주소를 검색해주세요.' : null,
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
                              _latitude = double.tryParse(
                                  result['latitude'].toString());
                              _longitude = double.tryParse(
                                  result['longitude'].toString());
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
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
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: '운영 상태',
                  border: OutlineInputBorder(),
                ),
                items: ['운영중', '종료']
                    .map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(label),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateShelter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : const Text(
                  '수정 완료',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}