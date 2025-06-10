import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutterteam4/utils/test.dart'; // 네가 UploadTestPage 만든 파일명에 맞게 경로 수정
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '지역 업로더',
      home: const UploadTestPage(), // UploadTestPage를 홈으로 설정
    );
  }
}
