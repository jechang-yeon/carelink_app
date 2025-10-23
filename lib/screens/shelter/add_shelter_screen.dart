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
          'latitude': _latitude,
          'longitude': _longitude,
          'status': _status,
          'createdAt': Timestamp.now(),
          'managerUid': '',
          'managerContact': '',
          'staffUids': [],
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
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('보호소 정보',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '보호소 이름',
                          prefixIcon: Icon(Icons.home_work_outlined),
                        ),
                        validator: (value) =>
                        value!.isEmpty ? '보호소 이름을 입력해주세요.' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildAddressInput(
                          _addressController, _addressDetailController),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: '운영 상태',
                          prefixIcon: Icon(Icons.power_settings_new_outlined),
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
                    ],
                  ),
                ),
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

  Widget _buildAddressInput(TextEditingController mainController,
      TextEditingController detailController) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: mainController,
                decoration: const InputDecoration(
                  labelText: '주소',
                  hintText: '검색 또는 직접 입력',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                validator: (value) => value!.isEmpty ? '주소를 입력해주세요.' : null,
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
                if (result != null && result is Map<String, dynamic>) {
                  setState(() {
                    mainController.text = result['address'] ?? '';
                    _latitude = double.tryParse(result['latitude'].toString());
                    _longitude =
                        double.tryParse(result['longitude'].toString());
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('검색'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: detailController,
          decoration: const InputDecoration(
            labelText: '상세 주소',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
      ],
    );
  }
}
