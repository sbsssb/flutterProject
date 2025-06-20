import 'dart:convert';
import 'package:http/http.dart' as http;
import 'festival_model.dart';

Future<List<Festival>> fetchFestivals({
  int page = 1,
  int numOfRows = 10,
  String areaCode = '',
  String eventStartDate = '',
  String eventEndDate = '',
  String cat3 = '',
}) async {
  const String serviceKey = 'loeUwCSiTrlZ4bpQbXtMWINqF8HpYF7hacafFPZr3tI7mjjoMKCIlpooX4QRBEu+a8Ras0d+1zKF/N4NA2xiDA==';

  final baseUrl = 'https://apis.data.go.kr/B551011/KorService2/searchFestival2';

  final queryParameters = {
    'serviceKey': serviceKey,
    'MobileOS': 'ETC',
    'MobileApp': 'TestApp',
    '_type': 'json',
    'numOfRows': '$numOfRows',
    'pageNo': '$page',
    if (areaCode.isNotEmpty) 'areaCode': areaCode,
    if (eventStartDate.isNotEmpty) 'eventStartDate': eventStartDate,
    if (eventEndDate.isNotEmpty) 'eventEndDate': eventEndDate,
    if (cat3.isNotEmpty) 'cat3': cat3,
  };

  final uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);

  final response = await http.get(uri);

  // print(uri.toString());
  // print('응답 바디: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final body = data['response']['body'];

    final items = body['items'];

    if (items == null || items is String) {
      return [];
    }

    final item = items['item'];

    if (item is List) {
      return item.map((e) => Festival.fromJson(e)).toList();
    } else if (item is Map) {
      return [Festival.fromJson(Map<String, dynamic>.from(item))];
    } else {
      return [];
    }
  } else {
    throw Exception('API 요청 실패: ${response.statusCode}');
  }
}
