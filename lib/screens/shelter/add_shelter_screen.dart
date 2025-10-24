import 'package:carelink_app/models/staff_model.dart';
import 'package:carelink_app/services/map_service.dart';
import 'package:carelink_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
  final _managerContactController = TextEditingController();
  final TextEditingController _openingDateController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  final UserService _userService = UserService();

  String _status = '준비 중';
  bool _isLoading = false;
  bool _isStaffLoading = false;
  DateTime? _openingDate;
  List<StaffModel> _staffMembers = [];
  String? _selectedManagerUid;

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadStaffMembers();
  }

  Future<void> _loadStaffMembers() async {
    setState(() {
      _isStaffLoading = true;
    });

    try {
      final List<StaffModel> staff = await _userService.getAllStaff().first;
      if (!mounted) return;
      setState(() {
        _staffMembers = staff;
        _isStaffLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _staffMembers = [];
        _isStaffLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    _managerContactController.dispose();
    _openingDateController.dispose();
    super.dispose();
  }

  Future<void> _pickOpeningDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 10);
    final DateTime lastDate = DateTime(now.year + 10);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _openingDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        _openingDate = pickedDate;
        _openingDateController.text = _dateFormat.format(pickedDate);
      });
    }
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
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'addressDetail': _addressDetailController.text.trim(),
          'latitude': _latitude,
          'longitude': _longitude,
          'status': _status,
          'createdAt': Timestamp.now(),
          'openingDate':
          _openingDate != null ? Timestamp.fromDate(_openingDate!) : null,
          'managerUid': _selectedManagerUid ?? '',
          'managerContact': _managerContactController.text.trim(),
          'staffUids': _selectedManagerUid != null
              ? <String>[_selectedManagerUid!]
              : <String>[],
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
    final Color titleColor = _resolveTitleColor(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: kToolbarHeight + 12,
        iconTheme: IconThemeData(color: titleColor),
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: _buildAppBarTitle(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                '보호소 정보',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildSectionDivider(context),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _openingDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: '개설일',
                          hintText: '개설일을 선택하세요',
                          prefixIcon: Icon(Icons.event_available_outlined),
                        ),
                        onTap: _pickOpeningDate,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '보호소 이름',
                          prefixIcon: Icon(Icons.home_work_outlined),
                        ),
                        validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? '보호소 이름을 입력해주세요.'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _buildAddressInput(
                        _addressController,
                        _addressDetailController,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String?>(
                        value: _selectedManagerUid,
                        decoration: const InputDecoration(
                          labelText: '담당자 선택',
                          hintText: '등록된 직원 중 담당자를 선택하세요',
                          prefixIcon: Icon(Icons.person_pin_outlined),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('미정'),
                          ),
                          ..._staffMembers.map(
                                (StaffModel staff) => DropdownMenuItem<String?>(
                              value: staff.uid,
                              child: Text('${staff.name} (${staff.email})'),
                            ),
                          ),
                        ],
                        onChanged: _isStaffLoading
                            ? null
                            : (String? value) {
                          setState(() {
                            _selectedManagerUid = value;
                            final StaffModel? selectedStaff = value == null
                                ? null
                                : _staffMembers.firstWhere(
                                  (staff) => staff.uid == value,
                              orElse: () => StaffModel(
                                uid: value,
                                email: '',
                                name: '',
                                role: '',
                                phoneNumber: '',
                              ),
                            );
                            _managerContactController.text =
                                selectedStaff?.phoneNumber ?? '';
                          });
                        },
                      ),
                      if (_isStaffLoading) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('직원 정보를 불러오는 중입니다...'),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _managerContactController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: '담당자 연락처',
                          hintText: '예: 010-1234-5678',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: '운영 상태',
                          prefixIcon: Icon(Icons.power_settings_new_outlined),
                        ),
                        items: const ['준비 중', '운영 중']
                            .map(
                              (label) => DropdownMenuItem(
                            value: label,
                            child: Text(label),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _status = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarTitle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle = theme.appBarTheme.titleTextStyle ??
        theme.textTheme.titleLarge ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
    final double baseFontSize = baseStyle.fontSize ?? 20;
    final double scaledFontSize = baseFontSize * 1.5;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'New ',
            style: baseStyle.copyWith(
              fontSize: scaledFontSize,
              fontWeight: FontWeight.w300,
              height: 1.1,
            ),
          ),
          TextSpan(
            text: 'Shelter',
            style: baseStyle.copyWith(
              fontSize: scaledFontSize,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInput(
      TextEditingController mainController,
      TextEditingController detailController,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? '주소를 입력해주세요.'
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final Map<String, dynamic>? result =
                await Navigator.of(context).push<Map<String, dynamic>?>(
                  MaterialPageRoute<Map<String, dynamic>?>(
                    builder: (BuildContext context) =>
                    const AddressSearchScreen(),
                  ),
                );
                if (result != null) {
                  setState(() {
                    mainController.text = result['address'] as String? ?? '';
                    _latitude =
                        double.tryParse(result['latitude'].toString());
                    _longitude =
                        double.tryParse(result['longitude'].toString());
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
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

  Divider _buildSectionDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }

  Color _resolveTitleColor(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle = theme.appBarTheme.titleTextStyle ??
        theme.textTheme.titleLarge ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
    return baseStyle.color ?? theme.colorScheme.onSurface;
  }
}






