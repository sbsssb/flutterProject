import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../gemini/gemini_service.dart';
import '../map/google_places_service.dart';
import '../stamp/screens/stamp_detail_screen.dart';

class ScheduleList extends StatefulWidget {
  final List<Map<String, dynamic>> scheduleList;
  final String roomId;

  final String region;
  final String subRegion;
  final List<String> themes;
  final String transport;
  final String date;

  const ScheduleList({
    super.key,
    required this.scheduleList,
    required this.roomId,
    required this.region,
    required this.subRegion,
    required this.themes,
    required this.transport,
    required this.date,
  });

  @override
  State<ScheduleList> createState() => _ScheduleListState();
}

class _ScheduleListState extends State<ScheduleList> {
  late List<Map<String, dynamic>> schedules;
  final List<Map<String, String>> deletedTimeRanges = [];

  final DateTime baseStartTime = DateTime.parse("2025-06-20T09:00:00");
  final Duration unitDuration = const Duration(hours: 2);

  @override
  void initState() {
    super.initState();
    schedules = List<Map<String, dynamic>>.from(widget.scheduleList);
    updateScheduleTimes();
  }

  String formatTime(String dateTime) {
    final dt = DateTime.parse(dateTime);
    return DateFormat.Hm().format(dt);
  }

  void updateScheduleTimes() {
    for (int i = 0; i < schedules.length; i++) {
      final start = baseStartTime.add(unitDuration * i);
      final end = start.add(unitDuration);
      schedules[i]['start'] = start.toIso8601String();
      schedules[i]['end'] = end.toIso8601String();
    }
  }

  Future<void> saveToFirestore() async {
    final ref = FirebaseFirestore.instance
        .collection('travel_rooms')
        .doc(widget.roomId)
        .collection('schedules');

    final batch = FirebaseFirestore.instance.batch();

    // Google Maps API로 좌표 보정
    final correctedSchedules = await correctScheduleListWithGoogleMaps(
      rawList: schedules,
      googleApiKey: dotenv.env['GEMINI_API_KEY']!, // ✅ .env에 넣어둔 Google Maps 키
    );

    // 기존 일정 삭제
    final snapshot = await ref.get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    // 새 일정 저장
    for (final schedule in schedules) {
      batch.set(ref.doc(), {
        ...schedule,
        'created_at': Timestamp.now(),
      });
    }

    await batch.commit();
    print('✅ 일정 확정 및 저장 완료');
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      itemCount: schedules.length + 1,
      padding: const EdgeInsets.all(16),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = schedules.removeAt(oldIndex);
          schedules.insert(newIndex, item);
          updateScheduleTimes();
        });
      },
      itemBuilder: (context, index) {
        if (index == schedules.length) {
          return Padding(
            key: const ValueKey("button_row"),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (deletedTimeRanges.isEmpty) return;

                      final prompt = buildAddSchedulePrompt(
                        region: widget.region,
                        subRegion: widget.subRegion,
                        themes: widget.themes,
                        transport: widget.transport,
                        date: widget.date,
                        timeRanges: deletedTimeRanges,
                      );

                      final newSchedules = await fetchScheduleFromPrompt(
                        prompt: prompt,
                        apiKey: dotenv.env['GEMINI_API_KEY']!,
                      );

                      setState(() {
                        schedules.addAll(newSchedules);
                        deletedTimeRanges.clear();
                        updateScheduleTimes();
                      });
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
                    onPressed: () async {
                      await saveToFirestore();
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => StampDetailScreen(roomId: widget.roomId),)
                      );
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

        final item = schedules[index];
        return Card(
          key: ValueKey(item), // ReorderableListView에 필수
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 드래그 핸들 추가
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12.0, top: 4),
                    child: Icon(Icons.drag_handle, color: Colors.grey),
                  ),
                ),
                // 🔹 일정 정보
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
                // 🔹 삭제 버튼
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      deletedTimeRanges.add({
                        'start': item['start'],
                        'end': item['end'],
                      });
                      schedules.removeAt(index);
                      updateScheduleTimes();
                    });
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
