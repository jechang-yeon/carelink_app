import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

import '../../models/staff_model.dart';
import '../../services/user_service.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberEmail = false;

  final UserService _userService = UserService();

  static const String _emailPrefKey = 'saved_email';
  static const String _rememberPrefKey = 'remember_email';

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final bool rememberEmail = prefs.getBool(_rememberPrefKey) ?? false;
    if (mounted) {
      setState(() {
        _rememberEmail = rememberEmail;
        if (_rememberEmail) {
          _emailController.text = prefs.getString(_emailPrefKey) ?? '';
        }
      });
    }
  }

  Future<void> _saveEmailPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberPrefKey, _rememberEmail);
    if (_rememberEmail) {
      await prefs.setString(_emailPrefKey, _emailController.text.trim());
    } else {
      await prefs.remove(_emailPrefKey);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _saveEmailPreference();

      final StaffModel? userModel = await _userService.getCurrentUserModel();

      if (mounted && userModel != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen(user: userModel)),
        );
      } else if (mounted) {
        throw Exception('사용자 정보를 불러올 수 없습니다.');
      }
    } on FirebaseAuthException catch (e) {
      developer.log('로그인 실패: Firebase 오류 코드 - ${e.code}', name: 'LoginScreen');
      String errorMessage = '로그인에 실패했습니다. 다시 시도해주세요.';
      if (e.code == 'invalid-credential') {
        errorMessage = '등록되지 않은 이메일이거나 비밀번호가 틀렸습니다.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      developer.log('로그인 실패: 알 수 없는 오류 - $e', name: 'LoginScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/afa_logo.png',
                  height: 80,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.pets, size: 80, color: Color(0xFFFF7A00));
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  '환영합니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '케어링크 시스템에 로그인해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8A8A8E),
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                CheckboxListTile(
                  title: const Text('아이디 기억하기', style: TextStyle(fontSize: 14)),
                  value: _rememberEmail,
                  onChanged: (bool? value) {
                    setState(() {
                      _rememberEmail = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : const Text('로그인'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
