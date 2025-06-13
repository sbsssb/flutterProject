import 'package:flutter/material.dart';

Widget buildStampHeader(int done, int total) {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/stamp_images/stamp-icon.png', width: 80),
          const SizedBox(width: 8),
          Text(
            '$done / $total개',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E6FD9),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),

      Transform.translate(
        offset: const Offset(0, -20), // 위로 20px 겹치기
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E6FD9),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Text(
            '나의 일정',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      const SizedBox(height: 10), // 여백 조절
    ],
  );
}
