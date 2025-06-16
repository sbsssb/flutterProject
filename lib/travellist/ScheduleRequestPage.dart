import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../gemini/gemini_service.dart';
import 'ScheduleListPage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ScheduleRequestPage extends StatelessWidget {
  final String roomId;

  const ScheduleRequestPage({super.key, required this.roomId});

  Future<Map<String, dynamic>?> fetchTravelRoomData(String roomId) async {
    final doc = await FirebaseFirestore.instance.collection('travel_rooms').doc(roomId).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    // ✨ 이 값들은 나중에 사용자 입력 기반으로 변경 가능
    const region = '강원도';
    const subRegion = '강릉';
    const themes = ['맛집', '바다'];
    const transport = '자차';
    const date = '2025-06-13';

    return Scaffold(
      appBar: AppBar(title: const Text('일정 생성하기')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              final prompt = buildTravelPrompt(
                region: region,
                subRegion: subRegion,
                themes: themes,
                transport: transport,
                date: date,
              );

              final scheduleList = await fetchScheduleFromPrompt(
                prompt: prompt,
                apiKey: dotenv.env['GEMINI_API_KEY']!,
              );

              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleListPage(
                      roomId: roomId,
                      initialSchedules: scheduleList,
                      region: region,
                      subRegion: subRegion,
                      themes: themes,
                      transport: transport,
                      date: date,
                    ),
                  ),
                );
              }
            } catch (e) {
              print("에러 발생: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("일정 생성 중 오류가 발생했어요 🥲")),
              );
            }
          },
          child: const Text('✈️ 일정 생성 요청'),
        ),
      ),
    );
  }
}
