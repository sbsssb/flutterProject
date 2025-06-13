// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
//
// import 'user/signup_page.dart';
// // test 끝나면 삭제하자
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//
//   // 👇 카카오 SDK 초기화 (네이티브 앱 키 입력!)
//   KakaoSdk.init(nativeAppKey: '761f0c756c4d5d74c3bbb04de091d33f');
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: const SignUpPage(),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

Future<void> fetchFestivalList() async {
  const String serviceKey = 'loeUwCSiTrlZ4bpQbXtMWINqF8HpYF7hacafFPZr3tI7mjjoMKCIlpooX4QRBEu%2Ba8Ras0d%2B1zKF%2FN4NA2xiDA%3D%3D';
  final url = Uri.parse(
    'https://apis.data.go.kr/B551011/KorService/searchFestival'
        '?serviceKey=$serviceKey'
        '&numOfRows=10'
        '&pageNo=1'
        '&MobileOS=ETC'
        '&MobileApp=TestApp'
        '&_type=json',
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    final items = jsonData['response']['body']['items']['item'];

    if (items != null) {
      for (var item in items) {
        final title = item['title'];
        final startDate = item['eventstartdate'];
        print('축제명: $title, 시작일: $startDate');
      }
    } else {
      print('데이터가 없어요.');
    }
  } else {
    print('API 요청 실패: ${response.statusCode}');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 앱 실행 시 호출 테스트 (디버그 용도)
    fetchFestivalList();

    return MaterialApp(
      title: 'Festival App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Festival Test'),
        ),
        body: const Center(
          child: Text('축제 리스트를 확인하세요 (콘솔 로그)!'),
        ),
      ),
    );
  }
}

