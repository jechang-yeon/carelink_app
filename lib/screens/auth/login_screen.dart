import 'package:carelink_app/models/staff_model.dart';
import 'package:carelink_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
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

  // --- 추가: 사용자 서비스를 사용하기 위한 인스턴스 ---
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
    setState(() {
      _rememberEmail = rememberEmail;
      if (_rememberEmail) {
        _emailController.text = prefs.getString(_emailPrefKey) ?? '';
      }
    });
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
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Firebase Authentication으로 로그인
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _saveEmailPreference();

      // --- 수정된 부분: 로그인 후 역할 정보 가져오기 ---
      // 2. Firestore에서 사용자의 역할 정보 가져오기
      final StaffModel? userModel = await _userService.getCurrentUserModel();

      if (mounted && userModel != null) {
        // 3. HomeScreen으로 사용자의 역할 정보를 전달하며 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => HomeScreen(user: userModel)),
        );
      } else if (mounted) {
        // 역할 정보를 가져오지 못한 경우 오류 처리
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자 역할 정보를 가져오는 데 실패했습니다.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      developer.log('로그인 실패: Firebase 오류 코드 - ${e.code}',
          name: 'LoginScreen');
      String errorMessage = '로그인에 실패했습니다. 다시 시도해주세요.';
      if (e.code == 'invalid-credential') {
        errorMessage = '등록되지 않은 이메일이거나 비밀번호가 틀렸습니다.';
      } else if (e.code == 'invalid-email') {
        errorMessage = '유효하지 않은 이메일 형식입니다.';
      } else if (e.code == 'user-disabled') {
        errorMessage = '사용 중지된 계정입니다.';
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
          const SnackBar(content: Text('알 수 없는 오류가 발생했습니다.')),
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/afa_logo.png',
                  width: 240,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.pets,
                      size: 80,
                      color: Color(0xFFFF7A00),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'CareLink',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A)),
                ),
                const Text(
                  '임시보호소 관리 시스템',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  obscureText: true,
                ),
                CheckboxListTile(
                  title: const Text('아이디 기억하기'),
                  value: _rememberEmail,
                  onChanged: (bool? value) {
                    setState(() {
                      _rememberEmail = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A00),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('로그인',
                        style:
                        TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
