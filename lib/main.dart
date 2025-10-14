import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // Flutter 앱이 실행될 준비가 되었는지 확인합니다.
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase 서비스를 앱에서 사용할 수 있도록 초기화합니다.
  await Firebase.initializeApp();
  runApp(const CareLinkApp());
}

class CareLinkApp extends StatelessWidget {
  const CareLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareLink',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // AuthWrapper가 사용자의 로그인 상태를 확인하고 올바른 화면을 보여줍니다.
      home: const AuthWrapper(),
    );
  }
}

// 사용자의 인증 상태를 실시간으로 확인하는 위젯
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth의 인증 상태 변경을 스트림으로 받습니다.
    // (로그인, 로그아웃 등)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 데이터 연결을 기다리는 중이면 로딩 아이콘을 보여줍니다.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 스트림에 데이터가 있으면(로그인된 상태이면) HomeScreen을 보여줍니다.
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // 데이터가 없으면(로그아웃된 상태이면) LoginScreen을 보여줍니다.
        return const LoginScreen();
      },
    );
  }
}