import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:go_router/go_router.dart';
import 'package:flutterteam4/travelroom/addRoom.dart';
import 'package:flutterteam4/travellist/ScheduleRequestPage.dart';
import 'package:flutterteam4/stamp/screens/stamp_detail_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

final GoRouter router = GoRouter(
  routes: [
    // case1 : 기본 페이지
    // GoRoute(path: '/', builder: (context, state) => RoomCreate()),
    GoRoute(path: '/', builder: (context, state) => StampDetailScreen()),

  ],
);


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
    );
  }
}


