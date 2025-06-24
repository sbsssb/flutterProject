import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String userId;
  const CustomAppBar({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Firestore에서 실제 읽지 않은 알림 수 가져오기

    return AppBar(
      centerTitle: true, // ✅ 제목은 항상 중앙
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Navigator.canPop(context)
          ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      )
          : null,

      title: Row(
        mainAxisSize: MainAxisSize.min, // ✅ 로고 너비만큼만 차지
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/mypage_images/logo.png',
            height: 60,
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                await FirebaseAuth.instance.signOut(); // 🔑 로그아웃
                if (context.mounted) {
                  context.go('/');
                }
              },
            ),
          ],
        ),
      ],
      // actions: [
      //   Stack(
      //     children: [
      //       IconButton(
      //         icon: const Icon(Icons.notifications_none, color: Colors.black),
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(
      //               builder: (context) => NotificationPage(userId: userId),
      //             ),
      //           );
      //         },
      //       ),
      //       if (unreadCount > 0)
      //         Positioned(
      //           right: 10,
      //           top: 10,
      //           child: Container(
      //             padding: const EdgeInsets.all(4),
      //             decoration: const BoxDecoration(
      //               shape: BoxShape.circle,
      //               color: Colors.red,
      //             ),
      //             child: Text(
      //               '$unreadCount',
      //               style: const TextStyle(color: Colors.white, fontSize: 10),
      //             ),
      //           ),
      //         ),
      //     ],
      //   ),
      // ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}