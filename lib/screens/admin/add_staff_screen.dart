import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'Viewer'; // 기본 역할
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _registerStaff() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 1. Firebase Authentication에 사용자 생성
        final UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim());

        final user = userCredential.user;
        if (user != null) {
          // 2. Firestore 'staffs' 컬렉션에 역할 정보 저장
          await FirebaseFirestore.instance.collection('staffs').doc(user.uid).set({
            'email': user.email,
            'name': _nameController.text.trim(),
            'role': _selectedRole,
          });

          // --- 수정: BuildContext 사용 전 mounted 확인 ---
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('신규 직원이 등록되었습니다.')),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = '오류가 발생했습니다.';
        if (e.code == 'weak-password') {
          message = '비밀번호는 6자 이상이어야 합니다.';
        } else if (e.code == 'email-already-in-use') {
          message = '이미 사용 중인 이메일입니다.';
        }
        // --- 수정: BuildContext 사용 전 mounted 확인 ---
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        // --- 수정: BuildContext 사용 전 mounted 확인 ---
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알 수 없는 오류: $e')),
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
        title: const Text('신규 직원 등록'),
        backgroundColor: const Color(0xFFFF7A00),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름'),
                validator: (value) => value!.isEmpty ? '이름을 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: '이메일 (로그인 ID)'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value!.isEmpty ? '이메일을 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '초기 비밀번호'),
                obscureText: true,
                validator: (value) =>
                value!.isEmpty ? '비밀번호를 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // --- 수정: value -> initialValue ---
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: '기본 역할'),
                items: ['SystemAdmin', 'AreaManager', 'Viewer']
                    .map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(role),
                ))
                    .toList(),
                onChanged: (value) {
                  // --- 수정: setState 제거 ---
                  _selectedRole = value!;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerStaff,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  '등록하기',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}