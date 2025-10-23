import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 지도와 주소 변환에 필요한 API를 래핑한 서비스입니다.
///
/// 기존에는 코드에 직접 키를 하드코딩했으나, 보안을 위해
/// `--dart-define`을 통해 런타임에 주입하도록 변경했습니다.
/// 예) `flutter run --dart-define=GOOGLE_MAPS_API_KEY=... --dart-define=KAKAO_REST_API_KEY=...`
class MapService {
  MapService._();

  static const _googleKeyEnvName = 'GOOGLE_MAPS_API_KEY';
  static const _kakaoKeyEnvName = 'KAKAO_REST_API_KEY';

  static String? _googleMapsApiKeyOverride;
  static String? _kakaoRestApiKeyOverride;

  /// 테스트나 위젯 데모에서만 사용할 수 있도록 별도의 디버그 훅을 제공합니다.
  @visibleForTesting
  static void debugOverrideApiKeys({
    String? googleMapsApiKey,
    String? kakaoRestApiKey,
  }) {
    _googleMapsApiKeyOverride = googleMapsApiKey?.trim();
    _kakaoRestApiKeyOverride = kakaoRestApiKey?.trim();
  }

  static String? _readGoogleMapsKey() {
    final override = _googleMapsApiKeyOverride;
    if (override != null) {
      return override.isEmpty ? null : override;
    }
    const envValue = String.fromEnvironment(_googleKeyEnvName);
    return envValue.isEmpty ? null : envValue;
  }

  static String? _readKakaoRestKey() {
    final override = _kakaoRestApiKeyOverride;
    if (override != null) {
      return override.isEmpty ? null : override;
    }
    const envValue = String.fromEnvironment(_kakaoKeyEnvName);
    return envValue.isEmpty ? null : envValue;
  }

  /// 위도, 경도를 사용하여 Google Static Map URL을 생성하는 함수
  static String getStaticMapUrl({
    required double latitude,
    required double longitude,
    int width = 600,
    int height = 250,
  }) {
    final googleMapsApiKey = _readGoogleMapsKey();
    if (googleMapsApiKey == null) {
      debugPrint(
        '경고: $_googleKeyEnvName 값이 설정되지 않았습니다. placeholder 이미지를 반환합니다.',
      );
      return 'https://via.placeholder.com/${width}x$height.png?text=Map+API+Key+Needed';
    }

    final String url =
        'https://maps.googleapis.com/maps/api/staticmap?center=$latitude,$longitude&zoom=16&size=${width}x$height&markers=color:red%7C$latitude,$longitude&key=$googleMapsApiKey';
    return url;
  }

  ///주소를 좌표로 변환하는 기능은 카카오 API를 유지합니다.
  static Future<Map<String, double>?> getCoordinatesFromAddress(
      String address) async {
    final kakaoRestApiKey = _readKakaoRestKey();
    if (kakaoRestApiKey == null) {
      debugPrint(
        '경고: $_kakaoKeyEnvName 값이 설정되지 않아 주소 변환을 건너뜁니다.',
      );
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
      } else {
        debugPrint(
            '주소 변환 API 응답 오류(${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('주소 변환 API 오류: $e');
    }
    return null;
  }
}