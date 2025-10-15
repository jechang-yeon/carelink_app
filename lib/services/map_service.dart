import 'package:flutter/foundation.dart';

class MapService {
  // ⚠️ 중요: 여기에 발급받은 카카오 REST API 키를 붙여넣으세요!
  static const String kakaoRestApiKey = 'ee31084743290f3c43cb2761ff5d51f0';

  // 위도, 경도를 사용하여 카카오 Static Map URL을 생성하는 함수
  static String getStaticMapUrl({
    required double latitude,
    required double longitude,
    int width = 600,
    int height = 250,
  }) {
    if (kakaoRestApiKey == 'YOUR_KAKAO_REST_API_KEY') {
      debugPrint('경고: 카카오 REST API 키가 설정되지 않았습니다.');
      // 키가 없을 경우, 플레이스홀더 이미지를 반환
      return 'https://via.placeholder.com/${width}x$height.png?text=Map+API+Key+Needed';
    }

    final String url =
        'https://dapi.kakao.com/v2/staticmap?appkey=$kakaoRestApiKey&center=$latitude,$longitude&level=4&marker=true&marker=pos:$longitude,$latitude&width=$width&height=$height';
    return url;
  }
}