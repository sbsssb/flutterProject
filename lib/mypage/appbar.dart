import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String userId;
  const CustomAppBar({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Firestore에서 실제 읽지 않은 알림 수 가져오기
    final int unreadCount = 3; // 지금은 임시 하드코딩 (테스트용)

    return AppBar(
      centerTitle: false,
      title: Padding(
        padding: const EdgeInsets.only(left: 100.0, top: 11.0),
        child: Image.asset(
          'assets/mypage_images/logo.png',
          height: 70,
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationPage(userId: userId),
                  ),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}