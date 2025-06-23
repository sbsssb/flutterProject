import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatefulWidget {
  final int? currentIndex;

  const BottomNavBar({super.key, this.currentIndex});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int unreadCount = 0;
  late final String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('is_read', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          unreadCount = snapshot.docs.length;
        });
      });
    }
  }
  Color resolveIconColor(int index) {
    return widget.currentIndex == index ? const Color(0xFFFACC15) : Colors.white;
  }

  TextStyle resolveLabelStyle(int index) {
    return TextStyle(
      color: widget.currentIndex == index ? const Color(0xFFFACC15) : Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex ?? 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF1E6FD9),
      selectedItemColor:
          widget.currentIndex == null ? Colors.white : const Color(0xFFFACC15),
      // 선택 없으면 노란불 감춤
      unselectedItemColor: Colors.white,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/main');
            break;
          case 1:
            if (userId != null) {
              context.go('/currentRoom/$userId');
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

      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
        const BottomNavigationBarItem(icon: Icon(Icons.map), label: '여행'),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications),
              if (unreadCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: '알림',
        ),
      ],
    );
  }
}
