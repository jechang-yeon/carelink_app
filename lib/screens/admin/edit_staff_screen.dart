import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/staff_model.dart';

class EditStaffScreen extends StatefulWidget {
  final StaffModel staff;
  const EditStaffScreen({super.key, required this.staff});

  @override
  State<EditStaffScreen> createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff.name);
    _selectedRole = widget.staff.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateStaff() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('staffs')
            .doc(widget.staff.uid)
            .update({
          'name': _nameController.text.trim(),
          'role': _selectedRole,
        });

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('직원 정보가 수정되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류가 발생했습니다: $e')),
          );
        }
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
        title: const Text('직원 정보 수정'),
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
                decoration: const InputDecoration(labelText: '이름'),
                validator: (value) => value!.isEmpty ? '이름을 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),
              // 이메일은 고유 ID이므로 수정 불가, 확인용으로만 표시
              TextFormField(
                initialValue: widget.staff.email,
                decoration: const InputDecoration(labelText: '이메일 (수정 불가)'),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // --- 수정: value -> initialValue ---
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: '기본 역할'),
                items: ['SystemAdmin', 'AreaManager', 'ShelterManager', 'ShelterStaff', 'Viewer']
                    .map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(role),
                ))
                    .toList(),
                onChanged: (value) {
                  // --- 수정: setState 제거 ---
                  _selectedRole = value!;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateStaff,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
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