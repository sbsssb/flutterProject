// lib/widgets/travel_end_button.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';


Widget buildStampEndButton({
  required BuildContext context,
  required int done,
  required int total,
  required String roomId,
  required String userId,
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
      Future<void> handleEndTrip() async {
        // 1. 여행방 is_done 업데이트
        await FirebaseFirestore.instance
            .collection('travel_rooms')
            .doc(roomId)
            .update({'is_done': true});
        // 2. 사용자 stampCount 누적 업데이트
        final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
        final userSnapshot = await userRef.get();
        final currentStampCount = userSnapshot.data()?['stampCount'] ?? 0;
        final newStampCount = currentStampCount + done;

        await userRef.update({'stampCount' : newStampCount});
        // 3. 화면 이동 및 알림
        context.go('/main');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("여행 일정이 종료되었습니다.")),
        );
      }

      if (done == total) {
        confettiController.play();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("축하합니다!"),
            content: const Text("모든 스탬프를 적립했어요!"),
            actions: [
              TextButton(
                onPressed: () async {
                  await handleEndTrip();
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
                onPressed: () async {
                  await handleEndTrip();
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
