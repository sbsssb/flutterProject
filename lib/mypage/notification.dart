import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'appbar.dart';
import 'package:flutterteam4/mypage/send_notification.dart'; // 네 구조에 맞게
import 'friends.dart'; // FriendsPage로 이동할 거야
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
            .where('is_read', isEqualTo: false) // ✅ 읽지 않은 알람만 보이게
            .orderBy('cdatetime', descending: true)
            .snapshots();

    return Scaffold(
      // appBar: CustomAppBar(userId: userId),
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

                // ✅ 알림 리스트 표시
                Expanded(
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final doc = notifications[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final type = data['type'] ?? '';
                      final content = data['content'] ?? '';
                      final isRead = data['is_read'] ?? false;
                      final time = (data['cdatetime'] as Timestamp?)?.toDate();
                      final senderNickname = data['sender_nickname'] ?? '';
                      final stampCount =
                          data['sender_stampCount'] ?? 0; // ✅ stampCount 읽기
                      final avatarImagePath = getProfileImagePath(
                        stampCount,
                      ); // ✅ 경로 변환

                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              print('🟡 알림이 클릭되었습니다.');

                              // 초기값: 친구 목록 탭 (0)
                              int tabIndex = 0; // 기본값

                              if (type == 'friend_request') {
                                tabIndex = 2;
                                print('📨 친구 요청 알림');
                              } else if (type == 'friend_accept') {
                                tabIndex = 0;
                                print('✅ 친구 수락 알림');
                              } else if (type == 'stamp_log') {
                                final roomId = data['room_id'];
                                print('📍 스탬프 로그 알림 - roomId: $roomId');

                                if (roomId != null && context.mounted) {
                                  // ❗ GoRouter를 사용하는 경우 - context가 유효할 때 바로 이동
                                  context.go('/detail/$roomId');
                                  print('🟢 GoRouter로 /detail/$roomId 이동');
                                } else {
                                  print('🔴 roomId 없음 또는 context 비활성');
                                }

                                // 스탬프 로그는 FriendsPage 이동이 아니므로 여기서 return
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .collection('notifications')
                                    .doc(doc.id)
                                    .update({'is_read': true}).then((_) {
                                  print('🟢 Firestore 업데이트 완료 - is_read: true');
                                }).catchError((e) {
                                  print('🔴 Firestore 업데이트 실패: $e');
                                });

                                return; // ✅ 여기서 종료
                              }

                              // 친구 요청/수락 처리
                              if (tabIndex != null && context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      print('🟢 FriendsPage 이동 시작 - 탭: $tabIndex');
                                      return FriendsPage(
                                        userData: {'user_id': userId},
                                        initialTabIndex: tabIndex,
                                      );
                                    },
                                  ),
                                );

                                print('🟢 Navigator.push 실행 완료');

                                // Firestore 업데이트 (읽음 처리)
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .collection('notifications')
                                    .doc(doc.id)
                                    .update({'is_read': true}).then((_) {
                                  print('🟢 Firestore 업데이트 완료 - is_read: true');
                                }).catchError((e) {
                                  print('🔴 Firestore 업데이트 실패: $e');
                                });
                              }
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
                                            time != null
                                                ? "${time.year}.${time.month.toString().padLeft(2, '0')}.${time.day.toString().padLeft(2, '0')} "
                                                    "${time.hour}:${time.minute.toString().padLeft(2, '0')}"
                                                : '시간 없음',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.brown,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // ✅ 닫기 버튼 (알림 상자 우상단)
                          Positioned(
                            top: 4,
                            right: 8,
                            child: GestureDetector(
                              onTap: () async {
                                await FirebaseFirestore.instance
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
