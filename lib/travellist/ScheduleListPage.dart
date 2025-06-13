import 'package:flutter/material.dart';
import 'ScheduleList.dart'; // 너의 ScheduleList 위젯 import

class ScheduleListPage extends StatelessWidget {
  final List<Map<String, dynamic>> scheduleList;

  const ScheduleListPage({super.key, required this.scheduleList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📅 생성된 일정')),
      body: ScheduleList(scheduleList: scheduleList),
    );
  }
}
