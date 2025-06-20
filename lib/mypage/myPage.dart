import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ Riverpod 연동용
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutterteam4/user/user_provider.dart'; // ✅ 로그인 사용자 정보를 가져오기 위한 Provider
import 'profileEdit.dart';
import 'friends.dart';
import 'prevRoom.dart';
import 'appbar.dart'; // ✅ 기존 앱바 연동
import 'profile_avatar.dart';
import '../common/bottom_nav_bar.dart';

class myPageApp extends StatelessWidget {
  const myPageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: myPageMainApp(), // ✅ 마이페이지 메인 위젯
    );
  }
}

// ✅ Firestore에서 유저 데이터를 불러오는 함수
Future<Map<String, dynamic>?> fetchUserData(String userId) async {
  try {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  } catch (e) {
    print('Firestore error: $e');
    return null;
  }
}

// ✅ Firestore에서 "친구 수"를 세는 함수
Future<int> fetchAcceptedFriendCount(String userId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('friends')
      .where('status', isEqualTo: 'accepted') // 🔹 친구로 수락된 경우만
      .get();

  return snapshot.docs.length; // 🔹 문서 개수 = 친구 수
}

class myPageMainApp extends ConsumerStatefulWidget {
  const myPageMainApp({super.key});


  @override
  ConsumerState<myPageMainApp> createState() => _myPageMainAppState();
}

class _myPageMainAppState extends ConsumerState<myPageMainApp> {
  @override
  void initState() {
    super.initState();
  }

  void _refreshUserData() {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      setState(() {});
    }
  }



  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('에러 발생: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: fetchUserData(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Scaffold(
                body: Center(child: Text('사용자 데이터를 불러올 수 없습니다.')),
              );
            }

            final userData = snapshot.data!;


            int unreadCount = 3;



            // 🔹 친구 수 먼저 불러오기 → 그 안에서 스탬프 수 FutureBuilder 중첩
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('friends')
                  .where('status', isEqualTo: 'accepted')
                  .snapshots(),
              builder: (context, friendsSnapshot) {
                if (friendsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }

                final friendsCount = friendsSnapshot.data?.docs.length ?? 0;

                return FutureBuilder<int>(
                  future: getSumStampCount(user.uid),
                  builder: (context, stampSnapshot) {
                    if (stampSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    }

                    final stampCount = stampSnapshot.data ?? 0;
                    final String imagePath = getProfileImagePath(stampCount);

                    return Scaffold(
                      appBar: CustomAppBar(userId: user.uid),
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
                            _buildLicenseCard(userData, stampCount, friendsCount), // ✅ 친구 수 넘기기
                            const SizedBox(height: 20),
                            Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfileEditPage(
                                            userData: userData,
                                            stampCount: stampCount,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        _refreshUserData();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 14),
                                      backgroundColor: const Color(0xFF1E6FD9),
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
                                      'assets/mypage_images/license_character.png',
                                      height: 70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 180,
                                  height: 180,
                                  child: _buildFunctionCard(
                                    image: 'assets/mypage_images/prev_travel.png',
                                    label: '이전 여행',
                                    imageSize: 100,
                                    fontSize: 24,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PrevRoomIn(userId: userData['user_id']),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: 180,
                                  height: 180,
                                  child: _buildFunctionCard(
                                    image: 'assets/mypage_images/friends.png',
                                    label: '사귄 친구',
                                    imageSize: 100,
                                    fontSize: 24,
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FriendsPage(userData: userData),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            buildCurrentTravelCard(
                              image: 'assets/mypage_images/current_travel.png',
                              label: '진행 중인 여행',
                              description: '아직 진행 중인 여행 그룹이 있어요.',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                        bottomNavigationBar: const BottomNavBar(currentIndex: 1),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

String _formatTimestamp(dynamic timestamp) {
  if (timestamp == null) return '날짜 없음';
  try {
    final date = (timestamp as Timestamp).toDate();
    return DateFormat('yyyy.MM.dd').format(date);
  } catch (e) {
    return '날짜 오류';
  }
}





Widget _buildLicenseCard(Map<String, dynamic> userData, int stampCount, int friendsCount) {
  // int stampCount = userData['travel_success_count'] ?? 0;
  String nickname = userData['nickname'] ?? '여행자';
  String title = getTitleWithNickname(stampCount, nickname); // ✅ 여기에 추가

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
                border: Border.all(color: const Color(0xFF1E6FD9), width: 2.0),
              ),
              child: const Text(
                '랜덤 라이센스',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E6FD9),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Image.asset(getProfileImagePath(stampCount), height: 160),
                  const SizedBox(height: 8),
                  Text(
                    getTitleWithNickname(stampCount, nickname),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1E6FD9),
                    ),
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
                      nickname,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E6FD9),
                      ),
                    ),
                    Text(
                      userData['email'] ?? '이메일 없음',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 180,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1E6FD9)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                '스템프 횟수',
                                style: TextStyle(
                                  color: Color(0xFF1E6FD9),
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '${stampCount}회',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                '사귄 친구',
                                style: TextStyle(
                                  color: Color(0xFF1E6FD9),
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '$friendsCount명',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                  '발급일자: ${_formatTimestamp(userData['cdatetime'])}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: -15,
                        left: 0,
                        child: Image.asset(
                          'assets/mypage_images/stamp_icon.png',
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF1E6FD9),
                    ),
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
