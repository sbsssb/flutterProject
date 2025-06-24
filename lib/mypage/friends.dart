import 'package:flutter/material.dart';
import 'appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'send_notification.dart';
import 'profile_avatar.dart';
import '../common/bottom_nav_bar.dart';


class FriendsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final int initialTabIndex; // ✅ 이 줄 추가
  const FriendsPage({
    super.key,
    required this.userData,
    this.initialTabIndex = 0,
  });

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  int selectedTab = 0;
  final int _unreadCount = 2;
  List<Map<String, dynamic>> friendList = [];
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> pendingRequests = [];

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTabIndex; // ✅ 여기에 반영
    initFriendData();
  }

  Future<void> initFriendData() async {
    await fetchFriends();
    await fetchAllUsers();
    await fetchPendingRequests();
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
            'stampCount': userData['stampCount'] ?? 0, // ✅ 이 줄 추가!
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
      final nickname = data['nickname'] ?? '';
      if (nickname.trim().isEmpty) continue;

      fetchedAllUsers.add({
        'user_id': userId,
        'nickname': nickname,
        'avatar_id': data['avatar_id'] ?? '',
        'stampCount': data['stampCount'] ?? 0, // ✅ 이 줄 추가!
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
        .where('status', whereIn: ['incoming', 'sending'])
        .get();

    List<Map<String, dynamic>> fetchedPending = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final friendUserId = doc.id;

      // 🔎 상대방 유저 정보 조회
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUserId)
          .get();

      final userData = userDoc.data() ?? {};

      fetchedPending.add({
        ...data,
        'friend_user_id': friendUserId,
        'is_incoming': data['status'] == 'incoming',
        'stampCount': userData['stampCount'] ?? 0, // ✅ 여기!
      });
    }

    setState(() {
      pendingRequests = fetchedPending;
    });
  }

  Future<void> sendFriendRequest(String targetUserId, String targetNickname) async {
    final currentUserId = widget.userData['user_id'];
    final timestamp = Timestamp.now();

    try {
      // 🔹 Firestore에서 내 정보 가져오기 (닉네임, 아바타)
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      final data = currentUserDoc.data() ?? {};
      final currentNickname = data['nickname'] ?? '알수없음';
      final avatarId = data.containsKey('avatar_id') ? data['avatar_id'] : 'default_avatar';
      final stampCount = data['stampCount'] ?? 0;

      // 🔹 상대방에게 친구 요청 정보 저장 (incoming)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('friends')
          .doc(currentUserId)
          .set({
        'user_id': currentUserId,
        'nickname': currentNickname,
        'avatar_id': avatarId,
        'status': 'incoming',
        'request_message': '같이 여행 가자!',
        'cdatetime': timestamp,
      });

      // 🔹 내 쪽에도 보낸 요청 정보 저장 (sending)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(targetUserId)
          .set({
        'user_id': targetUserId,
        'nickname': targetNickname,
        'avatar_id': 'default_avatar',
        'status': 'sending',
        'request_message': '',
        'cdatetime': timestamp,
      });

      // 🔹 알림 전송
      await sendNotification(
        targetUserId: targetUserId,
        type: 'friend_request',
        content: ' 님이 친구 요청을 보냈습니다.',
        senderId: currentUserId,
        senderNickname: currentNickname,
        senderAvatarId: avatarId,
        senderStampCount: stampCount,
      );

      // 🔄 상태 새로고침
      await fetchPendingRequests();
      await fetchAllUsers();
      setState(() {});
    } catch (e) {
      print('친구 요청 실패: $e');
    }
  }

  Future<void> acceptFriendRequest(String fromUserId) async {
    final myUserId = widget.userData['user_id'];
    final now = Timestamp.now();

    try {
      // 🔹 상태 업데이트 (내 친구 목록)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(myUserId)
          .collection('friends')
          .doc(fromUserId)
          .update({
        'status': 'accepted',
        'accepted_at': now,
      });

      // 🔹 내 정보 Firestore에서 다시 가져오기 (nickname, avatar)
      final myUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUserId)
          .get();

      final data = myUserDoc.data() ?? {};
      final myNickname = data['nickname'] ?? '알수없음';
      final myAvatarId = data.containsKey('avatar_id') ? data['avatar_id'] : 'default_avatar';
      final stampCount = data['stampCount'] ?? 0;

      // 🔹 상대방 친구 목록에도 accepted 추가
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .collection('friends')
          .doc(myUserId)
          .set({
        'user_id': myUserId,
        'nickname': myNickname,
        'avatar_id': myAvatarId,
        'status': 'accepted',
        'request_message': '',
        'cdatetime': now,
        'accepted_at': now,
      });

      // 🔹 알림 전송
      await sendNotification(
        targetUserId: fromUserId,
        type: 'friend_accept',
        content: ' 님이 친구 요청을 수락했습니다.',
        senderId: myUserId,
        senderNickname: myNickname,
        senderAvatarId: myAvatarId,
        senderStampCount: stampCount,
      );

      // 🔹 친구 목록/요청 목록 새로고침
      await fetchFriends();
      await fetchPendingRequests();
      await fetchAllUsers();
      setState(() {});
    } catch (e) {
      print('친구 수락 오류: $e');
    }
  }

  Future<void> rejectFriendRequest(String fromUserId) async {
    final myUserId = widget.userData['user_id'];

    try {
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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(targetUserId)
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(targetUserId)
          .delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('friends')
          .doc(currentUserId)
          .delete();

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
    final String userId = widget.userData['user_id']; // ✅ 추가
    List<Map<String, dynamic>> baseList;
    if (selectedTab == 2) {
      baseList = pendingRequests.where((r) => r['is_incoming'] == true).toList();
    } else if (selectedTab == 1) {
      baseList = allUsers;
    } else {
      baseList = friendList;
    }
    // ✅ 검색어가 비어 있지 않으면 필터링, 아니면 전체 보여줌
    final displayList = baseList.where((user) {
      final name = (user['nickname'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery); // 실시간 필터링
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(userId: userId),

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
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase(); // 검색어 업데이트
                  });
                },
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
                  final stampCount = user['stampCount'] ?? 0; // ✅ 이 줄 추가
                  print('✅ 유저 $name 의 스탬프 수: $stampCount');
                  final isMyRequest = pendingRequests.any(
                        (f) => f['user_id'] == userId && f['status'] == 'sending',
                  );
                  final isReceivedRequest = pendingRequests.any(
                        (f) => f['user_id'] == userId && f['status'] == 'incoming',
                  );


                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Image.asset(getProfileImagePath(stampCount), height: 80),
                        const SizedBox(width: 16),
                        Expanded(child: Text(name, style: const TextStyle(fontSize: 22,fontFamily: 'AstaSans',))),
                        if (selectedTab == 0)
                          ElevatedButton(
                            onPressed: () async {
                              await removeFriend(userId);
                              setState(() {});
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
                                  setState(() {});
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabButton('친구 목록', 0),
                _buildTabButton('친구 추가', 1),
                _buildTabButton('요청 수락', 2),
              ],
            ),
          ),
          const BottomNavBar(currentIndex: 2), // 👈 여기까지 포함
        ],
      ),
    );
  }
}