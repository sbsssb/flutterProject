import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FestivalTopBar extends StatelessWidget {
  final String currentTab; // 'list' 또는 'calendar'

  const FestivalTopBar({super.key, required this.currentTab});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Image.asset('assets/common_images/logo-main-ver1.png', height: 100), // 로고 이미지
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => context.go('/festivalList'),
              child: Text(
                '축제 목록',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                  color: currentTab == 'list' ? Colors.blue : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 80),
            GestureDetector(
              onTap: () => context.go('/festivalCalendar'),
              child: Text(
                '축제 달력',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                  color: currentTab == 'calendar' ? Colors.blue : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}