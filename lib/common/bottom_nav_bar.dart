import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  final int? currentIndex; // null 허용

  const BottomNavBar({super.key, this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    Color resolveIconColor(int index) {
      return currentIndex == index ? const Color(0xFFFACC15) : Colors.white;
    }

    TextStyle resolveLabelStyle(int index) {
      return TextStyle(
        color: currentIndex == index ? const Color(0xFFFACC15) : Colors.white,
      );
    }

    return BottomNavigationBar(
      currentIndex: currentIndex ?? 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF1E6FD9),
      selectedItemColor: const Color(0xFFFACC15),
      unselectedItemColor: Colors.white,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/main');
            break;
          case 1:
            if (userId != null) {
              context.go('/prevRoom/$userId');
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
              context.go('/login');
            }
            break;
          case 2:
            if (userId != null) {
              context.go('/mypage');
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
              context.go('/login');
            }
            break;
          case 3:
            if (userId != null) {
              context.go('/notification/$userId');
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
              context.go('/login');
            }
            break;
        }
      },

      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: '여행'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: '알림'),
      ],
    );
  }
}
