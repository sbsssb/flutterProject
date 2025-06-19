import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vibration/vibration.dart';
import '../../models/schedule_model.dart';
import '../../models/stamp_log_model.dart';
import '../services/firestore_service.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/stamp_card.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import '../widgets/stamp_header.dart';
import '../widgets/stamp_end_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../user/user_provider.dart';

class StampDetailScreen extends ConsumerStatefulWidget {
  final String roomId;

  const StampDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<StampDetailScreen> createState() => _StampDetailScreenState();
}

class _StampDetailScreenState extends ConsumerState<StampDetailScreen> {
  late Future<List<Schedule>> _futureSchedules;
  late ConfettiController _confettiController;
  bool _checkedDistance = false;
  Timer? _distanceTimer;
  late String? userId;


  //위치 권한 허용
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("위치 권한이 거부되었습니다.");
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print("위치 권한이 영구적으로 거부되었습니다. 설정에서 허용해야 합니다.");
      return false;
    }
    print("위치 권한 허용됨");
    return true;
  }

  //거리 계산
  Future<void> checkDistance(List<Schedule> schedules) async {
    bool granted = await requestLocationPermission();
    if (!granted) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    for (var schedule in schedules) {
      if (schedule.isDone) continue;

      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        schedule.lat,
        schedule.lng,
      );

      print('[${schedule.title}]와의 거리 : ${distance.toStringAsFixed(2)}m');

      //1km 이내일 경우 알림 + 진동
      if (distance <= 2000) {
        //이미 알림 안 울렸을 경우에만
        if (!schedule.canStampAlreadyNoti) {
          print('알림 조건 만족 => ${schedule.title}');
          schedule.canStamp = true;
          schedule.canStampAlreadyNoti = true;
          await showStampNotificaions(schedule.title);
          Vibration.vibrate(duration: 1000);
        }
      } else {
        //거리 벗어나면 다시 알림 가능 상태로 전환
        schedule.canStampAlreadyNoti = false;
        schedule.canStamp = false;
      }
    }
    setState(() {});
  }

  //알림 초기화
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void initializeNotifications() async {
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  //알림 보내기
  Future<void> showStampNotificaions(String title) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'stamp_channel',
          '스탬프 알림',
          channelDescription: '스탬프 적립 안내 알림 채널입니다',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      '스탬프 적립 가능!',
      '$title 일정에 도착했습니다.',
      platformChannelSpecifics,
    );
  }

  //도장 gif 보여주기
  Future<void> showStampDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/stamp_images/stamp-animation.gif',
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 10),
                const Text('스탬프 적립 중', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
    );
    await Future.delayed(const Duration(seconds: 2));
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _futureSchedules = FirestoreService.getSchedules(widget.roomId);
    initializeNotifications();
    _confettiController = ConfettiController(duration: Duration(seconds: 3));
    print('roomId: ${widget.roomId}');

    //30초 마다 거리 체크
    _distanceTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      final schedules = await _futureSchedules;
      await checkDistance(schedules);
    });
  }

  @override
  void dispose() {
    _distanceTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    userId = user?.uid;
    if (userId == null) {
      return const Center(child: Text("로그인이 필요합니다"));
    }

    return Scaffold(
      body: FutureBuilder<List<Schedule>>(
        future: _futureSchedules,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("일정이 없습니다."));
          }

          final schedules = snapshot.data!;
          final total = schedules.length;
          final done = schedules.where((s) => s.isDone).length;

          if (!_checkedDistance) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              checkDistance(schedules);
              _checkedDistance = true;
            });
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: 180,
                child: Container(
                  //노란색 박스
                  decoration: BoxDecoration(
                    color: Color(0xFFFACC15),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: schedules.length,
                          itemBuilder: (context, index) {
                            final schedule = schedules[index];
                            return StampCard(
                              schedule: schedule,
                              onStampPressed: () async {
                                await showStampDialog(context);

                                final log = StampLog(
                                  stampId: '${userId}_${schedule.id}',
                                  userId: userId!,
                                  scheduleId: schedule.id,
                                  cdatetime: DateTime.now(),
                                );

                                await FirestoreService.addStampLog(
                                  roomId: widget.roomId,
                                  log: log,
                                );
                                await FirestoreService.markScheduleDone(
                                  roomId: widget.roomId,
                                  scheduleId: schedule.id,
                                );

                                Fluttertoast.showToast(msg: '스탬프가 적립되었습니다!');

                                setState(() {
                                  schedule.isDone = true;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      //종료 버튼
                      buildStampEndButton(
                        context: context,
                        done: done,
                        total: total,
                        confettiController: _confettiController,
                        roomId: widget.roomId,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              //컨페티 효과
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 100,
                  emissionFrequency: 0.05,
                  gravity: 0.3,
                ),
              ),
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: buildStampHeader(done, total),
              ),
            ],
          );
        },
      ),
    );
  }
}
