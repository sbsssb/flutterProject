import 'package:flutter/material.dart';
import 'appbar.dart';
void main() {
  runApp(const MaterialApp(
    home: NotificationPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {
        'name': '친구 1',
        'message': '님께서 친구요청을 하셨습니다.',
        'time': '2025.06.10 pm 14:30',
        'showButtons': true,
      },
      {
        'name': '친구 2',
        'message': '님께서 방에 초대를 하셨습니다.',
        'time': '2025.06.10 pm 14:30',
        'showButtons': true,
      },
      {
        'name': '친구 3',
        'message': '님께서 친구를 수락하셨습니다.',
        'time': '2025.06.10 pm 14:30',
        'showButtons': false,
      },
    ];

    return Scaffold(
      appBar: buildAppBar(
        unreadCount: 1,
        onNotificationTap: () {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Center(child: Image.asset('assets/noti_message.png', height: 250)),
            const SizedBox(height: 16),

            // 🔽 알림 목록 반복
            for (final notification in notifications)
              Container(
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
                    // 🔸 프로필 이미지
                    Image.asset('assets/profile_gold.png', height: 48),

                    const SizedBox(width: 12),

                    // 🔸 메시지 + 버튼 + 시간
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 닉네임 + 메시지
                          RichText(
                            text: TextSpan(
                              text: notification['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown),
                              children: [
                                TextSpan(
                                  text: notification['message'],
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // 🔹 버튼 영역
                              if (notification['showButtons']) ...[
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E6FD9),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('수락'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('거절'),
                                ),
                              ],

                              const Spacer(),

                              // 🔹 시간은 항상 표시
                              Text(
                                notification['time'],
                                style: const TextStyle(fontSize: 12, color: Colors.brown),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 🔙 뒤로가기 버튼
            const Spacer(),
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.share), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
        onTap: (index) {
          // TODO: 페이지 전환 처리
        },
      ),
    );
  }
}