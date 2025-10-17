import 'dart:io';
import 'package:carelink_app/constants/terms_content.dart';
import 'package:carelink_app/screens/common/terms_view_screen.dart';
import 'package:carelink_app/screens/search/address_search_screen.dart';
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
  final List<XFile> _newlySelectedImages = [];
  late List<String> _existingImageUrls;
  final PageController _pageController = PageController();

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
  late TextEditingController _ownerAddressDetailController;

  late bool _privacyConsent;
  late bool _shelterUseConsent;
  late bool _fosterConsent;

  @override
  void initState() {
    super.initState();
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
    _ownerAddressDetailController =
        TextEditingController(text: widget.animal.ownerAddressDetail);
    _existingImageUrls = List.from(widget.animal.photoUrls);
    _privacyConsent = widget.animal.consents['privacy'] ?? false;
    _shelterUseConsent = widget.animal.consents['shelterUse'] ?? false;
    _fosterConsent = widget.animal.consents['foster'] ?? false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _ownerNameController.dispose();
    _ownerContactController.dispose();
    _ownerAddressController.dispose();
    _ownerAddressDetailController.dispose();
    super.dispose();
  }

  Future<void> _pickImages(ImageSource source) async {
    if (source == ImageSource.gallery) {
      final List<XFile> images =
      await _imagePickerService.pickImagesFromGallery();
      if (images.isNotEmpty) {
        setState(() {
          _newlySelectedImages.addAll(images);
        });
      }
    } else {
      final XFile? image = await _imagePickerService.pickImageFromCamera();
      if (image != null) {
        setState(() {
          _newlySelectedImages.add(image);
        });
      }
    }
  }

  void _deleteImage(int index, bool isExisting) {
    setState(() {
      if (isExisting) {
        _existingImageUrls.removeAt(index);
      } else {
        _newlySelectedImages.removeAt(index - _existingImageUrls.length);
      }
    });
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
          'nameLowercase': _nameController.text.toLowerCase(),
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
          'ownerAddressDetail': _ownerAddressDetailController.text,
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
              _buildPhotoUploader(),
              const SizedBox(height: 24),
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
              _buildAddressInput(
                  _ownerAddressController, _ownerAddressDetailController),
              const Divider(height: 40),
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
          onChanged: null,
        ),
        Expanded(
          child: InkWell(
            onTap: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) =>
                      TermsViewScreen(title: title, content: content),
                ),
              );
              if (result == true) {
                onChanged(true);
              }
            },
            child: Text(
              title,
              style: TextStyle(
                decoration: TextDecoration.underline,
                color: value ? Colors.grey : Colors.blue,
              ),
            ),
          ),
        ),
      ],
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
                  border: OutlineInputBorder(),
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
          controller: detailController,
          decoration: const InputDecoration(
            labelText: '상세 주소',
            hintText: '동, 호수 등 상세 주소를 입력하세요.',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUploader() {
    final allImages = [..._existingImageUrls, ..._newlySelectedImages];

    return Stack(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: allImages.isEmpty
              ? const Center(
            child:
            Text('사진을 등록해주세요.', style: TextStyle(color: Colors.grey)),
          )
              : PageView.builder(
            controller: _pageController,
            itemCount: allImages.length,
            itemBuilder: (context, index) {
              final item = allImages[index];
              final isExisting = item is String;
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isExisting
                        ? Image.network(item, fit: BoxFit.cover)
                        : Image.file(File((item as XFile).path),
                        fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black.withAlpha(153),
                      child: IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.white, size: 18),
                        onPressed: () => _deleteImage(index, isExisting),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black.withAlpha(153),
                child: IconButton(
                  icon: const Icon(Icons.photo_library,
                      color: Colors.white, size: 18),
                  onPressed: () => _pickImages(ImageSource.gallery),
                  tooltip: '갤러리에서 선택',
                ),
              ),
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black.withAlpha(153),
                child: IconButton(
                  icon:
                  const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  onPressed: () => _pickImages(ImageSource.camera),
                  tooltip: '카메라로 촬영',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}