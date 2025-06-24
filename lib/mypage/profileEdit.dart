import 'package:firebase_auth/firebase_auth.dart';
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

  void _showPasswordChangeDialog(BuildContext rootContext) {
    // 🔐 입력 필드 컨트롤러들
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();

    // 🔔 팝업창 띄우기
    showDialog(
      context: rootContext, // 여기 context는 dialog용
      builder: (context) {
        return AlertDialog(
          title: const Text('비밀번호 변경'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ 기존 비밀번호 입력
                TextField(
                  controller: currentPwController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '기존 비밀번호'),
                ),
                // ✅ 새 비밀번호 입력
                TextField(
                  controller: newPwController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '새 비밀번호'),
                ),
                // ✅ 새 비밀번호 확인
                TextField(
                  controller: confirmPwController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '새 비밀번호 확인'),
                ),
              ],
            ),
          ),
          actions: [
            // 🔘 취소 버튼
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            // ✅ 저장 버튼
            ElevatedButton(
              onPressed: () async {
                final currentPw = currentPwController.text.trim();
                final newPw = newPwController.text.trim();
                final confirmPw = confirmPwController.text.trim();

                // 1. 새 비밀번호 일치 여부 확인
                if (newPw != confirmPw) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(content: Text('새 비밀번호가 일치하지 않습니다.')),
                  );
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  final email = user?.email;
                  if (email == null) throw Exception('이메일 없음');

                  // 2. 🔐 재인증
                  final credential = EmailAuthProvider.credential(
                    email: email,
                    password: currentPw,
                  );
                  await user!.reauthenticateWithCredential(credential);

                  // 3. ✅ 비밀번호 변경
                  await user.updatePassword(newPw);

                  Navigator.pop(context); // 팝업 닫기

                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
                  );
                } catch (e) {
                  print('❌ 비밀번호 변경 실패: $e');
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(content: Text('비밀번호 변경에 실패했습니다.')),
                  );
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
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
            const SizedBox(height: 55),
            Text('면허 갱신하기',
              style: TextStyle(
                fontFamily: 'Jalnan',
                color: Color(0xFF1E6FD9),
                fontSize: 25,
              ),
            ),
            const SizedBox(height: 12),

            // ✅ 가로 선 추가
            const Divider(
              color: Color(0xFF1E6FD9), // 선 색상
              thickness: 2,              // 두께
              height: 16,                // 위아래 공간 포함 전체 높이
            ),
            const SizedBox(height: 12),
            Text(
              widget.userData['email'] ?? '이메일 없음',
              style: const TextStyle(color: Color(0xFF1E6FD9)),
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
                            fontFamily: 'AstaSans',
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          getTitleWithNickname(widget.stampCount, widget.userData['nickname']),
                          style: TextStyle( // ✅ const 제거
                            fontSize: 14,
                              fontFamily: 'AstaSans',
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
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showPasswordChangeDialog(context), // ⬅️ 함수 호출
              icon: const Icon(Icons.lock_outline),
              label: const Text('비밀번호 변경', style: TextStyle(
                  fontSize: 30,
                  fontFamily: 'AstaSans',
              )),
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

                      // ✅ 닉네임 중복 체크
                      final query = await FirebaseFirestore.instance
                          .collection('users')
                          .where('nickname', isEqualTo: newNickname)
                          .get();

                      final isDuplicate = query.docs.any((doc) => doc.id != userId); // 본인 제외

                      if (isDuplicate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('이미 사용 중인 닉네임입니다.')),
                        );
                        return; // 중복이면 저장하지 않음
                      }

                      // ✅ 중복이 아니라면 저장
                      await FirebaseFirestore.instance
                          .collection('users')
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
                  '정보 저장 및 나가기',
                  style: TextStyle(fontSize: 26, fontFamily: 'Jalnan', color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}