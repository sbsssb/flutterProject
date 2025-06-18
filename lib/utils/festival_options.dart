import '../festival/festival_model.dart';

List<String> generateDateOptions({int months = 6}) {
  final now = DateTime.now();
  return List.generate(months, (i) {
    final next = DateTime(now.year, now.month + i);
    return '${next.year}${next.month.toString().padLeft(2, '0')}01';
  });
}

Map<String, String> regionOptions = {
  '지역': '',
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

Map<String, String> categoryOptions = {
  '카테고리': '',
  '문화관광축제': 'A02070100',
  '일반축제': 'A02070200',
  '전통공연': 'A02080100',
  '전시회': 'A02080500',
  '박람회': 'A02080600',
  '대중콘서트': 'A02081000',
  '스포츠행사': 'A02081200',
  '기타행사': 'A02081300',
};

List<String> themeOptions = ['카테고리'];

List<Festival> filterFestivalsByCat3(List<Festival> festivals, String selectedCat3) {
  if (selectedCat3.isEmpty || selectedCat3 == '카테고리') return festivals;
  return festivals.where((festival) => festival.cat3 == selectedCat3).toList();
}