import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔔 Firestore에 알림을 저장하는 함수
/// 사용자가 다른 사용자에게 친구 요청 / 수락 등의 알림을 전송할 때 사용
Future<void> sendNotification({
  required String targetUserId,        // 알림을 받는 사용자 UID
  required String type,                // 'friend_request', 'friend_accept' 등
  required String content,             // 알림 본문 (UI에 표시)
  required String senderId,            // 보낸 사용자 UID
  required String senderNickname,      // 보낸 사용자 닉네임
  required String senderAvatarId,      // 보낸 사용자 아바타 ID
}) async {
  try {
    final timestamp = Timestamp.now();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .collection('notifications')
        .add({
      'type': type,
      'content': content,
      'is_read': false,
      'cdatetime': timestamp,
      'sender_id': senderId,
      'sender_nickname': senderNickname,
      'sender_avatar_id': senderAvatarId,
    });

    print('✅ 알림 전송 완료 → $targetUserId');
  } catch (e) {
    print('❌ 알림 전송 실패: $e');
  }
}