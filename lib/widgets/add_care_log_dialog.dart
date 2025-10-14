import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddCareLogDialog extends StatefulWidget {
  final String shelterId;
  final String animalId;

  const AddCareLogDialog({
    super.key,
    required this.shelterId,
    required this.animalId,
  });

  @override
  State<AddCareLogDialog> createState() => _AddCareLogDialogState();
}

class _AddCareLogDialogState extends State<AddCareLogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amMealController = TextEditingController();
  final _pmMealController = TextEditingController();
  final _waterController = TextEditingController();
  final _exerciseController = TextEditingController();
  bool _isLoading = false;

  // 날짜 관리를 위한 변수
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amMealController.dispose();
    _pmMealController.dispose();
    _waterController.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  // 날짜 선택 팝업(DatePicker)을 띄우는 함수
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // 오늘 이후 날짜는 선택 불가
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveLog() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // 현재 로그인한 사용자의 이메일 가져오기
      final userEmail =
          FirebaseAuth.instance.currentUser?.email ?? '알 수 없는 사용자';

      try {
        await FirebaseFirestore.instance
            .collection('shelters')
            .doc(widget.shelterId)
            .collection('animals')
            .doc(widget.animalId)
            .collection('careLogs')
            .add({
          'date': Timestamp.fromDate(_selectedDate), // 선택된 날짜로 저장
          'amMeal': _amMealController.text,
          'pmMeal': _pmMealController.text,
          'water': _waterController.text,
          'exercise': _exerciseController.text,
          'recordedByEmail': userEmail, // 현재 사용자 이메일 저장
        });

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('케어 기록이 추가되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류 발생: $e')),
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
    return AlertDialog(
      title: const Text('데일리 케어 기록 추가'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 날짜 선택 UI
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '기록 날짜: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                    tooltip: '날짜 선택',
                  ),
                ],
              ),
              const Divider(),
              TextFormField(
                controller: _amMealController,
                decoration: const InputDecoration(labelText: '오전 배식'),
                validator: (value) =>
                value!.isEmpty ? '내용을 입력해주세요.' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pmMealController,
                decoration: const InputDecoration(labelText: '오후 배식'),
                validator: (value) =>
                value!.isEmpty ? '내용을 입력해주세요.' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _waterController,
                decoration: const InputDecoration(labelText: '급수'),
                validator: (value) =>
                value!.isEmpty ? '내용을 입력해주세요.' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _exerciseController,
                decoration: const InputDecoration(labelText: '운동'),
                validator: (value) =>
                value!.isEmpty ? '내용을 입력해주세요.' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveLog,
          child: _isLoading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('저장'),
        ),
      ],
    );
  }
}