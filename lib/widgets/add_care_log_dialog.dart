import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void dispose() {
    _amMealController.dispose();
    _pmMealController.dispose();
    _waterController.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('shelters')
            .doc(widget.shelterId)
            .collection('animals')
            .doc(widget.animalId)
            .collection('careLogs')
            .add({
          'date': Timestamp.now(),
          'amMeal': _amMealController.text,
          'pmMeal': _pmMealController.text,
          'water': _waterController.text,
          'exercise': _exerciseController.text,
          'recordedBy': '', // 추후 기록자 정보 추가
        });

        if (mounted) {
          Navigator.of(context).pop(); // 성공 시 팝업 닫기
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