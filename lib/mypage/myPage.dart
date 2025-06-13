import 'package:flutter/material.dart';
import 'appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'profileEdit.dart';
import 'friends.dart';

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

Future<Map<String, dynamic>?> fetchUserData(String userId) async {
  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  } catch (e) {
    print('Firestore error: \$e');
    return null;
  }
}

class myPageMainApp extends StatefulWidget {
  const myPageMainApp({super.key});

  @override
  State<myPageMainApp> createState() => _myPageMainAppState();
}

class _myPageMainAppState extends State<myPageMainApp> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  int _unreadCount = 3; // 실시간 알림 수 (예시 값)

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    // 예시 userId (임시): 실제로는 로그인한 사용자의 uid로 대체해야 해
    const userId = 'yBGkS5yQ7Hc8tzbEEQYUSd3n8O23';

    final data = await fetchUserData(userId);
    if (data != null) {
      setState(() {
        userData = data;
        isLoading = false;
      });
    } else {
      print('사용자 데이터를 찾을 수 없습니다.');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '날짜 없음';
    try {
      final date = (timestamp as Timestamp).toDate();  // Firestore Timestamp → DateTime
      return DateFormat('yyyy.MM.dd').format(date);    // 예: 2025.06.11
    } catch (e) {
      return '날짜 오류';
    }
  }

  String _getProfileImagePath() {
    int travelCount = userData?['travel_success_count'] ?? 0;

    if (travelCount >= 11) {
      return 'assets/profile_gold.png';
    } else if (travelCount >= 6) {
      return 'assets/profile_silver.png';
    } else {
      return 'assets/profile_bronze.png';
    }
  }

  String _getTitleWithNickname() {
    int travelCount = userData?['travel_success_count'] ?? 0;
    String nickname = userData?['nickname'] ?? '여행자';

    if (travelCount >= 11) {
      return '인간 네비게이션 \n$nickname';
    } else if (travelCount >= 6) {
      return '차 멀미에 익숙한 \n$nickname';
    } else {
      return '집 밖을 나선 \n$nickname';
    }
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (userData != null) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileEditPage(userData: userData!),
                          ),
                        );

                        // ✅ 수정 후 돌아왔고 저장이 된 경우만 다시 데이터 불러오기
                        if (result == true) {
                          _loadUserData(); // 최신 사용자 정보 다시 불러오기
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 14),
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
                  Positioned(
                    left: -24,
                    top: -18,
                    child: Image.asset(
                      'assets/license_character.png',
                      height: 70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: _buildFunctionCard(
                    image: 'assets/prev_travel.png',
                    label: '이전 여행',
                    imageSize: 100,
                    fontSize: 24,
                    onTap: () {},
                  ),
                ),
                SizedBox(
                  width: 180,
                  height: 180,
                  child: _buildFunctionCard(
                    image: 'assets/friends.png',
                    label: '사귄 친구',
                    imageSize: 100,
                    fontSize: 24,
                    onTap: () async {
                      if (userData != null) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FriendsPage(userData: userData!),
                          ),
                        );

                        // ✅ 수정 후 돌아왔고 저장이 된 경우만 다시 데이터 불러오기
                        if (result == true) {
                          _loadUserData(); // 최신 사용자 정보 다시 불러오기
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 375,
                child: buildCurrentTravelCard(
                  image: 'assets/current_travel.png',
                  label: '진행 중인 여행',
                  description: '아직 진행 중인 여행 그룹이 있어요.',
                  onTap: () {},
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

  Widget _buildLicenseCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(0xFF1E6FD9),
                    width: 2.0,
                  ),
                ),
                child: const Text(
                  '랜덤 라이센스',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1E6FD9)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Image.asset(_getProfileImagePath(), height: 160),
                    const SizedBox(height: 8),
                    Text(
                      _getTitleWithNickname(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1E6FD9)),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        userData?['nickname'] ?? '닉네임 없음',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E6FD9),
                        ),
                      ),
                      Text(
                        userData?['email'] ?? '이메일 없음',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 180,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF1E6FD9)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('여행 성공', style: TextStyle(color: Color(0xFF1E6FD9), fontSize: 17)),
                                const SizedBox(height: 20),
                                Text('${userData?['travel_success_count'] ?? 0}회', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('사귄 팅구', style: TextStyle(color: Color(0xFF1E6FD9), fontSize: 17)),
                                const SizedBox(height: 20),
                                Text('${userData?['friends_count'] ?? 0}명', style: const TextStyle(fontWeight: FontWeight.bold)),
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
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '발급일자: ${_formatTimestamp(userData?['cdatetime'])}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '랜덤어때 협회',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E6FD9)),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: -15,
                          left: 0,
                          child: Image.asset('assets/stamp_icon.png', height: 60, fit: BoxFit.contain),
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

  Widget _buildFunctionCard({
    required String image,
    required String label,
    String? description,
    VoidCallback? onTap,
    double imageSize = 60,
    double fontSize = 14,
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
              Image.asset(image, height: imageSize),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, color: Color(0xFF1E6FD9)),
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
              Image.asset(image, height: 110, width: 110, fit: BoxFit.contain),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E6FD9)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
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
