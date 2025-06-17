import 'dart:convert';
import 'package:http/http.dart' as http;
import 'festival_detail_model.dart';

class FestivalDetailApi {
  static const String baseUrl = 'https://apis.data.go.kr/B551011/KorService2';
  static const String serviceKey = 'loeUwCSiTrlZ4bpQbXtMWINqF8HpYF7hacafFPZr3tI7mjjoMKCIlpooX4QRBEu%2Ba8Ras0d%2B1zKF%2FN4NA2xiDA%3D%3D';

  static Future<FestivalDetail?> fetchFestivalDetail(String contentId, int contentTypeId) async {

    print('🛰️ 상세 API 요청 시작 - contentId: $contentId / type: $contentTypeId');

    try {
      final commonRes = await http.get(Uri.parse(
        '$baseUrl/detailCommon2'
        '?serviceKey=$serviceKey'
        '&contentId=$contentId'
        '&MobileOS=ETC'
        '&MobileApp=TestApp'
        '&_type=json',
      ));

      final introRes = await http.get(Uri.parse(
        '$baseUrl/detailIntro2?serviceKey=$serviceKey&contentId=$contentId&contentTypeId=$contentTypeId&MobileOS=ETC&MobileApp=TestApp&_type=json',
      ));

      final imageRes = await http.get(Uri.parse(
        '$baseUrl/detailImage2?serviceKey=$serviceKey&contentId=$contentId&MobileOS=ETC&MobileApp=TestApp&_type=json',
      ));

      final commonJson = json.decode(commonRes.body);
      final introJson = json.decode(introRes.body);
      final imageJson = json.decode(imageRes.body);

      print('📨 commonRes.body: ${commonRes.body}');
      print('📨 introRes.body: ${introRes.body}');
      print('📨 imageRes.body: ${imageRes.body}');

      final commonRaw = commonJson['response']?['body']?['items']?['item'];
      final introRaw = introJson['response']?['body']?['items']?['item'];
      final imageRaw = imageJson['response']?['body']?['items']?['item'];

      if (commonRaw == null) {
        print('❌ commonItem 없음');
        return null;
      }
      if (introRaw == null) {
        print('❌ introItem 없음');
      }

      final commonItem = (commonRaw is List) ? commonRaw[0] : commonRaw;
      final introItem = (introRaw is List) ? introRaw[0] : introRaw ?? {};

      List<String> imageUrls = [];
      if (imageRaw != null) {
        if (imageRaw is List) {
          imageUrls = imageRaw
              .map((e) => e['originimgurl'] as String? ?? '')
              .where((url) => url.isNotEmpty)
              .toList();
        } else if (imageRaw is Map) {
          final url = imageRaw['originimgurl'];
          if (url != null && url is String && url.isNotEmpty) {
            imageUrls = [url];
          }
        }
      }

      return FestivalDetail(
        title: commonItem['title'] ?? '',
        overview: commonItem['overview'] ?? '',
        address: commonItem['addr1'] ?? '',
        tel: commonItem['tel'] ?? '',
        homepage: commonItem['homepage'] ?? '',
        mapX: double.tryParse(commonItem['mapx'] ?? '') ?? 0.0,
        mapY: double.tryParse(commonItem['mapy'] ?? '') ?? 0.0,

        eventStartDate: introItem['eventstartdate'] ?? '',
        eventEndDate: introItem['eventenddate'] ?? '',
        eventPlace: introItem['eventplace'] ?? '',
        playTime: introItem['playtime'] ?? '',
        useTimeFestival: introItem['usetimefestival'] ?? '',
        sponsor: introItem['sponsor1'] ?? '',
        bookingPlace: introItem['bookingplace'] ?? '',
        discountInfoFestival: introItem['discountinfofestival'] ?? '',

        imageUrls: imageUrls,
      );
    } catch (e) {
      print('🧨 상세정보 가져오기 오류: $e');
      return null;
    }
  }
}