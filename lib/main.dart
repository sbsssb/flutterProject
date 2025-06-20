import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ 축제 달력 한글화 import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutterteam4/travelroom/travelDetail.dart';
import 'package:flutterteam4/utils/app_theme.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutterteam4/album/album_page.dart';
import 'firebase_options.dart';
import 'festival/festival_list_page.dart';
import 'festival/festival_calendar_page.dart';
import 'festival_detail/festival_detail_page.dart';
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
import 'main/main_screen.dart';
import 'utils/app_theme.dart'; // 👈 테마 임포트 추가
import 'mypage/prevRoom.dart';
import 'mypage/myPage.dart';
import 'mypage/notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']!);
  runApp(const ProviderScope(child: MyApp()));
}

final GoRouter router = GoRouter(
  initialLocation: '/main', // 초기 진입점
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final goingTo = state.matchedLocation;
    
    // 로그인했는데 login 접근 시 메인으로
    if (user != null && goingTo == '/login') return '/main';

    // 그 외엔 허용
    return null;
  },

  routes: [
    GoRoute(path: '/login', builder: (context, state) => LoginPage()),
    GoRoute(path: '/main', builder: (context, state) => const MainScreen()),
    GoRoute(path: '/addRoom', builder: (context, state) => const RoomCreate()),
    GoRoute(path: '/festivalList', builder: (context, state) => const FestivalListPage()),
    GoRoute(path: '/festivalCalendar', builder: (context, state) => const FestivalCalendarPage()),
    GoRoute(
      path: '/festivalDetail/:contentId',
      builder: (context, state) {
        final contentId = state.pathParameters['contentId']!;
        final contentTypeId = int.tryParse(state.uri.queryParameters['type'] ?? '15') ?? 15;
        return FestivalDetailPage(
          contentId: contentId,
          contentTypeId: contentTypeId,
        );
      },
    ), // ✅ 상세 페이지 이동 시 contentId와 contentTypeId을 넘김
    GoRoute(
      path: '/festival',
      builder: (context, state) => const FestivalListPage(),
    ),
    GoRoute(
      path: '/dice/:roomId',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        return DoubleDiceOnBoard(roomId: roomId);
      },
    ),
    GoRoute(
      path: '/album/:roomId/:uploaderId',
      name: 'album',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        final uploaderId = state.pathParameters['uploaderId']!;
        return AlbumPage(roomId: roomId, uploaderId: uploaderId);
      },
    ),
    GoRoute(
      path: '/stamp',
      builder: (context, state) {
        final roomId = state.uri.queryParameters['roomId']!;
        return StampDetailScreen(roomId: roomId);
      },
    ),
    GoRoute(
      path: '/detail/:roomId',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        return TravelRoomDetailPage(roomId: roomId);
      },
    ),
    GoRoute(path: '/mypage', builder: (context, state) => const myPageApp()),
    GoRoute(
      path: '/prevRoom/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return PrevRoomApp(userId: userId);
      },
    ),
    GoRoute(
      path: '/notification/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return NotificationPage(userId: userId);
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
      theme: AppTheme.mainTheme, // ✅ 여기서 테마(폰트, 색상) 적용
      // ✅ 축제 달력 한글화 코드
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
    _startInvitationPolling('zNhdAIu8B1T7reLzyDwQ');
  }

  void _waitForLoginAndListenToInvitations() async {
    const uid = 'zNhdAIu8B1T7reLzyDwQ';

    while (true) {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('members')
          .where('user_id', isEqualTo: uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print("✅ members 문서가 생성됨 → listener 붙이기 시작");
        _listenToInvitations(uid); // 🔥 이때부터 실시간 감지 시작!
        break;
      }

      print("⏳ members 문서 아직 없음 → 대기 중...");
      await Future.delayed(const Duration(seconds: 1));
    }
  }


  // void _waitForLoginAndListenToInvitations() {
  //   FirebaseAuth.instance.authStateChanges().listen((user) {
  //     if (user != null) {
  //       print("✅ 로그인 감지됨, UID: ${user.uid}");
  //       _listenToInvitations(user.uid);
  //     }
  //   });
  // }

  Set<String> _notifiedRooms = {}; // 중복 방지용
  bool _initialCheckDone = false;

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








  Future<void> _handleMemberDoc(DocumentSnapshot doc) async {
    final memberData = doc.data() as Map<String, dynamic>?;
    if (memberData == null) return;

    final isOwner = memberData['is_owner'] == true;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (isOwner || currentUid == null) return;

    final parentRoomRef = doc.reference.parent.parent;
    if (parentRoomRef == null) return;

    final roomDoc = await parentRoomRef.get();
    final roomData = roomDoc.data();
    if (roomData == null) return;

    final hostIsActive = roomData['host_is_active'] == true;
    final ownerId = roomData['owner_id'];
    final roomId = parentRoomRef.id;

    // 🔁 중복 알림 방지
    print("🧪 조건 체크");
    print("  hostIsActive: $hostIsActive");
    print("  currentUid: $currentUid");
    print("  ownerId: $ownerId");
    print("  notifiedRooms.contains: ${_notifiedRooms.contains(roomId)}");

    // 조건 체크 전에 강제로 제거 (테스트용)
    _notifiedRooms.remove(roomId);

    // 🔁 중복 알림 방지
    if (!hostIsActive || currentUid == ownerId || _notifiedRooms.contains(roomId)) return;
    // if (currentUid == ownerId || _notifiedRooms.contains(roomId)) return;

    print('🎯 초대 알림 조건 만족 → roomId: $roomId');
    _notifiedRooms.add(roomId);

    if (!mounted) return;

// 🔒 안전하게 다이얼로그 띄우기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print("📢 다이얼로그 진짜 호출 직전");
        _showInvitationDialog(context, roomId);
      }
    });
  }
  void _startInvitationPolling(String uid) {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('members')
          .where('user_id', isEqualTo: uid)
          .get();

      for (final doc in snapshot.docs) {
        await _handleMemberDoc(doc); // 🔁 조건 검사해서 다이얼로그 띄우기
      }
    });

    print("✅ 초대 polling 시작 (5초 간격)");
  }








  void _showInvitationDialog(BuildContext context, String roomId) {
    print("📢 _showInvitationDialog called");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("📢 addPostFrameCallback → 실행됨");
      if (!context.mounted) {
        print("❌ context가 유효하지 않음 → 다이얼로그 스킵");
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("🎉 방 초대"),
          content: Text("방에 초대되었습니다!\n방 ID: $roomId"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
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
    });
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
