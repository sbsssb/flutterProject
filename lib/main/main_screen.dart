import 'package:flutter/material.dart';
import '../common/bottom_nav_bar.dart'; // 하단바 파일

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF1E6FD9), // 전체 배경 파란색
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              height: screenHeight * 0.85, // 반응형 높이 설정
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo_dog_dice.png', height: 100),
                  const SizedBox(height: 12),
                  const Text('어디든 좋아!', style: TextStyle(fontSize: 16)),
                  const Text('랜덤어때', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/create-room');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6FD9),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('주사위 굴리기', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Image.asset('assets/icons/dice.png', height: 28),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text('최근 여행', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/festival');
                    },
                    icon: const Icon(Icons.celebration),
                    label: const Text("축제 구경가기"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
          Image.asset('assets/icons/three_dice.png', height: 32),
        ],
      ),
    );
  }
}


