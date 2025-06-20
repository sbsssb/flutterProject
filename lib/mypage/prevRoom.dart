import 'package:flutter/material.dart';
import 'appbar.dart';



class PrevRoomApp extends StatelessWidget {
  const PrevRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PrevRoomIn(),
    );
  }
}

class PrevRoomIn extends StatefulWidget {
  const PrevRoomIn({super.key});

  @override
  State<PrevRoomIn> createState() => _PrevRoomInState();
}

class _PrevRoomInState extends State<PrevRoomIn> {
  int _unreadCount = 3; // 실시간 알림 수 (예시 값)

  // 🔹 방 2개 추가하여 총 6개로 구성
  final List<Map<String, dynamic>> travelRooms = [
    {'title': '부산 여행', 'members': 3},
    {'title': '전주 여행', 'members': 1},
    {'title': '제주 여행', 'members': 2},
    {'title': '강원도 여행', 'members': 3},
    {'title': '속초 여행', 'members': 2}, // 🔹 추가된 방
    {'title': '광주 여행', 'members': 4}, // 🔹 추가된 방
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: CustomAppBar(userId: userId),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이전 여행',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1E6FD9)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: travelRooms.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final room = travelRooms[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF1E6FD9)),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(room['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('참여인원 : ${room['members']}명'),
                          const Spacer(),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: 상세 페이지 이동 처리
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text('이동'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_left)),
                  for (int i = 1; i <= 3; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          shape: const CircleBorder(),
                          side: const BorderSide(color: Colors.blue),
                        ),
                        child: Text('$i'),
                      ),
                    ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_right)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.share), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
        onTap: (index) {
          // TODO: 화면 전환 처리
        },
      ),
    );
  }
}
