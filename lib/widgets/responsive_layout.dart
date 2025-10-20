import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget desktopBody;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    required this.desktopBody,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 너비가 600px보다 크면 데스크탑용 UI를,
        // 그렇지 않으면 모바일용 UI를 보여줍니다.
        if (constraints.maxWidth > 600) {
          return desktopBody;
        } else {
          return mobileBody;
        }
      },
    );
  }
}