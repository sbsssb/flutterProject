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
      itemCount: scheduleList.length + 1,
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (context, index) {
        // 마지막 index에 버튼 추가
        if (index == scheduleList.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 일정 추가 로직
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("일정 추가"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 일정 확정 로직
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("일정 확정"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final item = scheduleList[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // 삭제 로직 여기에 작성
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}