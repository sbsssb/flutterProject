import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/schedule_model.dart';
import '../../models/stamp_log_model.dart';
import '../../mypage/send_notification.dart';

class FirestoreService {
  // 스케줄 받아오기
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

  // 스탬프 찍기 기록 저장
  static Future<void> addStampLog({
    required String roomId,
    required StampLog log,
  }) async {
    // 🔸 1. 로그 저장
    await FirebaseFirestore.instance
        .collection('travel_rooms')
        .doc(roomId)
        .collection('stamp_logs')
        .doc(log.stampId)
        .set(log.toMap());

    // 🔸 2. 사용자 정보 조회 (닉네임, 아바타, 스탬프 수 등 알림에 필요한 정보)
    final userProfile = await getUserProfile(log.userId);
    if (userProfile == null) return;

    final userNickname = userProfile['nickname'] ?? '사용자';
    final userAvatarId = userProfile['avatar_id'] ?? 'default';
    final userStampCount = userProfile['stamp_count'] ?? 0;

    // 🔸 3. 알림 전송
    await sendNotification(
      targetUserId: log.userId,
      type: 'stamp_log', // ✅ 새 타입
      content: '새로운 스탬프가 적립되었어요!',
      senderId: log.userId,
      senderNickname: userNickname,
      senderAvatarId: userAvatarId,
      senderStampCount: userStampCount,
      roomId: roomId,
    );
  }

  // 일정 완료 처리
  static Future<void> markScheduleDone({
    required String roomId,
    required String scheduleId,
  }) async {
    await FirebaseFirestore.instance
        .collection('travel_rooms')
        .doc(roomId)
        .collection('schedules')
        .doc(scheduleId)
        .update({'is_done': true});
  }

  // ✅ 사용자 프로필 가져오기 (닉네임, 아바타, 스탬프 수용)
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print('❌ 사용자 프로필 가져오기 실패: $e');
    }
    return null;
  }
}