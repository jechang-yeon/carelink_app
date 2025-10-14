import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddShelterScreen extends StatefulWidget {
  const AddShelterScreen({super.key});

  @override
  State<AddShelterScreen> createState() => _AddShelterScreenState();
}

class _AddShelterScreenState extends State<AddShelterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  // 폼이 저장될 때 최종 선택된 값을 담을 변수
  String _selectedStatus = '운영중';
  bool _isLoading = false;

  Future<void> _addShelter() async {
    // 1. 폼의 유효성을 먼저 검사합니다.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. 유효성 검사를 통과하면 폼을 저장합니다.
    // 이 때 각 FormField의 onSaved 콜백이 호출됩니다.
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      // 3. onSaved를 통해 업데이트된 _selectedStatus 값을 사용하여 Firestore에 저장합니다.
      await FirebaseFirestore.instance.collection('shelters').add({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'status': _selectedStatus,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('보호소 추가에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('신규 보호소 개설'),
        backgroundColor: const Color(0xFFFF7A00),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '보호소 이름',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '보호소 이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '주소',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '주소를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // --- 경고가 발생했던 DropdownButtonFormField 수정 ---
              DropdownButtonFormField<String>(
                // 1. 'value' 대신 'initialValue'를 사용하여 경고를 해결했습니다.
                initialValue: '운영중',
                decoration: const InputDecoration(
                  labelText: '운영 상태',
                  border: OutlineInputBorder(),
                ),
                items: ['운영중', '종료']
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
                    .toList(),
                // 2. onChanged에서는 이제 UI 상태를 직접 변경할 필요가 없습니다.
                //    FormField가 내부적으로 선택된 값을 관리하고 화면에 표시해줍니다.
                onChanged: (value) {},
                // 3. 폼의 save()가 호출될 때, 최종 선택된 값을 _selectedStatus 변수에 저장합니다.
                onSaved: (value) {
                  if (value != null) {
                    _selectedStatus = value;
                  }
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _addShelter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  '저장하기',
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