import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vibration/vibration.dart';
import '../models/schedule_model.dart';
import '../models/stamp_log_model.dart';
import '../services/firestore_service.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/schedule_card.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';

class TravelDetailScreen extends StatefulWidget {
  final String roomId = 'gpsTest';

  const TravelDetailScreen({super.key});

  @override
  State<TravelDetailScreen> createState() => _TravelDetailScreenState();
}

class _TravelDetailScreenState extends State<TravelDetailScreen> {
  late Future<List<Schedule>> _futureSchedules;
  late ConfettiController _confettiController;

  final String userId = 'gpsTest1';
  bool _checkedDistance = false;
  Timer? _distanceTimer;

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

      //2km 이내일 경우 알림 + 진동
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
                  'assets/images/stamp-animation.gif',
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
    return Scaffold(
      appBar: AppBar(title: Text('여행 상세')),
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
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '$done / $total 완료됨',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: schedules.length,
                      itemBuilder: (context, index) {
                        final schedule = schedules[index];
                        return ScheduleCard(
                          schedule: schedule,
                          onStampPressed: () async {
                            await showStampDialog(context);

                            final log = StampLog(
                              stampId: '${userId}_${schedule.id}',
                              userId: userId,
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
                  ElevatedButton(
                    onPressed: () {
                      //일정 전체 완료 => 컨페티+축하메시지
                      if (done == total) {
                        _confettiController.play();
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text("축하합니다!"),
                                content: Text("모든 스탬프를 적립했어요!"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("여행 일정이 종료되었습니다."),
                                        ),
                                      );
                                    },
                                    child: Text("확인"),
                                  ),
                                ],
                              ),
                        );
                        //일정 일부 완료 => 확인 메시지
                      } else {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text("일정 종료"),
                                content: Text(
                                  "현재 스탬프를 $done / $total개 정립했습니다. \n 정말 종료할까요? ",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("여행 일정이 종료되었습니다."),
                                        ),
                                      );
                                    },
                                    child: Text("네, 종료할게요."),
                                  ),
                                ],
                              ),
                        );
                      }
                    },
                    child: Text("일정 종료하기"),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
