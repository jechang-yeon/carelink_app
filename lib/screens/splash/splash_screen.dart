import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/staff_model.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    unawaited(_prepareInitialRoute());
  }

  Future<void> _prepareInitialRoute() async {
    try {
      // 인증 상태 확인과 최소 표시 시간을 병렬로 진행해 사용자의 체감 대기 시간을 줄입니다.
      final Future<StaffModel?> staffFuture = _loadCurrentStaff();
      await Future<void>.delayed(const Duration(milliseconds: 800));
      final StaffModel? staff = await staffFuture;

      if (!mounted) {
        return;
      }

      if (staff != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen(user: staff)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('초기화 중 오류가 발생했습니다: $error')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<StaffModel?> _loadCurrentStaff() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    return _userService.getCurrentUserModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash_logo.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 80,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '이미지를 불러올 수 없습니다.',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.15,
            left: 0,
            right: 0,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

