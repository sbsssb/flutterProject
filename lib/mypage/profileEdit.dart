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


    nicknameController = TextEditingController(
      text: widget.userData['nickname'] ?? '',
    );
    phoneController = TextEditingController(
      text: widget.userData['phone'] ?? '',
    );
  }

  void _showPasswordChangeDialog(BuildContext rootContext) {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();


    showDialog(
      context: rootContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('비밀번호 변경'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                TextField(
                  controller: currentPwController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '기존 비밀번호'),
                ),

                TextField(
                  controller: newPwController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '새 비밀번호'),
                ),

                TextField(
                  controller: confirmPwController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '새 비밀번호 확인'),
                ),
              ],
            ),
          ),
          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),

            ElevatedButton(
              onPressed: () async {
                final currentPw = currentPwController.text.trim();
                final newPw = newPwController.text.trim();
                final confirmPw = confirmPwController.text.trim();


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


                  final credential = EmailAuthProvider.credential(
                    email: email,
                    password: currentPw,
                  );
                  await user!.reauthenticateWithCredential(credential);


                  await user.updatePassword(newPw);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
                  );
                } catch (e) {
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
    return Scaffold(

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 55),
            Text('프로필 수정하기',
              style: TextStyle(
                fontFamily: 'Jalnan',
                color: Color(0xFF1E6FD9),
                fontSize: 25,
              ),
            ),
            const SizedBox(height: 12),


            const Divider(
              color: Color(0xFF1E6FD9),
              thickness: 2,
              height: 16,
            ),
            const SizedBox(height: 12),
            Text(
              widget.userData['email'] ?? '이메일 없음',
              style: const TextStyle(color: Color(0xFF1E6FD9)),
            ),
            const SizedBox(height: 12),
            Image.asset(getProfileImagePath(widget.stampCount), height: 240),
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
                          style: TextStyle(
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
              onPressed: () => _showPasswordChangeDialog(context),
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
                    final userId = widget.userData['user_id'];
                    final newNickname = nicknameController.text.trim();
                    final newPhone = phoneController.text.trim();


                    final query = await FirebaseFirestore.instance
                        .collection('users')
                        .where('nickname', isEqualTo: newNickname)
                        .get();

                    final isDuplicate = query.docs.any((doc) => doc.id != userId);

                    if (isDuplicate) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('이미 사용 중인 닉네임입니다.')),
                      );
                      return;
                    }


                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .update({
                      'nickname': newNickname,
                      'phone': newPhone,
                    });


                    Navigator.pop(context, true);
                  } catch (e) {
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