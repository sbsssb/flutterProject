import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleList extends StatelessWidget {
  final List<Map<String, dynamic>> scheduleList;

  const ScheduleList({super.key, required this.scheduleList});

  String formatTime(String dateTime) {
    final dt = DateTime.parse(dateTime);
    return DateFormat.Hm().format(dt); // 예: 09:00
  }

  @override
  Widget build(BuildContext context) {
    if (scheduleList.isEmpty) {
      return const Center(child: Text("생성된 일정이 없습니다."));
    }

    return ListView.separated(
      itemCount: scheduleList.length,
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final item = scheduleList[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['travel_title'] ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "${formatTime(item['start'])} ~ ${formatTime(item['end'])}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text("📍 ${item['place_name']}"),
                const SizedBox(height: 6),
                Text(item['description'] ?? ''),
              ],
            ),
          ),
        );
      },
    );
  }
}