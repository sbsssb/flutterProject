import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../common/bottom_nav_bar.dart';

import '../mypage/profile_avatar.dart';

class TravelRoomDetailPage extends StatelessWidget {
  final String roomId;

  const TravelRoomDetailPage({super.key, required this.roomId});

  Future<Map<String, dynamic>?> fetchRoomData(String roomId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('travel_rooms')
            .doc(roomId)
            .get();
    return doc.exists ? doc.data() : null;
  }

  Future<List<Map<String, dynamic>>> fetchRoomMembers(String roomId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('travel_rooms')
            .doc(roomId)
            .collection('members')
            .get();

    return snapshot.docs
        .map((doc) => doc.data())
        .toList()
        .cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(),
      backgroundColor: Colors.blue[700],
      body: FutureBuilder(
        future: Future.wait([fetchRoomData(roomId), fetchRoomMembers(roomId)]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final roomData = snapshot.data![0] as Map<String, dynamic>;
          final members = snapshot.data![1] as List<Map<String, dynamic>>;

          return Column(
            children: [
              const SizedBox(height: 80),
              Image.asset(
                'assets/common_images/logo-main-ver2.png',
                height: 100,
              ),
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
                        padding: const EdgeInsets.only(
                          top: 60,
                          left: 24,
                          right: 24,
                        ),
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
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${roomData['region']} ${roomData['sub_region']}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'AstaSans',
                                    fontSize: 23,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            // 👥 멤버 목록
                            Wrap(
                              spacing: 20,
                              runSpacing: 30,
                              alignment: WrapAlignment.center,
                              children: members.map((member) {
                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('users').doc(member['user_id']).get(),
                                  builder: (context, snapshot) {
                                    int stampCount = 0;
                                    if (snapshot.hasData && snapshot.data!.exists) {
                                      final userData = snapshot.data!.data() as Map<String, dynamic>;
                                      stampCount = userData['stampCount'] ?? 0;
                                    }

                                    return SizedBox(
                                      width: 90, // ✅ 너비 제한 (한 줄에 3개 맞춤)
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
                                            textAlign: TextAlign.center,
                                            maxLines: 2, // 두 줄로
                                            overflow: TextOverflow.ellipsis,
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
                                final currentUser =
                                    FirebaseAuth.instance.currentUser;
                                final uploaderId = currentUser?.uid;

                                if (uploaderId != null) {
                                  context.go('/album/$roomId/$uploaderId');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFACC15),
                                minimumSize: const Size.fromHeight(60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: TextStyle(
                                    fontFamily: 'Jalnan',
                                    fontSize: 19,
                                    color: Colors.white
                                ),
                              ),
                              child: const Text('앨범 보기'),
                            ),

                            const SizedBox(height: 30),

                            // 📅 일정 버튼
                            ElevatedButton(
                              onPressed: () {
                                context.go('/stamp?roomId=$roomId');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFACC15),
                                minimumSize: const Size.fromHeight(60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: TextStyle(
                                    fontFamily: 'Jalnan',
                                    fontSize: 19,
                                    color: Colors.white
                                ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ), // ⬅️ padding 키움
                        decoration: BoxDecoration(
                          color: Colors.yellow[700], // 노란색 유지
                          borderRadius: BorderRadius.circular(30), // ⬅️ 더 둥글게
                          boxShadow: [
                            // ⬅️ 그림자 효과
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          roomData['room_name'] ?? '',
                          style: TextStyle(
                            fontFamily: 'Jalnan',
                            fontSize: 24,
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
