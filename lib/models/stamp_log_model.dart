import 'package:cloud_firestore/cloud_firestore.dart';

class StampLog {
  final String stampId;
  final String userId;
  final String scheduleId;
  final DateTime cdatetime;

  StampLog({
    required this.stampId,
    required this.userId,
    required this.scheduleId,
    required this.cdatetime,
  });

  factory StampLog.fromMap(Map<String, dynamic> map, String docId) {
    return StampLog(
      stampId: docId,
      userId: map['user_id'] ?? '',
      scheduleId: map['schedule_id'] ?? '',
      cdatetime: (map['cdatetime'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'schedule_id': scheduleId,
      'cdatetime': cdatetime,
    };
  }
}