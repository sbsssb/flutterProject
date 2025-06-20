import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'appbar.dart';
import 'package:flutterteam4/mypage/send_notification.dart'; // 네 구조에 맞게
import 'friends.dart'; // FriendsPage로 이동할 거야

class NotificationPage extends StatelessWidget {
  final String userId;

  const NotificationPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> notificationStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('is_read', isEqualTo: false) // ✅ 읽지 않은 알람만 보이게
        .orderBy('cdatetime', descending: true)
        .snapshots();

    return Scaffold(
      appBar: CustomAppBar(userId: userId),
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
                    Image.asset('assets/mypage_images/noti_message.png', height: 250),
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
                Center(child: Image.asset('assets/mypage_images/noti_message.png', height: 250)),
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

                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .collection('notifications')
                                  .doc(doc.id)
                                  .update({'is_read': true});

                              if (type == 'friend_request') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FriendsPage(
                                      userData: {'user_id': userId},
                                      initialTabIndex: 2, // 친구 요청 탭
                                    ),
                                  ),
                                );
                              } else if (type == 'friend_accept') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FriendsPage(
                                      userData: {'user_id': userId},
                                      initialTabIndex: 0, // 친구 목록 탭
                                    ),
                                  ),
                                );
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
                                  Image.asset('assets/mypage_images/profile_gold.png', height: 48),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            text: senderNickname,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown),
                                            children: [
                                              TextSpan(
                                                text: ' $content',
                                                style: const TextStyle(fontSize: 16, color: Colors.black),
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
                                            style: const TextStyle(fontSize: 12, color: Colors.brown),
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
                              child: const Icon(Icons.close, size: 18, color: Colors.brown),
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
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.grey),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.share), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
        onTap: (index) {
          // TODO: 페이지 전환 처리 (home, mypage 등)
        },
      ),
    );
  }
}