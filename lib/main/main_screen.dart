import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../common/bottom_nav_bar.dart'; // 하단바 위젯

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF1E6FD9), // 상단 파란 배경
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 로고 및 제목
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

            // 흰색 콘텐츠 박스
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
                      // 주사위 굴리기 버튼
                      ElevatedButton(
                        onPressed: () {
                          context.push('/addRoom');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E6FD9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
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
                              '주사위 굴리기',
                              style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Image.asset(
                              'assets/main_images/icon-dice1.png',
                              height: 70,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 최근 여행
                      const Text(
                        '최근 여행',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _regionItem(context, "고성", "r1"),
                          _regionItem(context, "무주", "r2"),
                          _regionItem(context, "문경", "r3"),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // 축제 구경가기 버튼
                      ElevatedButton.icon(
                        onPressed: () {
                          context.push('/festival');
                        },
                        icon: const Icon(Icons.celebration),
                        label: const Text("축제 구경가기",style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
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
        Navigator.pushNamed(context, '/room/$roomId');
      },
      child: Column(
        children: [
          Text(region, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Image.asset('assets/main_images/icon-dice2.png', height: 32),
        ],
      ),
    );
  }
}
