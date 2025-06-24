import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late String userId;
  late Future<List<Map<String, dynamic>>> _recentRooms;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      _recentRooms = getRecentJoinRooms(userId);
    } else {
      _recentRooms = Future.value([]);
    }
  }

  // 🔹 Firestore에서 최근 여행 3건 조회
  Future<List<Map<String, dynamic>>> getRecentJoinRooms(String userId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('join_rooms')
            .orderBy('cdatetime', descending: true)
            .limit(3)
            .get();

    return snapshot.docs.map((doc) {
      return {'room_id': doc['room_id'], 'region': doc['region']};
    }).toList();
  }

  //유저 정보
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  String getProfileImagePath(int count) {
    if (count >= 11) return 'assets/mypage_images/profile_gold.png';
    if (count >= 6) return 'assets/mypage_images/profile_silver.png';
    return 'assets/mypage_images/profile_bronze.png';
  }

  String getTitleWithNickname(int count, String nickname) {
    if (count >= 11) return '인간 네비게이션\n$nickname';
    if (count >= 6) return '차 멀미에 익숙한\n$nickname';
    return '집 밖을 나선\n$nickname';
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF1E6FD9),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            // 🔵 상단 로고/텍스트
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  const Text(
                    '어디든 좋아!',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Image.asset(
                    'assets/common_images/logo-main-ver2.png',
                    height: 150,
                  ),
                ],
              ),
            ),

            // ⚪ 콘텐츠 박스
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (userId == '') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('로그인 후 이용 가능합니다.')),
                            );
                            context.go('/login');
                            return;
                          }
                          context.push('/addRoom');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E6FD9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '주사위 굴리기',
                              style: TextStyle(
                                fontFamily: 'Jalnan',
                                fontSize: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Image.asset(
                              'assets/main_images/icon-dice1.png',
                              height: 50,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '나의 여행 등급',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E6FD9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 유저정보
                      _buildProfileSection(),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '최근 여행',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E6FD9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      userId == ''
                          ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            '로그인하고 여행 기록을 확인해보세요!',
                            style: TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                        ),
                      )
                          : FutureBuilder<List<Map<String, dynamic>>>(
                        future: _recentRooms,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator(); // 🔄 로딩 중
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Text(
                                  '최근 여행 기록이 없습니다.',
                                  style: TextStyle(fontSize: 18, color: Colors.black54),
                                ),
                              ),
                            );
                          }

                          // ✅ 여행 리스트 표시
                          final rooms = snapshot.data!;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(3, (index) {
                              if (index < rooms.length) {
                                final room = rooms[index];
                                return _regionItem(
                                  context,
                                  room['region'],
                                  room['room_id'],
                                );
                              } else {
                                return _emptyRegionSlot(index);
                              }
                            }),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      ElevatedButton(
                        onPressed: () {
                          context.push('/festival');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E6FD9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "축제 구경가기",
                              style: TextStyle(
                                fontFamily: 'Jalnan',
                                fontSize: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Image.asset(
                              'assets/main_images/icon-festival.png',
                              height: 50,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 지역 아이템 위젯
  Widget _regionItem(BuildContext context, String region, String roomId) {
    return GestureDetector(
      onTap: () {
        context.push('/detail/$roomId');
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Color(0xFF1E6FD9), width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              region,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Image.asset('assets/main_images/icon-dice2.png', height: 50),
          ],
        ),
      ),
    );
  }

  Widget _emptyRegionSlot(int index) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("어디든\n떠나볼까?", textAlign: TextAlign.center),
            Image.asset('assets/main_images/character.png', height: 45),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    if (userId == '') {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Text(
            '로그인하고 여행 등급을 확인해보세요!',
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
        ),
      );
    } else {
      return FutureBuilder<Map<String, dynamic>?>(
        future: getUserProfile(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return SizedBox();

          final data = snapshot.data!;
          final stampCount = data['stampCount'] ?? 0;
          final nickname = data['nickname'] ?? '여행자';
          final imagePath = getProfileImagePath(stampCount);
          final titleText = getTitleWithNickname(stampCount, nickname);

          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 350),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(imagePath, height: 80),
                  const SizedBox(width: 12),
                  RichText(
                    textAlign: TextAlign.left,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${titleText.split('\n').first}\n',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: titleText.split('\n').last,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}
