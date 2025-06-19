import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../mypage/profile_avatar.dart';

class TravelRoomDetailPage extends StatelessWidget {
  final String roomId;

  const TravelRoomDetailPage({super.key, required this.roomId});

  Future<Map<String, dynamic>?> fetchRoomData(String roomId) async {
    final doc = await FirebaseFirestore.instance.collection('travel_rooms').doc(roomId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<List<Map<String, dynamic>>> fetchRoomMembers(String roomId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('travel_rooms')
        .doc(roomId)
        .collection('members')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList().cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700],
      body: FutureBuilder(
        future: Future.wait([
          fetchRoomData(roomId),
          fetchRoomMembers(roomId),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final roomData = snapshot.data![0] as Map<String, dynamic>;
          final members = snapshot.data![1] as List<Map<String, dynamic>>;

          return Column(
            children: [
              const SizedBox(height: 80),
              Image.asset('assets/common_images/logo-main-ver2.png', height: 100),
              const SizedBox(height: 20),

              // Stack을 써서 방 이름을 노란 박스 위에 겹치게
              Expanded(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // 🟡 노란 박스 (화면 하단 영역)
                    Positioned.fill(
                      top: 30, // 방 이름 박스 높이만큼 여유를 줌
                      child: Container(
                        padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                        child: Column(
                          children: [
                            // 📍 지역 정보
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on, color: Colors.black),
                                const SizedBox(width: 8),
                                Text(
                                  '${roomData['region']} ${roomData['sub_region']}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            // 👥 멤버 목록
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: members.map((member) {
                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('users').doc(member['user_id']).get(),
                                  builder: (context, snapshot) {
                                    int stampCount = 0;
                                    if (snapshot.hasData && snapshot.data!.exists) {
                                      final userData = snapshot.data!.data() as Map<String, dynamic>;
                                      stampCount = userData['stampCount'] ?? 0;
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 36,
                                            backgroundImage: AssetImage(getProfileImagePath(stampCount)),
                                            backgroundColor: Colors.grey[300],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            member['nickname'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 50),

                            // 📷 앨범 버튼
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/album', arguments: roomId);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFACC15),
                                foregroundColor: Colors.black,
                                minimumSize: const Size.fromHeight(60),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(fontSize: 22),
                              ),
                              child: const Text('앨범 보기'),
                            ),

                            const SizedBox(height: 30),

                            // 📅 일정 버튼
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/schedule', arguments: roomId);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFACC15),
                                foregroundColor: Colors.black,
                                minimumSize: const Size.fromHeight(60),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(fontSize: 22),
                              ),
                              child: const Text('일정 보기'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 🔵 방 이름 박스 (노란 박스 위에 겹치게 위치)
                    Positioned(
                      top: 0,
                      left: 35,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), // ⬅️ padding 키움
                        decoration: BoxDecoration(
                          color: Colors.yellow[700], // 노란색 유지
                          borderRadius: BorderRadius.circular(30), // ⬅️ 더 둥글게
                          boxShadow: [ // ⬅️ 그림자 효과
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          roomData['room_name'] ?? '',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

  }
}
