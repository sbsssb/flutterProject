import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'appbar.dart';
import 'package:flutterteam4/mypage/send_notification.dart';
import 'friends.dart';
import 'profile_avatar.dart';
import '../common/bottom_nav_bar.dart';

class NotificationPage extends StatelessWidget {
  final String userId;

  const NotificationPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> notificationStream =
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('is_read', isEqualTo: false)
        .snapshots();

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/mypage_images/noti_message.png',
                      height: 250,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "알림이 없습니다.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Image.asset(
                    'assets/mypage_images/noti_message.png',
                    height: 250,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final doc = notifications[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final type = data['type'] ?? '';
                      final content = data['content'] ?? '';
                      final message = data['message'] ?? '';
                      final isRead = data['is_read'] ?? false;
                      final time = (data['timestamp'] ?? data['cdatetime']) as Timestamp?;
                      final timeValue = time?.toDate();
                      final senderNickname = data['sender_nickname'] ?? '';
                      final stampCount = data['sender_stampCount'] ?? 0;
                      final avatarImagePath = getProfileImagePath(stampCount);


                      if (type == 'invitation') {
                        final roomId = data['room_id'];
                        final stampCount = data['sender_stampCount'] ?? 0;
                        final avatarImagePath = getProfileImagePath(stampCount);

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('travel_rooms')
                              .doc(roomId)
                              .get(),
                          builder: (context, snapshot) {
                            String roomName = '알 수 없음';
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final roomData = snapshot.data!.data() as Map<String, dynamic>?;
                              roomName = roomData?['room_name'] ?? '이름 없음';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(avatarImagePath, height: 48),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('$roomName $message', style: const TextStyle(fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      timeValue != null
                                          ? "${timeValue.year}.${timeValue.month.toString().padLeft(2, '0')}.${timeValue.day.toString().padLeft(2, '0')} "
                                          "${timeValue.hour}:${timeValue.minute.toString().padLeft(2, '0')}"
                                          : '시간 없음',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () async {
                                          if (roomId == null) return;

                                          final roomDoc = await FirebaseFirestore.instance
                                              .collection('travel_rooms')
                                              .doc(roomId)
                                              .get();

                                          if (!roomDoc.exists) {
                                            if (context.mounted) {
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text("오류"),
                                                  content: const Text("해당 방이 존재하지 않습니다.\n이미 삭제되었을 수 있습니다."),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text("확인"),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(userId)
                                                .collection('notifications')
                                                .doc(doc.id)
                                                .update({'is_read': true});

                                            return;
                                          }


                                          context.go('/dice/$roomId');

                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .collection('notifications')
                                              .doc(doc.id)
                                              .update({'is_read': true});
                                        },
                                        child: const Text('수락'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .collection('notifications')
                                              .doc(doc.id)
                                              .update({'is_read': true});
                                        },
                                        child: const Text('거절'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }


                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              int tabIndex = 0;

                              if (type == 'friend_request') {
                                tabIndex = 2;
                              } else if (type == 'friend_accept') {
                                tabIndex = 0;
                              } else if (type == 'stamp_log') {
                                final roomId = data['room_id'];

                                if (roomId != null && context.mounted) {
                                  final roomDoc = await FirebaseFirestore.instance
                                      .collection('travel_rooms')
                                      .doc(roomId)
                                      .get();

                                  if (!roomDoc.exists) {
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("알림"),
                                          content: const Text("해당 방이 존재하지 않습니다."),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text("확인"),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(userId)
                                        .collection('notifications')
                                        .doc(doc.id)
                                        .update({'is_read': true});
                                    return;
                                  }

                                  context.go('/detail/$roomId');
                                }

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .collection('notifications')
                                    .doc(doc.id)
                                    .update({'is_read': true});
                                return;
                              }


                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FriendsPage(
                                      userData: {'user_id': userId},
                                      initialTabIndex: tabIndex,
                                    ),
                                  ),
                                );
                              }

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .collection('notifications')
                                  .doc(doc.id)
                                  .update({'is_read': true});
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(avatarImagePath, height: 48),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            text: senderNickname,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.brown,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: ' $content',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            timeValue != null
                                                ? "${timeValue.year}.${timeValue.month.toString().padLeft(2, '0')}.${timeValue.day.toString().padLeft(2, '0')} "
                                                "${timeValue.hour}:${timeValue.minute.toString().padLeft(2, '0')}"
                                                : '시간 없음',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .collection('notifications')
                                    .doc(doc.id)
                                    .update({'is_read': true});
                              },
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.brown,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}