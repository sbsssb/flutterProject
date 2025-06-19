import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<Map<String, double>?> getLatLngFromPlaceName(String placeName, String googleApiKey) async {
  final encodedPlace = Uri.encodeComponent(placeName);
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

  print("❌ 장소 좌표 못 찾음: $placeName");
  return null;
}

Future<List<Map<String, dynamic>>> correctScheduleListWithGoogleMaps({
  required List<Map<String, dynamic>> rawList,
  required String googleApiKey,
}) async {
  final corrected = await Future.wait(
    rawList.map((item) async {
      final fixed = await getLatLngFromPlaceName(item['place_name'], googleApiKey);
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
