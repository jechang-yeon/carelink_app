import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal.dart';

class EditAnimalScreen extends StatefulWidget {
  final String shelterId;
  final Animal animal;

  const EditAnimalScreen({
    super.key,
    required this.shelterId,
    required this.animal,
  });

  @override
  State<EditAnimalScreen> createState() => _EditAnimalScreenState();
}

class _EditAnimalScreenState extends State<EditAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form Field 값을 저장하기 위한 컨트롤러 및 변수들
  late TextEditingController _nameController;
  late String? _status;
  late String? _intakeType;
  late String? _species;
  late String? _gender;
  late TextEditingController _weightController;
  late bool _isNeutered;
  late bool _isRegistered;
  late TextEditingController _ownerNameController;
  late TextEditingController _ownerContactController;
  late TextEditingController _ownerAddressController;
  late bool _privacyConsent;
  late bool _shelterUseConsent;
  late bool _fosterConsent;

  @override
  void initState() {
    super.initState();
    // 기존 동물 정보로 폼 필드 초기화
    _nameController = TextEditingController(text: widget.animal.name);
    _status = widget.animal.status;
    _intakeType = widget.animal.intakeType;
    _species = widget.animal.species;
    _gender = widget.animal.gender;
    _weightController =
        TextEditingController(text: widget.animal.weight.toString());
    _isNeutered = widget.animal.isNeutered;
    _isRegistered = widget.animal.isRegistered;
    _ownerNameController =
        TextEditingController(text: widget.animal.ownerName);
    _ownerContactController =
        TextEditingController(text: widget.animal.ownerContact);
    _ownerAddressController =
        TextEditingController(text: widget.animal.ownerAddress);
    _privacyConsent = widget.animal.consents['privacy'] ?? false;
    _shelterUseConsent = widget.animal.consents['shelterUse'] ?? false;
    _fosterConsent = widget.animal.consents['foster'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _ownerNameController.dispose();
    _ownerContactController.dispose();
    _ownerAddressController.dispose();
    super.dispose();
  }

  Future<void> _updateAnimal() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('shelters')
            .doc(widget.shelterId)
            .collection('animals')
            .doc(widget.animal.id)
            .update({
          'name': _nameController.text,
          'status': _status,
          'intakeType': _intakeType,
          'species': _species,
          'gender': _gender,
          'weight': double.tryParse(_weightController.text) ?? 0.0,
          'isNeutered': _isNeutered,
          'isRegistered': _isRegistered,
          'ownerName': _ownerNameController.text,
          'ownerContact': _ownerContactController.text,
          'ownerAddress': _ownerAddressController.text,
          'consents': {
            'privacy': _privacyConsent,
            'shelterUse': _shelterUseConsent,
            'foster': _fosterConsent,
          },
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('동물 정보가 성공적으로 수정되었습니다.')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('동물 정보 수정'),
        backgroundColor: const Color(0xFFFF7A00),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('동물 정보',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: '동물 상태'),
                items: ['보호중', '퇴소', '병원 이관', '단체보호', '폐기']
                    .map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(label),
                ))
                    .toList(),
                onChanged: (value) {
                  _status = value;
                },
                validator: (value) => value == null ? '상태를 선택해주세요.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _intakeType,
                decoration: const InputDecoration(labelText: '입소 유형'),
                items: ['입소', '구조']
                    .map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(label),
                ))
                    .toList(),
                onChanged: (value) {
                  _intakeType = value;
                },
                validator: (value) => value == null ? '입소 유형을 선택해주세요.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름'),
                validator: (value) =>
                value!.isEmpty ? '이름을 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _species,
                decoration: const InputDecoration(labelText: '종류'),
                items: ['개', '고양이', '기타']
                    .map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(label),
                ))
                    .toList(),
                onChanged: (value) {
                  _species = value;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: '성별'),
                hint: const Text('성별을 선택하세요'),
                items: ['수컷', '암컷']
                    .map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(label),
                ))
                    .toList(),
                onChanged: (value) {
                  _gender = value;
                },
                validator: (value) => value == null ? '성별을 선택해주세요.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: '몸무게 (kg)'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty ? '몸무게를 입력해주세요.' : null,
              ),
              CheckboxListTile(
                title: const Text('중성화 여부'),
                value: _isNeutered,
                onChanged: (value) {
                  setState(() {
                    _isNeutered = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('동물 등록 여부'),
                value: _isRegistered,
                onChanged: (value) {
                  setState(() {
                    _isRegistered = value!;
                  });
                },
              ),
              const Divider(height: 40),
              const Text('보호자 정보',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(labelText: '보호자 이름'),
                validator: (value) =>
                value!.isEmpty ? '보호자 이름을 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerContactController,
                decoration: const InputDecoration(labelText: '보호자 연락처'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                value!.isEmpty ? '보호자 연락처를 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerAddressController,
                decoration: const InputDecoration(labelText: '보호자 주소'),
                validator: (value) =>
                value!.isEmpty ? '보호자 주소를 입력해주세요.' : null,
              ),
              const Divider(height: 40),
              const Text('이용 동의',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              CheckboxListTile(
                title: const Text('개인정보 이용 동의'),
                value: _privacyConsent,
                onChanged: (value) {
                  setState(() {
                    _privacyConsent = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('임시보호소 이용 동의'),
                value: _shelterUseConsent,
                onChanged: (value) {
                  setState(() {
                    _shelterUseConsent = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('동물 보호 위탁 동의'),
                value: _fosterConsent,
                onChanged: (value) {
                  setState(() {
                    _fosterConsent = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateAnimal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('수정 완료', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}