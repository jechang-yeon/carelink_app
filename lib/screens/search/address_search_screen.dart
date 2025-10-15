import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({super.key});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
    WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'onComplete',
        onMessageReceived: (JavaScriptMessage message) {
          // --- 수정된 부분: JSON 데이터 파싱 ---
          // 웹뷰로부터 전달받은 JSON 형식의 문자열을
          // Dart의 Map<String, dynamic> 형태로 변환합니다.
          final result = jsonDecode(message.message) as Map<String, dynamic>;

          // 파싱된 Map 데이터를 가지고 이전 화면으로 돌아갑니다.
          Navigator.of(context).pop(result);
        },
      )
      ..loadRequest(Uri.parse(
          'https://jechang-yeon.github.io/carelink_postcode/postcode.html'));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주소 검색'),
        backgroundColor: const Color(0xFF4A4A4A),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}