import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 지도와 주소 검색을 위한 Google Maps 관련 기능을 제공합니다.
///
/// API 키는 런타임에 `--dart-define=GOOGLE_MAPS_API_KEY=...` 형태로
/// 주입하거나, 테스트 환경에서 [debugOverrideApiKey]를 통해 지정할 수 있습니다.
class MapService {
  MapService._();

  static const _googleKeyEnvName = 'GOOGLE_MAPS_API_KEY';

  static String? _googleMapsApiKeyOverride;

  /// 테스트나 위젯 데모에서 사용할 수 있도록 별도의 디버그 훅을 제공합니다.
  @visibleForTesting
  static void debugOverrideApiKey({String? googleMapsApiKey}) {
    _googleMapsApiKeyOverride = googleMapsApiKey?.trim();
  }

  static String? _readGoogleMapsKey() {
    final override = _googleMapsApiKeyOverride;
    if (override != null) {
      return override.isEmpty ? null : override;
    }
    const envValue = String.fromEnvironment(_googleKeyEnvName);
    return envValue.isEmpty ? null : envValue;
  }

  static Uri _buildGoogleUri(String path, Map<String, String> queryParameters) {
    return Uri.https('maps.googleapis.com', path, queryParameters);
  }

  /// 위도, 경도를 사용하여 Google Static Map URL을 생성합니다.
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

  /// Google Geocoding API를 사용해 주소를 좌표로 변환합니다.
  static Future<Map<String, double>?> getCoordinatesFromAddress(
      String address) async {
    final googleMapsApiKey = _readGoogleMapsKey();
    if (googleMapsApiKey == null) {
      debugPrint(
        '경고: $_googleKeyEnvName 값이 설정되지 않아 주소 변환을 건너뜁니다.',
      );
      return null;
    }

    final uri = _buildGoogleUri(
      '/maps/api/geocode/json',
      <String, String>{
        'address': address,
        'key': googleMapsApiKey,
        'language': 'ko',
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        debugPrint('주소 변환 API 응답 오류(${response.statusCode}): ${response.body}');
        return null;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final String status = (data['status'] as String?) ?? 'UNKNOWN';
      if (status != 'OK' || data['results'] == null) {
        debugPrint('주소 변환 API 상태: $status');
        return null;
      }

      final List<dynamic> results = data['results'] as List<dynamic>;
      if (results.isEmpty) {
        return null;
      }

      final Map<String, dynamic> geometry =
      results.first['geometry'] as Map<String, dynamic>;
      final Map<String, dynamic> location =
      geometry['location'] as Map<String, dynamic>;
      final double? lat = (location['lat'] as num?)?.toDouble();
      final double? lng = (location['lng'] as num?)?.toDouble();

      if (lat == null || lng == null) {
        return null;
      }

      return <String, double>{
        'latitude': lat,
        'longitude': lng,
      };
    } catch (e) {
      debugPrint('주소 변환 API 오류: $e');
      return null;
    }
  }

  /// Google Places Autocomplete API를 사용해 주소 검색 결과를 제공합니다.
  static Future<List<Map<String, String>>> searchAddressSuggestions(
      String query) async {
    final googleMapsApiKey = _readGoogleMapsKey();
    if (googleMapsApiKey == null) {
      debugPrint('경고: $_googleKeyEnvName 값이 설정되지 않아 주소 검색을 건너뜁니다.');
      return <Map<String, String>>[];
    }

    if (query.trim().isEmpty) {
      return <Map<String, String>>[];
    }

    final uri = _buildGoogleUri(
      '/maps/api/place/autocomplete/json',
      <String, String>{
        'input': query,
        'types': 'address',
        'language': 'ko',
        'key': googleMapsApiKey,
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        debugPrint('주소 검색 API 응답 오류(${response.statusCode}): ${response.body}');
        return <Map<String, String>>[];
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final String status = (data['status'] as String?) ?? 'UNKNOWN';
      if (status == 'ZERO_RESULTS') {
        return <Map<String, String>>[];
      }

      if (status != 'OK') {
        debugPrint('주소 검색 API 상태: $status / ${data['error_message'] ?? ''}');
        return <Map<String, String>>[];
      }

      final List<dynamic> predictions =
      (data['predictions'] as List<dynamic>? ?? <dynamic>[]);
      return predictions
          .map((dynamic item) => item as Map<String, dynamic>)
          .map(
            (Map<String, dynamic> item) => <String, String>{
          'description': (item['description'] as String?) ?? '',
          'placeId': (item['place_id'] as String?) ?? '',
        },
      )
          .where((Map<String, String> item) =>
      item['description']!.isNotEmpty && item['placeId']!.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('주소 검색 API 오류: $e');
      return <Map<String, String>>[];
    }
  }

  /// 선택된 장소의 상세 정보를 조회합니다.
  static Future<Map<String, dynamic>?> fetchPlaceDetail(String placeId) async {
    final googleMapsApiKey = _readGoogleMapsKey();
    if (googleMapsApiKey == null) {
      debugPrint('경고: $_googleKeyEnvName 값이 설정되지 않아 장소 상세 정보를 가져올 수 없습니다.');
      return null;
    }

    final uri = _buildGoogleUri(
      '/maps/api/place/details/json',
      <String, String>{
        'place_id': placeId,
        'fields': 'formatted_address,geometry/location',
        'language': 'ko',
        'key': googleMapsApiKey,
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        debugPrint('장소 상세 API 응답 오류(${response.statusCode}): ${response.body}');
        return null;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final String status = (data['status'] as String?) ?? 'UNKNOWN';
      if (status != 'OK') {
        debugPrint('장소 상세 API 상태: $status / ${data['error_message'] ?? ''}');
        return null;
      }

      final Map<String, dynamic>? result =
      data['result'] as Map<String, dynamic>?;
      if (result == null) {
        return null;
      }

      final Map<String, dynamic>? geometry =
      result['geometry'] as Map<String, dynamic>?;
      final Map<String, dynamic>? location =
      geometry?['location'] as Map<String, dynamic>?;

      final double? lat = (location?['lat'] as num?)?.toDouble();
      final double? lng = (location?['lng'] as num?)?.toDouble();
      final String? formattedAddress = result['formatted_address'] as String?;

      if (lat == null || lng == null || formattedAddress == null) {
        return null;
      }

      return <String, dynamic>{
        'address': formattedAddress,
        'latitude': lat,
        'longitude': lng,
        'placeId': placeId,
      };
    } catch (e) {
      debugPrint('장소 상세 API 오류: $e');
      return null;
    }
  }
}
