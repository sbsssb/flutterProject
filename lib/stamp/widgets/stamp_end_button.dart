// lib/widgets/travel_end_button.dart
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

Widget buildStampEndButton({
  required BuildContext context,
  required int done,
  required int total,
  required ConfettiController confettiController,
}) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1E6FD9),
      side: const BorderSide(color: Color(0xFF1E6FD9),width: 3.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
    onPressed: () {
      if (done == total) {
        confettiController.play();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("축하합니다!"),
            content: const Text("모든 스탬프를 적립했어요!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("여행 일정이 종료되었습니다.")),
                  );
                },
                child: const Text("확인"),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("일정 종료"),
            content: Text("현재 스탬프를 $done / $total개 적립했습니다. \n정말 종료할까요?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("여행 일정이 종료되었습니다.")),
                  );
                },
                child: const Text("네, 종료할게요."),
              ),
            ],
          ),
        );
      }
    },
    child: const Text("일정 끝내기", style: TextStyle(fontSize: 18),),
  );
}
