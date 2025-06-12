import '../festival/festival_model.dart';

List<String> generateDateOptions({int months = 6}) {
  final now = DateTime.now();
  return List.generate(months, (i) {
    final next = DateTime(now.year, now.month + i);
    return '${next.year}${next.month.toString().padLeft(2, '0')}01';
  });
}

List<Festival> filterFestivalsByTheme(List<Festival> festivals, String selectedTheme) {
  if (selectedTheme.isEmpty || selectedTheme == '전체') return festivals;

  final keywords = themeKeywordMap[selectedTheme];
  if (keywords == null) return festivals;

  return festivals.where((festival) {
    final combinedText =
        '${festival.title} ${festival.description} ${festival.tags?.join(' ') ?? ''}';
    return keywords.any((keyword) => combinedText.contains(keyword));
  }).toList();
}

Map<String, String> regionOptions = {
  '전체': '',
  '서울': '1',
  '인천': '2',
  '대전': '3',
  '대구': '4',
  '광주': '5',
  '부산': '6',
  '울산': '7',
  '세종특별자치시': '8',
  '경기도': '31',
  '강원특별자치도': '32',
  '충청북도': '33',
  '충청남도': '34',
  '전라북도': '35',
  '전라남도': '36',
  '경상북도': '37',
  '경상남도': '38',
  '제주특별자치도': '39',
};

Map<String, List<String>> themeKeywordMap = {
  '여름': ['여름', '시원', '바다', '피서', '물놀이'],
  '야경': ['야경', '밤', '라이트', '빛', '불빛'],
  '야행': ['야행'],
  '전통문화': ['전통', '민속', '풍물', '문화재'],
  '문화예술': ['예술', '공연', '전시', '페스티벌', '뮤지컬'],
  '힐링': ['힐링', '자연', '쉼', '휴식', '산책'],
};

List<String> themeOptions = ['전체', ...themeKeywordMap.keys];