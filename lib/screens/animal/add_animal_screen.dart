import 'dart:io';
import 'package:carelink_app/constants/terms_content.dart';
import 'package:carelink_app/screens/common/terms_view_screen.dart';
import 'package:carelink_app/services/image_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddAnimalScreen extends StatefulWidget {
  final String shelterId;
  const AddAnimalScreen({super.key, required this.shelterId});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _imagePickerService = ImagePickerService();
  List<XFile> _selectedImages = [];

  // Form Fields
  final _nameController = TextEditingController();
  String? _intakeType = '입소';
  String? _species = '개';
  String? _gender;
  final _weightController = TextEditingController();
  bool _isNeutered = false;
  bool _isRegistered = false;
  final _ownerNameController = TextEditingController();
  final _ownerContactController = TextEditingController();
  final _ownerAddressController = TextEditingController();

  // Consent states
  bool _privacyConsent = false;
  bool _shelterUseConsent = false;
  bool _fosterConsent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _ownerNameController.dispose();
    _ownerContactController.dispose();
    _ownerAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images =
    await _imagePickerService.pickImagesFromGallery();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images;
      });
    }
  }

  Future<void> _saveAnimal() async {
    // 모든 동의 항목이 체크되었는지 확인
    if (!_privacyConsent || !_shelterUseConsent || !_fosterConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 약관에 동의해주세요.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        List<String> imageUrls = await _imagePickerService.uploadImages(
          images: _selectedImages,
          shelterId: widget.shelterId,
        );

        await FirebaseFirestore.instance
            .collection('shelters')
            .doc(widget.shelterId)
            .collection('animals')
            .add({
          'name': _nameController.text,
          'intakeType': _intakeType,
          'species': _species,
          'gender': _gender,
          'weight': double.tryParse(_weightController.text) ?? 0.0,
          'isNeutered': _isNeutered,
          'isRegistered': _isRegistered,
          'photoUrls': imageUrls,
          'ownerName': _ownerNameController.text,
          'ownerContact': _ownerContactController.text,
          'ownerAddress': _ownerAddressController.text,
          'consents': {
            'privacy': _privacyConsent,
            'shelterUse': _shelterUseConsent,
            'foster': _fosterConsent,
          },
          'status': '보호중',
          'createdAt': Timestamp.now(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('동물 정보가 성공적으로 등록되었습니다.')),
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
        title: const Text('신규 동물 등록'),
        backgroundColor: const Color(0xFFFF7A00),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Picker UI...
              const Text('사진 등록',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPhotoPicker(),
              const SizedBox(height: 24),

              // Animal Info Form...
              const Text('동물 정보',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              ),
              // ... Other form fields (name, species, etc.)
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

              // Guardian Info Form...
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

              // --- 수정된 동의 항목 UI ---
              const Text('이용 동의 (필수)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildConsentTile(
                title: TermsContent.privacyTitle,
                content: TermsContent.privacyContent,
                value: _privacyConsent,
                onChanged: (newValue) {
                  setState(() {
                    _privacyConsent = newValue;
                  });
                },
              ),
              _buildConsentTile(
                title: TermsContent.shelterUseTitle,
                content: TermsContent.shelterUseContent,
                value: _shelterUseConsent,
                onChanged: (newValue) {
                  setState(() {
                    _shelterUseConsent = newValue;
                  });
                },
              ),
              _buildConsentTile(
                title: TermsContent.fosterTitle,
                content: TermsContent.fosterContent,
                value: _fosterConsent,
                onChanged: (newValue) {
                  setState(() {
                    _fosterConsent = newValue;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAnimal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('등록하기', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 동의 항목을 위한 헬퍼 위젯
  Widget _buildConsentTile({
    required String title,
    required String content,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (newValue) => onChanged(newValue!),
        ),
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    TermsViewScreen(title: title, content: content),
              ));
            },
            child: Text(
              title,
              style: const TextStyle(
                decoration: TextDecoration.underline,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPicker() {
    // ... Photo Picker UI code (unchanged)
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: _selectedImages.isEmpty
              ? Center(
              child: Text('선택된 사진이 없습니다.',
                  style: TextStyle(color: Colors.grey[600])))
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_selectedImages[index].path),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.photo_library),
          label: const Text('갤러리에서 사진 선택'),
        ),
      ],
    );
  }
}