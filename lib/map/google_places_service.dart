import 'dart:convert';
import 'package:http/http.dart' as http;

/// ✅ 신버전 Google Places API v1을 이용한 좌표 보정 함수
Future<Map<String, double>?> getLatLngFromPlaceNameV1({
  required String query,
  required String apiKey,
}) async {
  final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': 'places.displayName,places.location',
    },
    body: jsonEncode({
      'textQuery': query,
    }),
  );

  final data = jsonDecode(response.body);

  if (data['places'] != null && data['places'].isNotEmpty) {
    final location = data['places'][0]['location'];
    return {
      'lat': location['latitude'],
      'lng': location['longitude'],
    };
  }

  print("❌ 장소 못 찾음 → $query\n응답: ${response.body}");
  return null;
}


Future<List<Map<String, dynamic>>> correctScheduleListWithGoogleMaps({
  required List<Map<String, dynamic>> rawList,
  required String googleApiKey,
  required String region,
  required String subRegion,
}) async {
  final corrected = await Future.wait(
    rawList.map((item) async {
      final placeName = item['place_name'] ?? '';
      final address = item['address'] ?? '';
      final query = '$region $subRegion $placeName $address';

      final fixed = await getLatLngFromPlaceNameV1(
        query: query,
        apiKey: googleApiKey,
      );

      if (fixed != null) {
        return {
          ...item,
          'lat': fixed['lat'],
          'lng': fixed['lng'],
        };
      } else {
        print("❌ 보정 실패 → $query, 기존 lat/lng 유지");
        return item;
      }
    }),
  );

  return corrected;
}
