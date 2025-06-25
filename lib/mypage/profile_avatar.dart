
import 'package:cloud_firestore/cloud_firestore.dart';


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
    return 0;
  }
}




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