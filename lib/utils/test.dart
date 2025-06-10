import 'package:flutter/material.dart';
import 'package:flutterteam4/utils/upload_region.dart';

class UploadTestPage extends StatelessWidget {
  const UploadTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('지역 데이터 업로드')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await uploadRegionSet();
            // 사용자에게 업로드 완료 알림
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Firestore 업로드 완료!')),
              );
            }
          },
          child: const Text('지역 데이터 업로드하기'),
        ),
      ),
    );
  }
}
