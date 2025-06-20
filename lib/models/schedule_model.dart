import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String placeName;
  final Timestamp start;
  bool isDone;
  bool canStamp;
  bool canStampAlreadyNoti = false;

  Schedule({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    required this.placeName,
    required this.isDone,
    required this.start,
    this.canStamp = false,
});
  factory Schedule.fromMap(Map<String, dynamic> map, String id) {
    final startRaw = map['start'];
    Timestamp startTimestamp;

    // String → Timestamp 변환
    if (startRaw is String) {
      final dateTime = DateTime.tryParse(startRaw);
      startTimestamp = dateTime != null
          ? Timestamp.fromDate(dateTime)
          : Timestamp.now(); // fallback
    } else if (startRaw is Timestamp) {
      startTimestamp = startRaw;
    } else {
      startTimestamp = Timestamp.now();
    }

    return Schedule(
      id: id,
      title: map['travel_title'] ?? '',
      description: map['description'] ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      placeName: map['place_name'] ?? '',
      isDone: map['is_done'] ?? false,
      start: startTimestamp,
    );
  }

}