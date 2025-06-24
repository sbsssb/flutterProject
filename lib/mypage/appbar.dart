import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'notification.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String userId;

  const CustomAppBar({super.key, required this.userId});

  Future<void> handleLogout(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (user != null) {
        // ✅ 구글 로그인인 경우 Google 로그아웃도 수행
        for (var info in user.providerData) {
          if (info.providerId == 'google.com') {
            // Google 로그아웃
            await GoogleSignIn().signOut();
            break;
          }
        }

        // ✅ Firebase 로그아웃
        await FirebaseAuth.instance.signOut();
      }

      // ✅ 로그인 페이지로 이동
      if (context.mounted) {
        context.go('/'); // 또는 context.go('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 중 오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Firestore에서 실제 읽지 않은 알림 수 가져오기
    final int unreadCount = 3; // 지금은 임시 하드코딩

    return AppBar(
      centerTitle: true,
      // ✅ 제목은 항상 중앙
      backgroundColor: Colors.white,
      elevation: 0,
      leading:
          Navigator.canPop(context)
              ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
              : null,

      title: Row(
        mainAxisSize: MainAxisSize.min, // ✅ 로고 너비만큼만 차지
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Image.asset('assets/mypage_images/logo.png', height: 60)],
      ),

      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: (){
                handleLogout(context);
              }
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
