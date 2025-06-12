import 'package:flutter/material.dart';
import '../gpt/gpt_service.dart';
import 'ScheduleListPage.dart'; // ⬅️ 방금 만든 페이지 import

class ScheduleRequestPage extends StatelessWidget {
  const ScheduleRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('일정 생성하기')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              final scheduleList = await fetchGeminiSchedule(
                region: '강원도',
                subRegion: '강릉',
                themes: ['맛집', '바다'],
                transport: '자차',
                date: '2025-06-13',
                apiKey: 'AIzaSyBCV3ZupC2uVhVwT4iiKu44Gr6-HYbFYsI',
              );

              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleListPage(scheduleList: scheduleList),
                  ),
                );
              }
            } catch (e) {
              print("에러 발생: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("일정 생성 중 오류가 발생했어요 🥲")),
              );
            }
          },
          child: const Text('✈️ 일정 생성 요청'),
        ),
      ),
    );
  }
}
