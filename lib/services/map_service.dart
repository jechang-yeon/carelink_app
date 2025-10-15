import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MapService {
  // ⚠️ 중요: 여기에 발급받은 카카오 REST API 키를 붙여넣으세요!
  static const String kakaoRestApiKey = 'YOUR_KAKAO_REST_API_KEY';

  static String getStaticMapUrl({
    required double latitude,
    required double longitude,
    int width = 600,
    int height = 250,
  }) {
    if (kakaoRestApiKey == 'YOUR_KAKAO_REST_API_KEY') {
      debugPrint('경고: 카카오 REST API 키가 설정되지 않았습니다.');
      return 'https://via.placeholder.com/${width}x$height.png?text=Map+API+Key+Needed';
    }

    final String url =
        'https://dapi.kakao.com/v2/staticmap?appkey=$kakaoRestApiKey&center=$latitude,$longitude&level=4&marker=true&marker=pos:$longitude,$latitude&width=$width&height=$height';
    return url;
  }

  // --- 추가된 함수: 주소를 좌표로 변환 (지오코딩) ---
  static Future<Map<String, double>?> getCoordinatesFromAddress(
      String address) async {
    if (kakaoRestApiKey == 'YOUR_KAKAO_REST_API_KEY') {
      debugPrint('경고: 카카오 REST API 키가 설정되지 않아 주소 변환을 건너뜁니다.');
      return null;
    }

    final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/address.json?query=${Uri.encodeComponent(address)}');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'KakaoAK $kakaoRestApiKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['documents'] != null && data['documents'].isNotEmpty) {
          final doc = data['documents'][0];
          // 위도(y), 경도(x)를 double 타입으로 반환
          return {
            'latitude': double.parse(doc['y']),
            'longitude': double.parse(doc['x']),
          };
        }
      }
    } catch (e) {
      debugPrint('주소 변환 API 오류: $e');
    }
    return null;
  }
}