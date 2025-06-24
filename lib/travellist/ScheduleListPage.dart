import 'package:flutter/material.dart';
import '../common/bottom_nav_bar.dart';
import 'ScheduleList.dart';

class ScheduleListPage extends StatelessWidget {
  final String roomId;
  final List<Map<String, dynamic>> initialSchedules;

  final String region;
  final String subRegion;
  final List<String> themes;
  final String transport;
  final String date;

  const ScheduleListPage({
    super.key,
    required this.roomId,
    required this.initialSchedules,
    required this.region,
    required this.subRegion,
    required this.themes,
    required this.transport,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: Image.asset(
                'assets/common_images/logo-main-ver1.png',
                height: 80,
              ),
            ),
            const SizedBox(height: 16),
            // 리스트는 아래 공간 전체를 차지하게
            Expanded(
              child: ScheduleList(
                scheduleList: initialSchedules,
                roomId: roomId,
                region: region,
                subRegion: subRegion,
                themes: themes,
                transport: transport,
                date: date,
              ),
            ),
          ],
        ),
      ),
    );
  }
}