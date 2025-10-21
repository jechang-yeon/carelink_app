import 'package:carelink_app/models/staff_model.dart';
import 'package:carelink_app/services/map_service.dart';
import 'package:carelink_app/services/user_service.dart';
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

  double? _latitude;
  double? _longitude;

  final UserService _userService = UserService();
  List<StaffModel> _allStaff = [];
  String? _selectedManagerUid;
  List<String> _selectedStaffUids = [];

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

    _selectedManagerUid =
    widget.shelter.managerUid.isNotEmpty ? widget.shelter.managerUid : null;
    _selectedStaffUids = List.from(widget.shelter.staffUids);
    _loadAllStaff();
  }

  Future<void> _loadAllStaff() async {
    if (!mounted) return;
    final staffList = await _userService.getAllStaff().first;
    if (mounted) {
      setState(() {
        _allStaff = staffList;
      });
    }
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

      if (_addressController.text.isNotEmpty && (_latitude == null || _longitude == null)) {
        final coords =
        await MapService.getCoordinatesFromAddress(_addressController.text);
        if (coords != null) {
          _latitude = coords['latitude'];
          _longitude = coords['longitude'];
        }
      }

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
          'managerUid': _selectedManagerUid ?? '',
          'staffUids': _selectedStaffUids,
        });

        if (!mounted) return;
        Navigator.of(context).pop();
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

  void _showStaffSelectionDialog() {
    List<String> tempSelectedStaff = List.from(_selectedStaffUids);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('소속 직원 선택'),
              content: SizedBox(
                width: double.maxFinite,
                child: _allStaff.isEmpty
                    ? const Center(child: Text('등록된 직원이 없습니다.'))
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allStaff.length,
                  itemBuilder: (context, index) {
                    final staff = _allStaff[index];
                    if (staff.uid == _selectedManagerUid) {
                      return const SizedBox.shrink();
                    }
                    return CheckboxListTile(
                      title: Text(staff.name),
                      subtitle: Text(staff.email),
                      value: tempSelectedStaff.contains(staff.uid),
                      onChanged: (isSelected) {
                        setDialogState(() {
                          if (isSelected == true) {
                            tempSelectedStaff.add(staff.uid);
                          } else {
                            tempSelectedStaff.remove(staff.uid);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStaffUids = tempSelectedStaff;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('보호소 정보 수정'),
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
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('담당자 지정',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        // --- 수정: value -> initialValue ---
                        initialValue: _selectedManagerUid,
                        hint: const Text('책임자를 선택하세요'),
                        decoration: const InputDecoration(
                          labelText: '보호소 책임자',
                          prefixIcon: Icon(Icons.person_pin_outlined),
                        ),
                        items: _allStaff
                            .map((staff) => DropdownMenuItem(
                          value: staff.uid,
                          child: Text('${staff.name} (${staff.email})'),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedManagerUid = value;
                            _selectedStaffUids.remove(value);
                          });
                        },
                        validator: (value) =>
                        value == null ? '책임자를 지정해주세요.' : null,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _showStaffSelectionDialog,
                        icon: const Icon(Icons.group_add_outlined),
                        label: Text('소속 직원 선택 (${_selectedStaffUids.length}명)'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateShelter,
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : const Text('수정 완료'),
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
                    _latitude =
                        double.tryParse(result['latitude'].toString());
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
            hintText: '동, 호수 등',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
      ],
    );
  }
}