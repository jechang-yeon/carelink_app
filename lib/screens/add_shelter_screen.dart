import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'address_search_screen.dart'; // 주소 검색 화면 import

class AddShelterScreen extends StatefulWidget {
  const AddShelterScreen({super.key});

  @override
  State<AddShelterScreen> createState() => _AddShelterScreenState();
}

class _AddShelterScreenState extends State<AddShelterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController(); // 주소 컨트롤러
  String _status = '운영중';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveShelter() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await FirebaseFirestore.instance.collection('shelters').add({
          'name': _nameController.text,
          'address': _addressController.text,
          'status': _status,
          'createdAt': Timestamp.now(),
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
        // --- 수정된 부분 ---
        // return을 사용하지 않고, mounted 상태일 때만 setState를 호출하도록 변경
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
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '보호소 이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: '보호소 주소',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '보호소 주소를 입력해주세요.';
                        }
                        return null;
                      },
                      maxLines: 2, // 주소가 길 수 있으므로 2줄로 설정
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      // 주소 검색 화면으로 이동하고 결과를 받음
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddressSearchScreen(),
                        ),
                      );

                      // 결과가 있으면 주소 컨트롤러에 값 설정
                      if (result != null && result is String) {
                        setState(() {
                          _addressController.text = result;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('주소 검색'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
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
                  _status = value!;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveShelter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : const Text(
                  '등록하기',
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