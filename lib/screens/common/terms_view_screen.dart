import 'package:flutter/material.dart';

class TermsViewScreen extends StatelessWidget {
  final String title;
  final String content;

  const TermsViewScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF4A4A4A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(content),
      ),
      // --- 추가된 부분: 동의 버튼 ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // '동의' 버튼을 누르면 true 값을 가지고 이전 화면으로 돌아갑니다.
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7A00),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            '위 내용에 동의합니다',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}