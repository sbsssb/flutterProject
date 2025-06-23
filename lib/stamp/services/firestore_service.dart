import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/schedule_model.dart';
import '../../models/stamp_log_model.dart';
import '../screens/stamp_detail_screen.dart';

class FirestoreService {
  //
  static Future<ScheduleResult> getScheduleResult(String roomId) async {
    final roomRef = FirebaseFirestore.instance.collection('travel_rooms').doc(roomId);

    final roomDoc = await roomRef.get();
    final isTripDone = roomDoc.data()?['is_done'] ?? false;

    final scheduleSnap = await roomRef.collection('schedules').orderBy('start').get();
    final schedules = scheduleSnap.docs.map((doc) => Schedule.fromMap(doc.data(), doc.id)).toList();

    return ScheduleResult(isTripDone: isTripDone, schedules: schedules);
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
