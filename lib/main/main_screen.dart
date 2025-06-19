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
  late Future<List<Map<String, dynamic>>> _recentRooms;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _recentRooms = getRecentJoinRooms(userId);
  }

  // 🔹 Firestore에서 최근 여행 3건 조회
  Future<List<Map<String, dynamic>>> getRecentJoinRooms(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('join_rooms')
        .orderBy('cdatetime', descending: true)
        .limit(3)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'room_id': doc['room_id'],
        'region': doc['region'],
      };
    }).toList();
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
                  const Text('어디든 좋아!', style: TextStyle(color: Colors.white, fontSize: 18)),
                  Image.asset('assets/common_images/logo-main-ver2.png', height: 150),
                ],
              ),
            ),

            // ⚪ 콘텐츠 박스
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
                          context.push('/addRoom');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E6FD9),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('주사위 굴리기',
                                style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 2),
                            Image.asset('assets/main_images/icon-dice1.png', height: 70),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('최근 여행',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E6FD9))),
                      ),
                      const SizedBox(height: 12),

                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _recentRooms,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          final rooms = snapshot.data!;
                          if (rooms.isEmpty) {
                            return const Text('참여한 여행이 없습니다.');
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(3, (index) {
                              if (index < rooms.length) {
                                final room = rooms[index];
                                return _regionItem(context, room['region'], room['room_id']);
                              } else {
                                return _emptyRegionSlot(index); // 빈 슬롯
                              }
                            }),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      ElevatedButton(
                        onPressed: () {
                          context.push('/festival');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E6FD9),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("축제 구경가기",
                                style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            Image.asset('assets/main_images/icon-festival.png', height: 70),
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
        // TODO: RoomDetail 머지되면 아래 주석 해제
        // context.push('/roomDetail/$roomId');
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
            Text(region, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
}
