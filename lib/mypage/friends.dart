import 'package:flutter/material.dart';
import 'appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const FriendsPage({super.key, required this.userData});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {

  bool isRequestMode = false; // ✅ 친구 요청 모드 여부
  final int _unreadCount = 2; // 알림 카운트 예시


//✅ 2. Firestore에서 친구 목록 불러오기
  List<Map<String, dynamic>> friendList = [];

  Future<void> loadFriends() async {
    final userId = widget.userData['user_id']; // 또는 uid
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .where('status', isEqualTo: 'accepted')
        .get();

    setState(() {
      friendList = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }


  //✅ 3. 친구 요청 모드: 사용자 리스트 + 요청 상태
  List<Map<String, dynamic>> allUsers = [];
  Set<String> pendingRequestIds = {};

  Future<void> loadAllUsers() async {
    final currentId = widget.userData['user_id'];

    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    setState(() {
      allUsers = snapshot.docs
          .where((doc) => doc.id != currentId)
          .map((doc) => {
        'id': doc.id,
        'nickname': doc['nickname'],
      })
          .toList();
    });

    // 친구 요청 중인 ID 가져오기
    final pendingSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentId)
        .collection('friends')
        .where('status', isEqualTo: 'pending')
        .get();

    setState(() {
      pendingRequestIds =
          pendingSnapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  //✅ 4. 친구 요청 버튼 처리
  Future<void> sendFriendRequest(String toUserId) async {
    final fromUserId = widget.userData['user_id'];

    await FirebaseFirestore.instance
        .collection('users')
        .doc(fromUserId)
        .collection('friends')
        .doc(toUserId)
        .set({
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(toUserId)
        .collection('friend_requests')
        .doc(fromUserId)
        .set({
      'status': 'pending',
      'sentAt': Timestamp.now(),
    });

    // UI 갱신
    await loadAllUsers();
  }

  String _getProfileImage({required Map<String, dynamic> friend}) {
    int count = friend['travel_success_count'] ?? 0;
    if (count >= 11) return 'assets/profile_gold.png';
    if (count >= 6) return 'assets/profile_silver.png';
    return 'assets/profile_bronze.png';
  }
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
              child: (isRequestMode ? allUsers.isEmpty : friendList.isEmpty)
                  ? Center(
                child: Text(
                  isRequestMode ? '조회되는 유저가 없습니다.' : '등록된 친구가 없습니다.',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: isRequestMode ? allUsers.length : friendList.length,
                itemBuilder: (context, index) {
                  final userId = isRequestMode
                      ? allUsers[index]['user_id']
                      : friendList[index]['user_id'];
                  final name = isRequestMode
                      ? allUsers[index]['nickname']
                      : friendList[index]['nickname'];
                  final isPending = pendingRequestIds.contains(userId);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Image.asset('assets/profile_gold.png', height: 80),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(name, style: const TextStyle(fontSize: 22)),
                        ),
                        if (isRequestMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isPending ? Colors.amber : Colors.transparent,
                              border: isPending
                                  ? null
                                  : Border.all(color: const Color(0xFF1E6FD9)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPending ? '요청 대기' : '친구 요청',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E6FD9),
                              ),
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E6FD9),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '취소',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
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
