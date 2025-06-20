import 'package:flutter/material.dart';

class LogoHeader extends StatelessWidget {
  final double topPadding;
  final double bottomPadding;

  const LogoHeader({
    super.key,
    this.topPadding = 50,
    this.bottomPadding = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: topPadding),
        Image.asset(
          'assets/common_images/logo-main-ver1.png',
          height: 100,
          fit: BoxFit.contain,
        ),
        SizedBox(height: bottomPadding),
      ],
    );
  }
}