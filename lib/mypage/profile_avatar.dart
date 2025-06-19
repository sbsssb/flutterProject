/// 스탬프 수에 따라 아바타 이미지 경로 반환
import 'package:cloud_firestore/cloud_firestore.dart';

/// ✅ 유저 ID로 총 스탬프 수를 반환하는 함수 약식으로 가져옴
Future<int> getSumStampCount(String userId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final data = snapshot.data();
    final stampCount = data?['stampCount'] ?? 0;

    return stampCount;
  } catch (e) {
    print('🔥 getSumStampCount 에러: $e');
    return 0;
  }
}

// // 트레블 룸의 전체 컬렉션 가져옴
// Future<int> getTotalStampCount(String userId) async {
//   int total = 0;
//
//   // travel_rooms라는 컬렉션 전체를 가져와
//   final travelRoomsSnapshot = await FirebaseFirestore.instance
//       .collection('travel_rooms')
//       .get();
//
//   // 각 여행방마다 stamp_logs 안에서 user_id가 내가 찾는 유저일 때만 개수 셈
//   for (var roomDoc in travelRoomsSnapshot.docs) {
//     final stampLogsSnapshot = await roomDoc.reference
//         .collection('stamp_logs')
//         .where('user_id', isEqualTo: userId)
//         .get();
//
//     total += stampLogsSnapshot.size;
//   }
//
//   return total;
// }

/// ✅ 스탬프 수에 따라 아바타 이미지 경로 반환
String getProfileImagePath(int stampCount) {
  final count = stampCount ?? 0;
  if (count >= 11) {
    return 'assets/mypage_images/profile_gold.png';
  } else if (count >= 6) {
    return 'assets/mypage_images/profile_silver.png';
  } else {
    return 'assets/mypage_images/profile_bronze.png';
  }
}

/// ✅ 스탬프 수에 따라 칭호 반환
String getTitleWithNickname(int stampCount, String nickname) {
  final count = stampCount ?? 0;
  if (count >= 11) {
    return '인간 네비게이션\n$nickname';
  } else if (count >= 6) {
    return '차 멀미에 익숙한\n$nickname';
  } else {
    return '집 밖을 나선\n$nickname';
  }
}



/// ✅ 스탬프 수에 따라 칭호 배경 변동
String getTitleBackground(int stampCount) {
  final count = stampCount ?? 0;
  if (count >= 11) {
    return 'assets/mypage_images/tier_SSR.png';
  } else if (count >= 6) {
    return 'assets/mypage_images/tier_SR.png';
  } else {
    return 'assets/mypage_images/tier_R.png';
  }
}