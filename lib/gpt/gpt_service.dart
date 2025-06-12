import 'dart:convert';
import 'package:http/http.dart' as http;

String buildTravelPrompt({
  required String region,
  required String subRegion,
  required List<String> themes,
  required String transport,
  required String date,
}) {
  final themeList = themes.join(', ');
  return '''
한국 $region $subRegion에서 여행 일정을 짜줘.
테마는 "$themeList"이고, 교통수단은 "$transport"야.
오전 9시부터 오후 6시까지 하루 일정으로,
장소 이름, 간단한 설명, 위도와 경도, 시작 시간과 종료 시간 형식으로 알려줘.
총 5개의 일정을 제안해 줘.
응답은 반드시 JSON 배열 형식으로 주고, 각 객체는 다음 필드를 포함해야 해:

- travel_title
- description
- place_name
- lat
- lng
- start (예: 2025-06-13T09:00:00)
- end (예: 2025-06-13T10:30:00)

JSON 외에는 아무 말도 하지 마.
''';
}

Future<List<Map<String, dynamic>>> fetchGeminiSchedule({
  required String region,
  required String subRegion,
  required List<String> themes,
  required String transport,
  required String date,
  required String apiKey,  // 👉 Gemini API 키
}) async {
  final prompt = buildTravelPrompt(
    region: region,
    subRegion: subRegion,
    themes: themes,
    transport: transport,
    date: date,
  );

  final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/chat-bison:generateContent?key=$apiKey');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    }),
  );
  print(response.body);

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    final content = decoded['candidates'][0]['content']['parts'][0]['text'];

    try {
      final parsed = jsonDecode(content);
      return List<Map<String, dynamic>>.from(parsed);
    } catch (e) {
      throw Exception("JSON 파싱 실패 ❌\n응답 내용: $content");
    }
  } else {
    throw Exception('Gemini 요청 실패: ${response.body}');
  }
}