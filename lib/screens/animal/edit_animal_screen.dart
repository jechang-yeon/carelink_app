import 'dart:io';
import 'package:carelink_app/constants/terms_content.dart';
import 'package:carelink_app/screens/common/terms_view_screen.dart';
import 'package:carelink_app/services/image_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/animal.dart';

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

  final _imagePickerService = ImagePickerService();
  List<XFile> _newlySelectedImages = [];
  late List<String> _existingImageUrls;

  // Form Fields
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

  // Consent States
  late bool _privacyConsent;
  late bool _shelterUseConsent;
  late bool _fosterConsent;

  @override
  void initState() {
    super.initState();
    // Initialize form fields with existing data
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
    _existingImageUrls = List.from(widget.animal.photoUrls);
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

  Future<void> _pickImages() async {
    final List<XFile> images =
    await _imagePickerService.pickImagesFromGallery();
    if (images.isNotEmpty) {
      setState(() {
        _newlySelectedImages.addAll(images);
      });
    }
  }

  Future<void> _updateAnimal() async {
    if (!_privacyConsent || !_shelterUseConsent || !_fosterConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 약관에 동의해야 수정할 수 있습니다.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        List<String> newImageUrls = [];
        if (_newlySelectedImages.isNotEmpty) {
          newImageUrls = await _imagePickerService.uploadImages(
            images: _newlySelectedImages,
            shelterId: widget.shelterId,
          );
        }

        final finalImageUrls = _existingImageUrls + newImageUrls;

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
          'photoUrls': finalImageUrls,
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
        // Pop twice to go back to detail screen and refresh it
        Navigator.of(context).pop();
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
              // Photo Manager UI...
              const Text('사진 관리',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPhotoManager(),
              const SizedBox(height: 24),
              // Animal Info Form...
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
              // ... Other form fields
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
              // ... More form fields
              const Divider(height: 40),

              // Guardian Info Form...
              const Text('보호자 정보',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              // ... Guardian form fields
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

  Widget _buildPhotoManager() {
    // ... Photo Manager UI code (unchanged)
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: (_existingImageUrls.isEmpty && _newlySelectedImages.isEmpty)
              ? Center(
              child: Text('등록된 사진이 없습니다.',
                  style: TextStyle(color: Colors.grey[600])))
              : ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._existingImageUrls.map((url) => _buildPhotoThumbnail(url, false)),
              ..._newlySelectedImages.map((file) => _buildPhotoThumbnail(file.path, true)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.photo_library),
          label: const Text('갤러리에서 사진 추가'),
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(String path, bool isLocalFile) {
    // ... Photo Thumbnail code (unchanged)
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isLocalFile
                ? Image.file(
              File(path),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            )
                : Image.network(
              path,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isLocalFile) {
                    _newlySelectedImages.removeWhere((file) => file.path == path);
                  } else {
                    _existingImageUrls.remove(path);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}