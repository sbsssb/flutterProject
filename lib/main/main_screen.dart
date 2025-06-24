import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/bottom_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../dice/dice.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Future<List<Map<String, dynamic>>> _recentRooms;

  @override
  void initState() {
    super.initState();
    _waitForLoginAndListenToInvitations();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _recentRooms = getRecentJoinRooms(userId);
  }

  StreamSubscription? _invitedRoomListener;
  Set<String> _notifiedRooms = {};

  void _waitForLoginAndListenToInvitations() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    while (true) {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('members')
          .where('user_id', isEqualTo: uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print("✅ members 문서가 생성됨 → listener 붙이기 시작");
        _listenToInvitations(uid);
        break;
      }

      print("⏳ members 문서 아직 없음 → 대기 중...");
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> _handleMemberDoc(DocumentSnapshot doc) async {
    final memberData = doc.data() as Map<String, dynamic>?;
    if (memberData == null) {
      print("❌ memberData 없음 - 문서 비어 있음");
      return;
    }

    final isOwner = memberData['is_owner'] == true;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    print("👤 참여자: ${memberData['nickname']} (${memberData['user_id']}), 방장 여부: $isOwner");

    if (isOwner) {
      print("⛔ 본인이 방장이므로 알림 제외");
      return;
    }
    if (currentUid == null) {
      print("❌ currentUid 없음 - 로그인 안됨");
      return;
    }

    final parentRoomRef = doc.reference.parent.parent;
    if (parentRoomRef == null) {
      print("❌ parentRoomRef 없음 - 상위 room 문서 못 찾음");
      return;
    }

    final roomDoc = await parentRoomRef.get();
    final roomData = roomDoc.data();
    if (roomData == null) {
      print("❌ roomData 없음 - 문서 비어 있음");
      return;
    }

    final hostIsActive = roomData['host_is_active'] == true;
    final ownerId = roomData['owner_id'];
    final roomId = parentRoomRef.id;

    print("📦 방 정보 - roomId: $roomId");
    print("    host_is_active: $hostIsActive");
    print("    owner_id: $ownerId");
    print("    currentUid: $currentUid");
    print("    이미 알림 보냈나?: ${_notifiedRooms.contains(roomId)}");

    if (!hostIsActive) {
      print("⛔ 방장이 접속 중 아님 → 알림 제외");
      return;
    }

    if (currentUid == ownerId) {
      print("⛔ 내가 방장 → 알림 제외");
      return;
    }

    if (_notifiedRooms.contains(roomId)) {
      print("⛔ 이미 알림 보냄 → 중복 방지");
      return;
    }

    // ✅ 통과한 경우
    print('🎯 초대 알림 조건 만족 → roomId: $roomId');
    _notifiedRooms.add(roomId);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('notifications')
        .add({
      'type': 'invitation',
      'room_id': roomId,
      'message': '방에 초대되었습니다!',
      'timestamp': FieldValue.serverTimestamp(),
      'is_read': false,
    });

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showInvitationDialog(context, roomId);
      }
    });
  }





  void _listenToInvitations(String uid) {
    _invitedRoomListener?.cancel();

    _invitedRoomListener = FirebaseFirestore.instance
        .collectionGroup('members')
        .where('user_id', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) async {
      print("📡 실시간 초대 수신: ${snapshot.docs.length}");

      for (final doc in snapshot.docs) {
        await _handleMemberDoc(doc);
      }
    });
  }



  @override
  void dispose() {
    _invitedRoomListener?.cancel();
    super.dispose();
  }

  void _showInvitationDialog(BuildContext context, String roomId) async {
    // 🔥 Firestore에서 room_name 읽기
    final roomDoc = await FirebaseFirestore.instance
        .collection('travel_rooms')
        .doc(roomId)
        .get();

    final roomName = roomDoc.data()?['room_name'] ?? '이름 없음';

    // ✅ 다이얼로그 띄우기
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF3E0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "🎉 방 초대",
          style: TextStyle(
            fontFamily: 'Jalnan',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF333333),
          ),
        ),
        content: Text(
          "방에 초대되었습니다!\n\n방 이름: $roomName", // ✅ room_name 표시
          style: const TextStyle(
            fontFamily: 'Jalnan',
            fontSize: 16,
            color: Color(0xFF555555),
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 12),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              textStyle: const TextStyle(
                fontFamily: 'Jalnan',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                fontFamily: 'YGTZan',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              context.push('/dice/$roomId');
            },
            child: const Text("입장하기"),
          ),
        ],
      ),
    );
  }






  // 🔹 Firestore에서 최근 여행 3건 조회
  Future<List<Map<String, dynamic>>> getRecentJoinRooms(String userId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('join_rooms')
            .orderBy('cdatetime', descending: true)
            .limit(3)
            .get();

    return snapshot.docs.map((doc) {
      return {'room_id': doc['room_id'], 'region': doc['region']};
    }).toList();
  }

  //유저 정보
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  String getProfileImagePath(int count) {
    if (count >= 11) return 'assets/mypage_images/profile_gold.png';
    if (count >= 6) return 'assets/mypage_images/profile_silver.png';
    return 'assets/mypage_images/profile_bronze.png';
  }

  String getTitleWithNickname(int count, String nickname) {
    if (count >= 11) return '인간 네비게이션\n$nickname';
    if (count >= 6) return '차 멀미에 익숙한\n$nickname';
    return '집 밖을 나선\n$nickname';
  }

  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E6FD9),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            // 🔵 상단 로고/텍스트
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  const Text(
                    '어디든 좋아!',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Image.asset(
                    'assets/common_images/logo-main-ver2.png',
                    height: 150,
                  ),
                ],
              ),
            ),

            // ⚪ 콘텐츠 박스
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          context.push('/addRoom');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E6FD9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '주사위 굴리기',
                              style: TextStyle(
                                fontFamily: 'Jalnan',
                                fontSize: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Image.asset(
                              'assets/main_images/icon-dice1.png',
                              height: 50,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '나의 여행 등급',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E6FD9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 유저정보
                      FutureBuilder<Map<String, dynamic>?>(
                        future: getUserProfile(userId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return SizedBox();

                          final data = snapshot.data!;
                          final stampCount = data['stampCount'] ?? 0;
                          final nickname = data['nickname'] ?? '여행자';
                          final imagePath = getProfileImagePath(stampCount);
                          final titleText = getTitleWithNickname(stampCount, nickname);

                          return Center(
                            child: Container(
                              constraints: BoxConstraints(maxWidth: 350),
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Color(0xFFFFF9C4), // 연한 노란색
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(imagePath, height: 80),
                                  const SizedBox(width: 12),
                                  RichText(
                                    textAlign: TextAlign.left,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${titleText.split('\n').first}\n', // 칭호만
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black,
                                          ),
                                        ),
                                        TextSpan(
                                          text: titleText.split('\n').last, // 닉네임만
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '최근 여행',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E6FD9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _recentRooms,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          final rooms = snapshot.data!;
                          if (rooms.isEmpty) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(3, (index) => _emptyRegionSlot(index)),
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(3, (index) {
                              if (index < rooms.length) {
                                final room = rooms[index];
                                return _regionItem(
                                  context,
                                  room['region'],
                                  room['room_id'],
                                );
                              } else {
                                return _emptyRegionSlot(index); // 빈 슬롯
                              }
                            }),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      ElevatedButton(
                        onPressed: () {
                          context.push('/festival');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E6FD9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "축제 구경가기",
                              style: TextStyle(
                                fontFamily: 'Jalnan',
                                fontSize: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Image.asset(
                              'assets/main_images/icon-festival.png',
                              height: 50,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 지역 아이템 위젯
  Widget _regionItem(BuildContext context, String region, String roomId) {
    return GestureDetector(
      onTap: () {
        context.push('/detail/$roomId');
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Color(0xFF1E6FD9), width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              region,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 6),
            Image.asset('assets/main_images/icon-dice2.png', height: 50),
          ],
        ),
      ),
    );
  }

  Widget _emptyRegionSlot(int index) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("어디든\n떠나볼까?", textAlign: TextAlign.center),
            Image.asset('assets/main_images/character.png', height: 45),
          ],
        ),
      ),
    );
  }
}
