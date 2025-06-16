import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

// 일정 첫 추가
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
오전 9시부터 오후 6시까지 하루 일정으로, 겹치지 않게
장소 이름, 간단한 설명(간단한 한 문장, ~한 시간/~한 식사/~한 여행 같은 형식으로), 위도와 경도, 시작 시간과 종료 시간 형식으로 알려줘.
총 5개의 일정을 제안해 줘.
응답은 반드시 JSON 배열 형식으로 주고, 각 객체는 다음 필드를 포함해야 해:

- travel_title
- description
- place_name
- lat
- lng
- start (예: ${date}T09:00:00)
- end (예: ${date}T10:30:00)

응답은 반드시 JSON 배열 형식으로 주되, ``` 같은 마크다운 형식은 절대 포함하지 마.
''';
}

// 일정 추가 생성
String buildAddSchedulePrompt({
  required String region,
  required String subRegion,
  required List<String> themes,
  required String transport,
  required String date,
  required List<Map<String, String>> timeRanges,
}) {
  final themeList = themes.join(', ');
  final timeList = timeRanges.map((range) {
    return "- ${range['start']} ~ ${range['end']}";
  }).join('\n');

  return '''
한국 $region $subRegion에서 여행 일정을 추가로 제안해 줘.
테마는 "$themeList"이고, 교통수단은 "$transport"야.

기존 일정 외에 추가로 아래 시간대만 사용할 수 있어:
$timeList

각 시간대에 적절한 장소와 설명을 포함해서 추천해 줘.
장소 이름, 간단한 설명(간단한 한 문장, ~한 시간/~한 식사/~한 여행 같은 형식으로), 위도와 경도, 시작 시간과 종료 시간 형식으로 알려줘.
앞서 추천했던 곳은 제외하고 겹치지 않게 해 줘야 해.
응답은 반드시 JSON 배열 형식으로 주고, 각 객체는 다음 필드를 포함해야 해:

- travel_title
- description
- place_name
- lat
- lng
- start (예: ${date}T13:00:00)
- end (예: ${date}T14:00:00)

응답은 반드시 JSON 배열 형식으로 주고, 마크다운(예: ```json)은 절대 포함하지 마.
''';
}


Future<List<Map<String, dynamic>>> fetchScheduleFromPrompt({
  required String prompt,
  required String apiKey,
}) async {
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  final chat = model.startChat();

  final response = await chat.sendMessage(Content.text(prompt));
  final content = response.text;
  if (content == null) throw Exception("응답이 비어 있음 ❌");

  try {
    final cleaned = content
        .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s*```$', multiLine: true), '');
    final parsed = jsonDecode(cleaned);
    return List<Map<String, dynamic>>.from(parsed);
  } catch (e) {
    throw Exception("JSON 파싱 실패 ❌\n응답 내용: $content");
  }
}