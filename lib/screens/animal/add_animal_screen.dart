import 'dart:io';
import 'package:carelink_app/constants/terms_content.dart';
import 'package:carelink_app/screens/common/terms_view_screen.dart';
import 'package:carelink_app/screens/search/address_search_screen.dart';
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
  final List<XFile> _selectedImages = [];
  final PageController _pageController = PageController();

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
  final _ownerAddressDetailController = TextEditingController();

  bool _privacyConsent = false;
  bool _shelterUseConsent = false;
  bool _fosterConsent = false;

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
          _selectedImages.addAll(images);
        });
      }
    } else {
      final XFile? image = await _imagePickerService.pickImageFromCamera();
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_selectedImages.isNotEmpty) {
        _pageController.jumpToPage(index > 0 ? index - 1 : 0);
      }
    });
  }

  Future<void> _saveAnimal() async {
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
          'nameLowercase': _nameController.text.toLowerCase(),
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
          'ownerAddressDetail': _ownerAddressDetailController.text,
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
              _buildSectionCard(
                title: '사진 등록',
                child: _buildPhotoUploader(),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '동물 정보',
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _intakeType,
                      decoration: const InputDecoration(labelText: '입소 유형', prefixIcon: Icon(Icons.input_outlined)),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '이름', prefixIcon: Icon(Icons.badge_outlined)),
                      validator: (value) =>
                      value!.isEmpty ? '이름을 입력해주세요.' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _species,
                            decoration: const InputDecoration(labelText: '종류', prefixIcon: Icon(Icons.pets_outlined)),
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _gender,
                            decoration: const InputDecoration(labelText: '성별', prefixIcon: Icon(Icons.wc_outlined)),
                            hint: const Text('선택'),
                            items: ['수컷', '암컷']
                                .map((label) => DropdownMenuItem(
                              value: label,
                              child: Text(label),
                            ))
                                .toList(),
                            onChanged: (value) {
                              _gender = value;
                            },
                            validator: (value) =>
                            value == null ? '선택해주세요.' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: '몸무게 (kg)', prefixIcon: Icon(Icons.scale_outlined)),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                      value!.isEmpty ? '몸무게를 입력해주세요.' : null,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('중성화 여부'),
                      value: _isNeutered,
                      onChanged: (value) {
                        setState(() {
                          _isNeutered = value!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('동물 등록 여부'),
                      value: _isRegistered,
                      onChanged: (value) {
                        setState(() {
                          _isRegistered = value!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '보호자 정보',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(labelText: '보호자 이름', prefixIcon: Icon(Icons.person_outline)),
                      validator: (value) =>
                      value!.isEmpty ? '보호자 이름을 입력해주세요.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ownerContactController,
                      decoration: const InputDecoration(labelText: '보호자 연락처', prefixIcon: Icon(Icons.phone_outlined)),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                      value!.isEmpty ? '보호자 연락처를 입력해주세요.' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildAddressInput(
                        _ownerAddressController, _ownerAddressDetailController),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '이용 동의 (필수)',
                child: Column(
                  children: [
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAnimal,
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

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            child,
          ],
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
                color: value ? const Color(0xFF8A8A8E) : Colors.blue,
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
                  prefixIcon: Icon(Icons.home_outlined),
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
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12)),
              child: const Text('검색'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: detailController,
          decoration: const InputDecoration(
            labelText: '상세 주소',
            hintText: '동, 호수 등',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUploader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _selectedImages.isEmpty
              ? const Center(
            child:
            Text('사진을 등록해주세요.', style: TextStyle(color: Color(0xFF8A8A8E))),
          )
              : PageView.builder(
            controller: _pageController,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_selectedImages[index].path),
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _selectedImages.length,
                  (index) => Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // --- 수정: withOpacity -> withAlpha ---
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black)
                      .withAlpha(_pageController.hasClients && _pageController.page?.round() == index ? 230 : 102),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: [
              _buildPickerButton(Icons.photo_library_outlined, () => _pickImages(ImageSource.gallery), '갤러리'),
              const SizedBox(height: 8),
              _buildPickerButton(Icons.camera_alt_outlined, () => _pickImages(ImageSource.camera), '카메라'),
            ],
          ),
        ),
        if(_selectedImages.isNotEmpty)
          Positioned(
            top: 12,
            left: 12,
            child: _buildPickerButton(Icons.delete_outline, () => _deleteImage(_pageController.page?.round() ?? 0), '삭제'),
          ),
      ],
    );
  }

  Widget _buildPickerButton(IconData icon, VoidCallback onPressed, String tooltip) {
    return CircleAvatar(
      radius: 20,
      // --- 수정: withOpacity -> withAlpha ---
      backgroundColor: Colors.black.withAlpha(153),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}