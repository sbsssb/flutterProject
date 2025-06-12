import 'package:flutter/material.dart';
import 'appbar.dart';
void main() {
  runApp(const myPageApp());
}

class myPageApp extends StatelessWidget {
  const myPageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: myPageMainApp(),
    );
  }
}

class myPageMainApp extends StatefulWidget {
  const myPageMainApp({super.key});

  @override
  State<myPageMainApp> createState() => _myPageMainAppState();
}

class _myPageMainAppState extends State<myPageMainApp> {
  int _unreadCount = 3; // 실시간 알림 수 (예시 값)

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    // TODO: Firestore / FCM 연동 예정
    // 예시로 2개 표시 중
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        unreadCount: _unreadCount,
        onNotificationTap: () {
          // 알림 페이지 이동
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              '프로필',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildLicenseCard(),

            const SizedBox(height: 20),

            Center( // ✅ 버튼을 화면 가운데 정렬
              child: Stack(
                clipBehavior: Clip.none, // ✅ 버튼 바깥으로 튀어나오게 허용
                children: [
                  // ✅ 파란 버튼
                  ElevatedButton(
                    onPressed: () {
                      // TODO: 프로필 수정 페이지 이동
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 14), // 🔄 수정: 크기 축소
                      backgroundColor: Color(0xFF1E6FD9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '면허 갱신하기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),

                  // ✅ 왼쪽에 캐릭터 PNG 삐져나오기
                  Positioned(
                    left: -24, // 🔄 버튼 왼쪽으로 삐져나오게
                    top: -18,
                    child: Image.asset(
                      'assets/license_character.png', // 네가 넣은 png 경로
                      height: 70, // 필요에 따라 조절
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 🔹 이전 여행 카드
                SizedBox(
                  width: 180,
                  height: 180,
                  child: _buildFunctionCard(
                    image: 'assets/prev_travel.png',
                    label: '이전 여행',
                    imageSize: 100, // ✅ 내부 이미지 사이즈 커짐
                    fontSize: 24,  // ✅ 텍스트 크기 증가
                    onTap: () {
                      // TODO: 이전 여행 페이지 이동
                    },
                  ),
                ),

                // 🔹 사귄 친구 카드
                SizedBox(
                  width: 180,
                  height: 180,
                  child: _buildFunctionCard(
                    image: 'assets/friends.png',
                    label: '사귄 친구',
                    imageSize: 100,
                    fontSize: 24,
                    onTap: () {
                      // TODO: 친구 목록 페이지 이동
                    },
                  ),
                ),
              ],
            ),


            const SizedBox(height: 20),

            Center(
              child: SizedBox(
                width: 375, // ✅ 이전 카드 2개 + 간격에 맞춤
                child: buildCurrentTravelCard(
                  image: 'assets/current_travel.png',
                  label: '진행 중인 여행',
                  description: '아직 진행 중인 여행 그룹이 있어요.',
                  onTap: () {
                    // TODO: 상세 이동
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.share), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
        onTap: (index) {
          // TODO: 탭 이동 처리
        },
      ),
    );
  }

  // 라이센스 카드
  Widget _buildLicenseCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

// 🔹 타이틀 뱃지 - 왼쪽 상단 정렬
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Color(0xFF1E6FD9),
                      width: 2.0, // ✅ 테두리 선 굵기 조절 (기본: 1.0)
                  ),

                ),
                child: const Text(
                  '랜덤 라이센스',
                  style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: Color(0xFF1E6FD9)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 프로필 영역 (좌/우 정렬)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 🔸 왼쪽: 프로필 + 칭호
                Column(
                  children: [
                    Image.asset('assets/profile_icon.png', height: 160),
                    const SizedBox(height: 8),
                    const Text(
                      '모험심 강한\n상급 낭만고양이!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF1E6FD9)),

                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // 🔸 오른쪽: 닉네임 + 이메일 + 통계
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // 🔄 수정: start → center
                    children: [

                      const SizedBox(height: 12), // ✅ 추가: 프로필 이미지와의 간격 확보

                      const Text(
                        'nickname',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E6FD9),
                        ),
                      ),
                      const Text(
                        'cat123456@gmail.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 20), // 🔄 수정: 기존 12 → 20으로 여백 증가

                      Container(
                        width: 180, // ✅ 고정 너비로 시각 균형 유지
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF1E6FD9)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround, // 🔄 수정: center 정렬
                          children: const [
                            Column(
                              children: [
                                Text('여행 성공', style: TextStyle(color: Color(0xFF1E6FD9),fontSize:17 )),
                                SizedBox(height: 20),
                                Text('8회', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                Text('사귄 팅구', style: TextStyle(color: Color(0xFF1E6FD9),fontSize:17)),
                                SizedBox(height: 20),
                                Text('12명', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🔹 발급일 + 협회 + 도장
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    '발급일자: 2025.06.10',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '랜덤어때 협회',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF1E6FD9),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // ✅ PNG 전용 Stack → 자유 위치 배치
                  SizedBox(
                    width: 32, // PNG가 들어갈 공간
                    height: 32,
                    child: Stack(
                      clipBehavior: Clip.none, // ✅ overflow 허용
                      children: [
                        Positioned(
                          top: -15, // 🔄 원하는 만큼 조정
                          left: 0, // 또는 right: 0 으로 정렬 조정
                          child: Image.asset(
                            'assets/stamp_icon.png',
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// ✅ 기능 카드 위젯 개선
  Widget _buildFunctionCard({
    required String image,
    required String label,
    String? description,
    VoidCallback? onTap,
    double imageSize = 60,     // ✅ 이미지 크기 조절 가능
    double fontSize = 14,      // ✅ 텍스트 크기 조절 가능
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(image, height: imageSize), // 🔄 수정: 외부에서 조정 가능
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize, // 🔄 수정: 외부에서 조정 가능
                  color: Color(0xFF1E6FD9),
                ),
              ),
              if (description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 진행 중인 여행 카드 (가로형 레이아웃)
  Widget buildCurrentTravelCard({
    required String image,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🔹 이미지 (왼쪽)
              Image.asset(
                image,
                height: 110,
                width: 110,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),

              // 🔹 텍스트 (오른쪽)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF1E6FD9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}