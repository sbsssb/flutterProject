import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../common/logo_header.dart';

class FestivalTopBar extends StatelessWidget {
  final String currentTab;

  const FestivalTopBar({super.key, required this.currentTab});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const LogoHeader(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => context.go('/festival'),
              child: Text(
                '축제 목록',
                style: TextStyle(
                  fontFamily: 'Jalnan',
                  fontSize: 22,
                  color: currentTab == 'list'
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 80),
            GestureDetector(
              onTap: () => context.go('/festivalCalendar'),
              child: Text(
                '축제 달력',
                style: TextStyle(
                  fontFamily: 'Jalnan',
                  fontSize: 22,
                  color: currentTab == 'calendar'
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}