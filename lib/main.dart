import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ 추가
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutterteam4/travelroom/travelDetail.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutterteam4/album/album_page.dart';
import 'common/mainPage.dart';
import 'firebase_options.dart';
import 'festival/festival_list_page.dart';
import 'user/login_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutterteam4/travelroom/addRoom.dart';
import 'package:flutterteam4/travellist/ScheduleRequestPage.dart';
import 'package:flutterteam4/mypage/myPage.dart';
import 'package:flutterteam4/user/login_page.dart';
import 'package:flutterteam4/stamp/screens/stamp_detail_screen.dart';

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
    // case1 : 기본 페이지
    GoRoute(path: '/', builder: (context, state) => LoginPage()),
    GoRoute(path: '/addRoom', builder: (context, state) => const RoomCreate()),
    GoRoute(path: '/mainPage', builder: (context, state) => const MainPage()),
    GoRoute(path: '/festival', builder: (context, state) => const FestivalListPage()),
    GoRoute(
      path: '/stamp',
      builder: (context, state) {
        final roomId = state.uri.queryParameters['roomId']!;
        return StampDetailScreen(roomId: roomId);
      },
    ),
    GoRoute(path: '/stamp', builder: (context, state) => const StampDetailScreen()),
    GoRoute(path: '/album', builder: (context, state) => const AlbumPage()),
    GoRoute(path: '/detail', builder: (context, state) => const TravelRoomDetailPage(roomId: 'Uutz9iJoJJgoa93dHoDi')),

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


