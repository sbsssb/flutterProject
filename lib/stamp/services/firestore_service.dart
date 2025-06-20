import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/schedule_model.dart';
import '../../models/stamp_log_model.dart';

class FirestoreService {
  //스케줄 받아오기
  static Future<List<Schedule>> getSchedules(String roomId) async {

    final snapshot = await FirebaseFirestore.instance
        .collection('travel_rooms')
        .doc(roomId)
        .collection('schedules')
        .orderBy('start')
        .get();

    return snapshot.docs
        .map((doc) => Schedule.fromMap(doc.data(), doc.id))
        .toList();
  }
  //스탬프 찍기 기록 저장
  static Future<void> addStampLog({required String roomId, required StampLog log,}) async{
    await FirebaseFirestore.instance
        .collection('travel_rooms')
        .doc(roomId)
        .collection('stamp_logs')
        .doc(log.stampId)
        .set(log.toMap());
  }
  //일정 완료 처리
  static Future<void> markScheduleDone({required String roomId, required String scheduleId,}) async {
    await FirebaseFirestore.instance
        .collection('travel_rooms')
        .doc(roomId)
        .collection('schedules')
        .doc(scheduleId)
        .update({'is_done' : true});
  }
}
