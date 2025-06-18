import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutterteam4/travelroom/selectRegion.dart';
import 'package:flutterteam4/travelroom/selectTheme.dart';
import '../dice/dice.dart';
import '../firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterteam4/user/user_provider.dart';

class RoomCreate extends StatelessWidget {
  const RoomCreate({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
      ),

      home: RoomCreatePage(),
    );
  }
}

class RoomCreatePage extends ConsumerStatefulWidget {
  @override
  _RoomCreatePageState createState() => _RoomCreatePageState();
}

class _RoomCreatePageState extends ConsumerState<RoomCreatePage> {
  final TextEditingController _nameController = TextEditingController();
  String selectedRegion = '';
  String selectedTransport = '';
  List<String> selectedThemes = [];
  List<Map<String, dynamic>> invitedFriends = [];

  FirebaseFirestore fs = FirebaseFirestore.instance;

  //친구 초대
  Widget _buildFriendInviteRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...invitedFriends.map((friend) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage('assets/avatars/${friend['avatar_id']}.png'),  // 경로는 프로젝트에 맞게
                  backgroundColor: Colors.grey[300],
                ),
                SizedBox(height: 4),
                Text(
                  friend['nickname'],
                  style: TextStyle(fontSize: 12),
                )
              ],
            ),
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _selectFriends,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.add, size: 20),
                ),
                SizedBox(height: 4),
                Text("추가", style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectFriends() async {
    // final user = FirebaseAuth.instance.currentUser;
    // if (user == null) return;
    // final currentUserId = user.uid;
    final user = ref.watch(authStateProvider).value;

    final friendSnapshot = await FirebaseFirestore.instance
        .collection('users')
        // .doc(currentUserId)
        .doc(user?.uid)
        .collection('friends')
        .where('status', isEqualTo: 'accepted')
        .get();

    final allFriends = friendSnapshot.docs;

    // 임시 선택된 친구 (Map 형태)
    List<Map<String, dynamic>> tempSelected = [...invitedFriends];

    // 이미 선택된 user_id만 뽑기
    final selectedIds = tempSelected.map((f) => f['user_id']).toList();

    final result = await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: StatefulBuilder(
            builder: (context, setState) {
              String searchQuery = '';
              List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredFriends = allFriends;

              // 필터링
              if (searchQuery.isNotEmpty) {
                filteredFriends = allFriends.where((doc) {
                  final nickname = doc.data()['nickname'] ?? '';
                  return nickname.contains(searchQuery);
                }).toList();
              }

              return SizedBox(
                width: 320,
                height: 520,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('친구 초대하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 12),

                      // 🔍 검색창
                      TextField(
                        decoration: InputDecoration(
                          hintText: "닉네임 검색",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (value) {
                          setState(() => searchQuery = value);
                        },
                      ),

                      const SizedBox(height: 12),

                      // 🙋 초대한 친구들
                      if (tempSelected.isNotEmpty)
                        SizedBox(
                          height: 80,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: tempSelected.map((friend) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundImage: AssetImage('assets/avatars/${friend['avatar_id']}.png'),
                                          backgroundColor: Colors.grey[300],
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              tempSelected.removeWhere((f) => f['user_id'] == friend['user_id']);
                                            });
                                          },
                                          child: CircleAvatar(
                                            radius: 10,
                                            backgroundColor: Colors.red,
                                            child: Icon(Icons.close, size: 12, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(friend['nickname'], style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // 📋 친구 목록
                      Expanded(
                        child: ListView(
                          children: filteredFriends.map((doc) {
                            final data = doc.data();
                            final userId = doc.id;
                            final nickname = data['nickname'] ?? '이름없음';
                            final avatarId = data['avatar_id'] ?? '';
                            final titles = data['titles'] ?? '';
                            final isInvited = tempSelected.any((f) => f['user_id'] == userId);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: AssetImage('assets/avatars/$avatarId.png'),
                                backgroundColor: Colors.grey[300],
                              ),
                              title: Text(nickname),
                              trailing: ElevatedButton(
                                onPressed: isInvited
                                    ? null
                                    : () {
                                  setState(() {
                                    tempSelected.add({
                                      'user_id': userId,
                                      'nickname': nickname,
                                      'avatar_id': avatarId,
                                      'titles': titles,
                                    });
                                  });
                                },
                                child: Text(isInvited ? '초대됨' : '초대'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInvited ? Colors.grey : Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // ✅ 확인/닫기 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                invitedFriends = tempSelected;
                              });
                              Navigator.pop(context, tempSelected);
                            },
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );

      },
    );

    if (result != null) {
      setState(() {
        invitedFriends = result;
      });
    }

  }

  //지역 선택 페이지
  Future<void> _selectRegion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegionSelectPage()),
    );

    if (result != null && result is String) {
      setState(() {
        selectedRegion = result;
      });
    }
  }

  // 교통수단 선택 다이얼로그
  void _selectTransport() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('교통수단 선택'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTransport = '대중교통';
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 대중교통 그림 (예: 아이콘이나 이미지)
                        Icon(Icons.directions_transit, size: 48, color: Colors.blue),
                        SizedBox(height: 8),
                        Text('대중교통', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTransport = '자차';
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 자동차 그림
                        Icon(Icons.directions_car, size: 48, color: Colors.green),
                        SizedBox(height: 8),
                        Text('자차', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 테마 페이지
  Future<void> _selectThemes() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ThemeSelectPage()),
    );

    if (result != null && result is List<String>) {
      setState(() {
        selectedThemes = result;
      });
    }
  }

  void _createRoom() async {
    final user = ref.watch(authStateProvider).value;

    final roomId = fs.collection('travel_rooms').doc().id;

    await fs.collection('travel_rooms')
        .doc(roomId)
        .set({
            "room_id": roomId,
            "room_name" : _nameController.text,
            //"owner_id": user.uid,
            "owner_id": user?.uid,
            "region": selectedRegion,
            "sub_region": null,
            "theme": selectedThemes,
            "transport": selectedTransport,
            "cdatetime": FieldValue.serverTimestamp(),
            "is_done" : false
          });

    // members 서브컬렉션에 방장 추가
    await fs.collection('travel_rooms')
        .doc(roomId)
        .collection('members')
        .doc(user?.uid)  // 또는 유저 uid
        .set({
      "user_id": user?.uid,
      "is_owner": true,
      "nickname": "test1111",
      "avatar_id": null,
      "titles": "칭호",  // 또는 유저가 가진 타이
    });

    // users 컬렉션에 참여한 room_id 추가
    await fs.collection('users')
        .doc(user?.uid)
        .set({
      'joined_rooms': FieldValue.arrayUnion([roomId])
    }, SetOptions(merge: true));

    // 초대한 친구들 저장
    for (final friend in invitedFriends) {
      await fs.collection('travel_rooms')
          .doc(roomId)
          .collection('members')
          .doc(friend['user_id'])
          .set({
        "user_id": friend['user_id'],
        "is_owner": false,
        "nickname": friend['nickname'],
        //"avatar_id": friend['avatar_id'],
        "avatar_id": null,
        "titles": friend['titles'] ?? '',
      });

      // 친구들의 users 문서에도 joined_rooms 추가
      await fs.collection('users')
          .doc(friend['user_id'])
          .set({
        'joined_rooms': FieldValue.arrayUnion([roomId])
      }, SetOptions(merge: true));
    }

    // 성공적으로 저장 후 알림 또는 페이지 이동
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("여행방이 생성되었습니다!")),
    );

    //초기화
    setState(() {
      _nameController.clear();
      selectedRegion = '';
      selectedTransport = '';
      selectedThemes = [];
      invitedFriends = [];
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoubleDiceOnBoard(roomId:roomId),
      ),
    );
  }

  final ButtonStyle commonButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.yellow,
    foregroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    textStyle: const TextStyle(fontSize: 16),
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Center(
                child: Image.asset(
                  'assets/common_images/logo-main-ver1.png',
                  height: 80,
                ),
              ),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "여행방 이름"),
              ),
              SizedBox(height: 40),
              _buildFriendInviteRow(),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: _selectRegion,
                style: commonButtonStyle,
                child: Text(selectedRegion.isEmpty ? "지역 선택" : selectedRegion),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectTransport,
                style: commonButtonStyle,
                child: Text(selectedTransport.isEmpty ? "교통수단 선택" : selectedTransport),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectThemes,
                style: commonButtonStyle,
                child: Text(selectedThemes.isEmpty ? "테마 선택" : selectedThemes.join(", ")),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _createRoom,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,         // 배경색
                    foregroundColor: Colors.white, // 글자색
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  textStyle: TextStyle(fontSize: 16)
                ),
                child: Text("방 만들기"),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

