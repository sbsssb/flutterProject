// 기존 import 그대로 유지
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../gemini/gemini_service.dart';
import '../map/google_places_service.dart';
import '../stamp/screens/stamp_detail_screen.dart';
import 'package:go_router/go_router.dart';

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
  int addedCount = 0;
  int? _draggingIndex;

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

    final correctedSchedules = await correctScheduleListWithGoogleMaps(
      rawList: schedules,
      googleApiKey: dotenv.env['GOOGLE_MAPS_API_KEY']!,
      region: widget.region,
      subRegion: widget.subRegion,
    );

    print("✅ 보정된 일정:");
    for (final schedule in correctedSchedules) {
      print("📍 ${schedule['place_name']} | 위도: ${schedule['lat']}, 경도: ${schedule['lng']}");
    }

    final snapshot = await ref.get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    for (final schedule in correctedSchedules) {
      batch.set(ref.doc(), {
        ...schedule,
        'created_at': Timestamp.now(),
      });
    }

    await batch.commit();
    print('✅ 일정 확정 및 저장 완료');
  }

  Widget _buildScheduleCard(Map<String, dynamic> item, int index, {bool isDragging = false}) {
    return Card(
      key: ValueKey(item),
      elevation: isDragging ? 6 : 3,
      color: isDragging ? const Color(0xFFFFF3CD) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(right: 12.0, top: 4),
                child: Icon(Icons.drag_handle, color: Colors.grey),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['travel_title'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Jalnan',
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${formatTime(item['start'])} ~ ${formatTime(item['end'])}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "📍 ${item['place_name']}",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'AstaSans',
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['description'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'AstaSans',
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      itemCount: schedules.length + 1,
      padding: const EdgeInsets.all(16),
      onReorderStart: (index) => setState(() => _draggingIndex = index),
      onReorderEnd: (index) => setState(() => _draggingIndex = null),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = schedules.removeAt(oldIndex);
          schedules.insert(newIndex, item);
          updateScheduleTimes();
        });
      },
      proxyDecorator: (child, index, animation) {
        return _buildScheduleCard(schedules[index], index, isDragging: true);
      },
      itemBuilder: (context, index) {
        if (index == schedules.length) {
          return Padding(
            key: const ValueKey("button_row"),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (deletedTimeRanges.isEmpty) return;
                      if (addedCount >= 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("⛔ 일정은 최대 3번까지만 추가할 수 있어요!")),
                        );
                        return;
                      }

                      final prompt = buildAddSchedulePrompt(
                        region: widget.region,
                        subRegion: widget.subRegion,
                        themes: widget.themes,
                        transport: widget.transport,
                        date: widget.date,
                        timeRanges: deletedTimeRanges,
                        existingSchedules: schedules,
                      );

                      final newSchedules = await fetchScheduleFromPrompt(
                        prompt: prompt,
                        apiKey: dotenv.env['GEMINI_API_KEY']!,
                      );

                      setState(() {
                        schedules.addAll(newSchedules);
                        deletedTimeRanges.clear();
                        updateScheduleTimes();
                        addedCount += 1;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFACC15),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                        fontFamily: 'Jalnan',
                        fontSize: 17,
                      ),
                    ),
                    child: const Text("일정 추가"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await saveToFirestore();
                      context.go('/stamp?roomId=${widget.roomId}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6FD9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                        fontFamily: 'Jalnan',
                        fontSize: 17,
                      ),
                    ),
                    child: const Text("일정 확정"),
                  ),
                ),
              ],
            ),
          );
        }

        return _buildScheduleCard(schedules[index], index);
      },
    );
  }
}
