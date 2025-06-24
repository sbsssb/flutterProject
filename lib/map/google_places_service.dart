import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<Map<String, double>?> getLatLngFromPlaceName({
  required String placeName,
  required String? address, // nullable
  required String region,
  required String subRegion,
  required String googleApiKey,
}) async {
  // 주소 > 지역 + 장소명 > 장소명 순서로 검색
  final queries = [
    if (address != null && address.isNotEmpty) address,
    "$region $subRegion $placeName",
    placeName
  ];

  for (final query in queries) {
    final encodedPlace = Uri.encodeComponent(query);
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/findplacefromtext/json'
          '?input=$encodedPlace&inputtype=textquery&fields=geometry&key=$googleApiKey',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK' && data['candidates'].isNotEmpty) {
      final location = data['candidates'][0]['geometry']['location'];
      return {'lat': location['lat'], 'lng': location['lng']};
    }
  }

  print("❌ 장소 좌표 못 찾음: $placeName");
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
      final fixed = await getLatLngFromPlaceName(
        placeName: item['place_name'],
        address: item['address'], // 프롬프트에 포함된 주소
        region: region,
        subRegion: subRegion,
        googleApiKey: googleApiKey,
      );
      if (fixed != null) {
        return {
          ...item,
          'lat': fixed['lat'],
          'lng': fixed['lng'],
        };
      }
      return item;
    }),
  );
  return corrected;
}