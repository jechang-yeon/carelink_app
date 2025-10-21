import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MapService {
  // ⚠️ 여기에 Google Cloud에서 확인한 API 키를 붙여넣으세요!
  static const String googleMapsApiKey = 'AIzaSyCtGEWtUfJM3sK9uYwZ8fy0igt9egXTeLw';

  // ⚠️ 주소->좌표 변환을 위해 카카오 REST API 키도 필요합니다.
  static const String kakaoRestApiKey = 'ee31084743290f3c43cb2761ff5d51f0';

  // 위도, 경도를 사용하여 Google Static Map URL을 생성하는 함수
  static String getStaticMapUrl({
    required double latitude,
    required double longitude,
    int width = 600,
    int height = 250,
  }) {
    if (googleMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
      debugPrint('경고: Google Maps API 키가 설정되지 않았습니다.');
      return 'https://via.placeholder.com/${width}x$height.png?text=Map+API+Key+Needed';
    }

    final String url =
        'https://maps.googleapis.com/maps/api/staticmap?center=$latitude,$longitude&zoom=16&size=${width}x$height&markers=color:red%7C$latitude,$longitude&key=$googleMapsApiKey';
    return url;
  }

  // 주소를 좌표로 변환하는 기능은 카카오 API를 유지합니다.
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