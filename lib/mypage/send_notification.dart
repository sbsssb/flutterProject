import 'package:cloud_firestore/cloud_firestore.dart';


Future<void> sendNotification({
  required String targetUserId,
  required String type,
  required String content,
  required String senderId,
  required String senderNickname,
  required String senderAvatarId,
  required int senderStampCount,
  String? roomId,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .collection('notifications')
        .add({
      'type': type,
      'content': content,
      'sender_id': senderId,
      'sender_nickname': senderNickname,
      'sender_avatarId': senderAvatarId,
      'sender_stampCount': senderStampCount,
      'cdatetime': Timestamp.now(),
      'is_read': false,
      if (type == 'stamp_log') 'room_id': roomId,
    });
  } catch (e) {

  }
}