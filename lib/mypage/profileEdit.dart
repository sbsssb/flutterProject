import 'package:flutter/material.dart';
import 'appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_avatar.dart';
import '../common/bottom_nav_bar.dart';

class ProfileEditPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final int stampCount;
  const ProfileEditPage({super.key, required this.userData, required this.stampCount});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late TextEditingController nicknameController;
  late TextEditingController phoneController;
  @override
  void initState() {
    super.initState();

    // 넘겨받은 userData를 기반으로 컨트롤러 초기화
    nicknameController = TextEditingController(
      text: widget.userData['nickname'] ?? '',
    );
    phoneController = TextEditingController(
      text: widget.userData['phone'] ?? '',
    );
  }


  @override
  Widget build(BuildContext context) {
    print('✅ 프로필 수정 페이지 userData: ${widget.userData}');
    return Scaffold(
      // appBar: CustomAppBar(userId: userId),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            Text(
              widget.userData['email'] ?? '이메일 없음',
              style: const TextStyle(color: Colors.blue),
            ),
            const SizedBox(height: 12),
            Image.asset(getProfileImagePath(widget.stampCount), height: 240), // 추후 수정 예정
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage(
                          getTitleBackground(widget.stampCount),
                        ),
                        alignment: Alignment.centerRight,
                        opacity: 0.25,
                        fit: BoxFit.contain,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '칭호',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          getTitleWithNickname(widget.stampCount, widget.userData['nickname']),
                          style: TextStyle( // ✅ const 제거
                            fontSize: 14,
                            color: Color(0xFF1E6FD9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nicknameController,
                    decoration: const InputDecoration(labelText: '닉네임'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('변경'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: '전화번호',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('저장'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.lock_outline),
              label: const Text('비밀번호 변경', style: TextStyle(fontSize: 22)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E6FD9),
                side: const BorderSide(color: Color(0xFF1E6FD9)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final userId = widget.userData['user_id']; // 문서 ID로 사용
                      final newNickname = nicknameController.text.trim();
                      final newPhone = phoneController.text.trim();

                      await FirebaseFirestore.instance
                          .collection('users') // 너희 앱 구조에 따라 수정 가능
                          .doc(userId)
                          .update({
                        'nickname': newNickname,
                        'phone': newPhone,
                      });

                      // ✅ 저장 완료 후 이전 화면(MyPage)으로 돌아가면서 true를 반환
                      Navigator.pop(context, true);
                    } catch (e) {
                      print('❌ 저장 실패: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('저장 중 오류가 발생했습니다.')),
                      );
                    }
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E6FD9),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text(
                  '정보 저장',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}