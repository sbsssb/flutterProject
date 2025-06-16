// 🔁 친구 목록 페이지 - 전체 파일 (수정 반영 완료)
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
  int selectedTab = 0; // 0: 친구 목록, 1: 친구 추가, 2: 요청 수락
  final int _unreadCount = 2;
  List<Map<String, dynamic>> friendList = [];
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> pendingRequests = [];
  List<String> pendingRequestIds = [];

  @override
  void initState() {
    super.initState();
    initFriendData();
  }

  Future<void> initFriendData() async {
    await fetchFriends();
    await fetchAllUsers();
    fetchPendingRequests();
  }

  Future<void> fetchFriends() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userData['user_id'])
        .collection('friends')
        .where('status', isEqualTo: 'accepted')
        .get();

    List<Map<String, dynamic>> fetchedFriends = [];

    for (var doc in snapshot.docs) {
      final friendData = doc.data();
      final friendUserId = friendData['user_id'];

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendUserId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          fetchedFriends.add({
            'user_id': friendUserId,
            'nickname': userData['nickname'] ?? '',
            'avatar_id': userData['avatar_id'] ?? '',
          });
        }
      } catch (e) {
        debugPrint('친구 정보 불러오기 실패: $e');
      }
    }

    setState(() {
      friendList = fetchedFriends;
    });
  }

  Future<void> fetchAllUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final friendIds = friendList.map((f) => f['user_id']).toSet();

    List<Map<String, dynamic>> fetchedAllUsers = [];

    for (var doc in snapshot.docs) {
      final userId = doc.id;
      if (userId == widget.userData['user_id'] || friendIds.contains(userId)) continue;

      final data = doc.data();
      fetchedAllUsers.add({
        'user_id': userId,
        'nickname': data['nickname'] ?? '',
        'avatar_id': data['avatar_id'] ?? '',
      });
    }

    setState(() {
      allUsers = fetchedAllUsers;
    });
  }

  Future<void> fetchPendingRequests() async {
    final currentUserId = widget.userData['user_id'];
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .where('status', isEqualTo: 'pending')
        .get();

    setState(() {
      pendingRequests = snapshot.docs.map((doc) {
        final data = doc.data();
        data['friend_user_id'] = doc.id;

        // ✅ 받은 요청인지 확인
        // data['is_incoming'] = data['user_id'] == doc.id;
        data['is_incoming'] = data['user_id'] != widget.userData['user_id'];

        return data;
      }).toList();

      pendingRequestIds =
          pendingRequests.map<String>((f) => f['user_id'] as String).toList();
    });
  }

  Future<void> sendFriendRequest(String targetUserId, String targetNickname) async {
    final currentUserId = widget.userData['user_id'];
    final currentNickname = widget.userData['nickname'] ?? '';
    final avatarId = widget.userData['avatar_id'] ?? 'default_avatar';
    final timestamp = Timestamp.now();

    try {
      // 🔹 1. 상대방 friends 컬렉션에 "내 정보" 저장 (요청을 받은 사람이 수락할 수 있도록)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('friends')
          .doc(currentUserId)
          .set({
        'user_id': currentUserId,              // ✅ 내가 요청한 사람
        'nickname': currentNickname,
        'avatar_id': avatarId,
        'status': 'pending',
        'request_message': '같이 여행 가자!',
        'cdatetime': timestamp,
      });

      // 🔹 2. 내 friends 컬렉션에 "상대방 정보" 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(targetUserId)
          .set({
        'user_id': targetUserId,              // ✅ 내가 요청한 대상
        'nickname': targetNickname,
        'avatar_id': 'default_avatar',
        'status': 'pending',
        'request_message': '',
        'cdatetime': timestamp,
      });

      await fetchPendingRequests();
      await fetchAllUsers();
      setState(() {});
    } catch (e) {
      print('친구 요청 실패: $e');
    }
  }

  Future<void> acceptFriendRequest(String fromUserId) async {
    final myUserId = widget.userData['user_id'];
    final nickname = widget.userData['nickname'] ?? '';
    final avatarId = widget.userData['avatar_id'] ?? 'default_avatar';
    final now = Timestamp.now();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(myUserId)
          .collection('friends')
          .doc(fromUserId)
          .update({'status': 'accepted', 'accepted_at': now});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .collection('friends')
          .doc(myUserId)
          .set({
        'user_id': myUserId,
        'nickname': nickname,
        'avatar_id': avatarId,
        'status': 'accepted',
        'request_message': '',
        'cdatetime': now,
        'accepted_at': now,
      });

      await fetchFriends();
      await fetchPendingRequests();
      setState(() {});
    } catch (e) {
      print('친구 수락 오류: $e');
    }
  }

  Future<void> rejectFriendRequest(String fromUserId) async {
    final myUserId = widget.userData['user_id'];

    try {
      // 🔄 상태만 'rejected'로 바꾼다 (삭제 ❌)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(myUserId)
          .collection('friends')
          .doc(fromUserId)
          .update({'status': 'rejected'});

      await fetchPendingRequests();
      setState(() {});
    } catch (e) {
      print('친구 거절 오류: $e');
    }
  }

  Future<void> cancelFriendRequest(String targetUserId) async {
    final currentUserId = widget.userData['user_id'];
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('friends')
          .doc(currentUserId)
          .delete();

      await fetchPendingRequests();
      await fetchAllUsers();
      setState(() {});
    } catch (e) {
      print('친구 요청 취소 실패: $e');
    }
  }

  Future<void> removeFriend(String targetUserId) async {
    final currentUserId = widget.userData['user_id'];

    try {
      // 1. 내 friends 컬렉션에서 제거
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(targetUserId)
          .delete();

      // 2. 상대방 friends 컬렉션에서도 제거
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('friends')
          .doc(currentUserId)
          .delete();

      // 3. 상태 갱신
      await fetchFriends();
      await fetchAllUsers();
      setState(() {});
    } catch (e) {
      print('친구 삭제 실패: $e');
    }
  }

  Widget _buildTabButton(String label, int tabIndex) {
    final isActive = selectedTab == tabIndex;
    return ElevatedButton(
      onPressed: () async {
        setState(() {
          selectedTab = tabIndex;
        });
        if (tabIndex == 1 || tabIndex == 2) {
          await fetchPendingRequests();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFF1E6FD9) : Colors.grey.shade300,
        foregroundColor: isActive ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 선택된 탭에 따라 보여줄 목록 정리 (요청 수락 탭만 받은 요청 필터링)
    List<Map<String, dynamic>> displayList;
    if (selectedTab == 2) {
      displayList = pendingRequests.where((r) => r['is_incoming'] == true).toList(); // 🔥 핵심 수정
    } else if (selectedTab == 1) {
      displayList = allUsers;
    } else {
      displayList = friendList;
    }

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
              selectedTab == 0 ? '친구 검색'
                  : selectedTab == 1 ? '친구할 유저 검색'
                  : '친구 요청 관리',
              style: const TextStyle(fontSize: 14, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            if (selectedTab != 2)
              TextField(
                decoration: InputDecoration(
                  hintText: '친구 이름을 검색하세요',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: displayList.isEmpty
                  ? Center(
                child: Text(
                  selectedTab == 0 ? '등록된 친구가 없습니다.'
                      : selectedTab == 1 ? '조회되는 유저가 없습니다.'
                      : '요청된 친구가 없습니다.',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final user = displayList[index];
                  final userId = user['user_id'];
                  final name = user['nickname'];
                  final isMyRequest = pendingRequests.any((f) => f['user_id'] == userId && f['is_incoming'] == false);
                  final isReceivedRequest = pendingRequests.any((f) => f['user_id'] == userId && f['is_incoming'] == true);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Image.asset('assets/profile_gold.png', height: 80),
                        const SizedBox(width: 16),
                        Expanded(child: Text(name, style: const TextStyle(fontSize: 22))),
                        if (selectedTab == 0)
                          ElevatedButton(
                            onPressed: () async {
                              await removeFriend(userId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E6FD9),
                            ),
                            child: const Text('취소', style: TextStyle(color: Colors.white)),
                          )
                        else if (selectedTab == 1)
                          GestureDetector(
                            onTap: () async {
                              if (isMyRequest) {
                                await cancelFriendRequest(userId);
                              } else if (!isReceivedRequest) {
                                await sendFriendRequest(userId, name);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('받은 요청입니다. 요청 수락 탭을 확인하세요!')),
                                );
                              }
                              await fetchPendingRequests();
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isReceivedRequest
                                    ? Colors.amber
                                    : isMyRequest
                                    ? Colors.orange
                                    : Colors.transparent,
                                border: Border.all(color: const Color(0xFF1E6FD9)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isReceivedRequest ? '요청 대기'
                                    : isMyRequest ? '요청 취소'
                                    : '친구 요청',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E6FD9),
                                ),
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  await acceptFriendRequest(userId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('수락', style: TextStyle(color: Colors.white)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  await rejectFriendRequest(userId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('거절', style: TextStyle(color: Colors.white)),
                              ),
                            ],
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTabButton('친구 목록', 0),
            _buildTabButton('친구 추가', 1),
            _buildTabButton('요청 수락', 2),
          ],
        ),
      ),
    );
  }
}
