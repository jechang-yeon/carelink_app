import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts 패키지 import
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareLink',
      theme: ThemeData(
        primaryColor: const Color(0xFFFF7A00),
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        // --- 수정 1: Pretendard -> Noto Sans KR ---
        fontFamily: GoogleFonts.notoSansKr().fontFamily,
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          backgroundColor: Color(0xFF4A4A4A),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFFF7A00)),
          ),
          labelStyle: const TextStyle(color: Color(0xFF8A8A8E)),
          // --- 수정 3 & 4: MaterialState -> WidgetState ---
          prefixIconColor: WidgetStateColor.resolveWith((states) =>
          states.contains(WidgetState.focused)
              ? const Color(0xFFFF7A00)
              : const Color(0xFF8A8A8E)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7A00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // --- 수정 2: CardTheme -> CardThemeData ---
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}