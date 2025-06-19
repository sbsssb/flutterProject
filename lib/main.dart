import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ 추가
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutterteam4/album/album_page.dart';
import 'firebase_options.dart';
import 'festival/festival_list_page.dart';
import 'user/login_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutterteam4/travelroom/addRoom.dart';
import 'package:flutterteam4/travellist/ScheduleRequestPage.dart';
import 'package:flutterteam4/mypage/myPage.dart';
import 'package:flutterteam4/user/login_page.dart';
import 'package:flutterteam4/stamp/screens/stamp_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterteam4/dice/dice.dart'; // ✅ 주사위판 페이지 import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']!);
  runApp(const ProviderScope(child: MyApp()));
}

final GoRouter router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => LoginPage()),
    GoRoute(path: '/addRoom', builder: (context, state) => const RoomCreate()),
    GoRoute(path: '/mainPage', builder: (context, state) => const MainPageWrapper()),
    GoRoute(path: '/festival', builder: (context, state) => const FestivalListPage()),
    // GoRoute(path: '/album', builder: (context, state) => const AlbumPage()),
    // GoRoute(path: '/myPage', builder: (context, state) => const MyPage()),
    // GoRoute(path: '/stampDetail', builder: (context, state) => const StampDetailScreen()),
    GoRoute(
      path: '/dice/:roomId',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        return DoubleDiceOnBoard(roomId: roomId);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
    );
  }
}

class MainPageWrapper extends StatefulWidget {
  const MainPageWrapper({super.key});

  @override
  State<MainPageWrapper> createState() => _MainPageWrapperState();
}

class _MainPageWrapperState extends State<MainPageWrapper> {
  StreamSubscription<QuerySnapshot>? _invitedRoomListener;
  @override
  void initState() {
    super.initState();
    _waitForLoginAndListenToInvitations(); // ✅ 로그인 후 스트림 시작
  }

  void _waitForLoginAndListenToInvitations() {
    // 하드코딩된 UID로 바로 리스너 실행
    const hardcodedUid = 'zNhdAIu8B1T7reLzyDwQ';
    print("✅ 하드코딩된 UID로 감시 시작: $hardcodedUid");
    _listenToInvitations(hardcodedUid);
  }



  // void _waitForLoginAndListenToInvitations() {
  //   FirebaseAuth.instance.authStateChanges().listen((user) {
  //     if (user != null) {
  //       print("✅ 로그인 감지됨, UID: ${user.uid}");
  //       _listenToInvitations(user.uid);
  //     }
  //   });
  // }

  void _listenToInvitations(String uid) {
    _invitedRoomListener?.cancel();

    _invitedRoomListener = FirebaseFirestore.instance
        .collectionGroup('members')
        .where('user_id', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isEmpty) {
        print("📭 members 문서 없음");
        return;
      }

      for (final doc in snapshot.docs) {
        final memberData = doc.data();
        final isOwner = memberData['is_owner'] == true;
        final memberPath = doc.reference.path;
        print("🔍 members 문서 확인: $memberPath");
        print("   └ is_owner: $isOwner");

        if (isOwner) {
          print("🙅‍♂️ members 기준 방장이므로 무시");
          continue;
        }

        final parentRoomRef = doc.reference.parent.parent;
        if (parentRoomRef == null) {
          print("⚠️ parentRoomRef가 null");
          continue;
        }

        final roomDoc = await parentRoomRef.get();
        final roomData = roomDoc.data();
        if (roomData == null) {
          print("⚠️ roomData 없음");
          continue;
        }

        final hostIsActive = roomData['host_is_active'] == true;
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        final ownerId = roomData['owner_id'];
        final roomId = parentRoomRef.id;

        print("📦 room 문서 확인: $roomId");
        print("   └ hostIsActive: $hostIsActive");
        print("   └ room.owner_id: $ownerId");
        print("   └ currentUid: $currentUid");

        if (!hostIsActive) {
          print("❌ host_is_active == false → 무시");
          continue;
        }

        if (currentUid == ownerId) {
          print("🙅‍♂️ 방 document 기준 방장 → 무시");
          continue;
        }

        print('🎯 초대 알림 조건 만족! → roomId: $roomId');

        if (!mounted) return;
        _showInvitationDialog(context, roomId);
        break;
      }
    });
  }









  void _showInvitationDialog(BuildContext context, String roomId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🎉 방 초대"),
        content: Text("방에 초대되었습니다!\n방 ID: $roomId"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // 닫기
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 먼저 닫고
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoubleDiceOnBoard(roomId: roomId),
                ),
              );
            },
            child: const Text("입장하기"),
          ),
        ],
      ),
    );
  }



  @override
  void dispose() {
    _invitedRoomListener?.cancel(); // ✅ 리스너 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MainPage();
  }
}


class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('임시 메인 페이지'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                GoRouter.of(context).go('/addRoom');
              },
              child: const Text("방 만들기"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                GoRouter.of(context).go('/festival');
              },
              child: const Text("축제 페이지"),
            ),

          ],
        ),
      ),
    );
  }
}
