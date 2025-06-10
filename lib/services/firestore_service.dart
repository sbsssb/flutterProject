import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';

class FirestoreService {
  static Future<List<Schedule>> getSchedules(String roomId) async {

    final snapshot = await FirebaseFirestore.instance
        .collection('travel_rooms')
        .doc(roomId)
        .collection('schedules')
        .get();

    return snapshot.docs
        .map((doc) => Schedule.fromMap(doc.data(), doc.id))
        .toList();
  }
}
