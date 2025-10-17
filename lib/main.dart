import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart'; // 스플래시 화면 import

Future<void> main() async {
  // Flutter 앱이 실행될 준비가 되었는지 확인합니다.
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase 서비스를 초기화합니다.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 앱을 실행합니다.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareLink',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
        ),
      ),
      // --- 가장 중요한 부분 ---
      // 앱의 첫 화면을 스플래시 화면으로 명확하게 지정합니다.
      home: const SplashScreen(),
    );
  }
}