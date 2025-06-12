import 'package:flutter/material.dart';
import 'appbar.dart';

void main() {
  runApp(const MaterialApp(
    home: FriendsPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  bool isRequestMode = false; // ✅ 친구 요청 모드 여부
  final int _unreadCount = 2; // 알림 카운트 예시

  // ✅ 예시 친구 리스트
  final List<String> friends = ['친구 1', '친구 2', '친구 3'];
  final List<String> usersToRequest = ['친구 1', '친구 2'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        unreadCount: _unreadCount,
        onNotificationTap: () {},
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              isRequestMode ? '친구할 유저 검색' : '친구 검색',
              style: const TextStyle(fontSize: 14, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: '친구 이름을 검색하세요',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: isRequestMode ? usersToRequest.length : friends.length,
                itemBuilder: (context, index) {
                  final name = isRequestMode ? usersToRequest[index] : friends[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Image.asset('assets/profile_icon.png', height: 80),
                        const SizedBox(width: 16),
                        Expanded(child: Text(name, style: const TextStyle(fontSize: 22))),
                        if (isRequestMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: index == 1 ? Colors.amber : Colors.transparent,
                              border: index != 1
                                  ? Border.all(color: const Color(0xFF1E6FD9))
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              index == 1 ? '요청 대기' : '친구 요청',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: index == 1 ? const Color(0xFF1E6FD9) : const Color(0xFF1E6FD9),
                              ),
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E6FD9),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('취소',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // ✅ 하단 스위치 버튼 → 하단 고정 버튼 2개로 변경
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => setState(() => isRequestMode = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: !isRequestMode ? const Color(0xFF1E6FD9) : Colors.grey.shade300,
                foregroundColor: !isRequestMode ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('친구 목록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => setState(() => isRequestMode = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isRequestMode ? const Color(0xFF1E6FD9) : Colors.grey.shade300,
                foregroundColor: isRequestMode ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('친구 추가',style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
