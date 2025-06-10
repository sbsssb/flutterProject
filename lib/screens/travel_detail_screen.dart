import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/firestore_service.dart';
import 'package:geolocator/geolocator.dart';


class TravelDetailScreen extends StatefulWidget {
  final String roomId = 'gpsTest';
  const TravelDetailScreen({super.key});

  @override
  State<TravelDetailScreen> createState() => _TravelDetailScreenState();
}

class _TravelDetailScreenState extends State<TravelDetailScreen> {
  late Future<List<Schedule>> _futureSchedules;

  @override
  void initState() {
    super.initState();
    _futureSchedules = FirestoreService.getSchedules(widget.roomId);

  }

  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied){
      permission = await Geolocator.requestPermission();
      if(permission == LocationPermission.denied){
        print("위치 권한이 거부되었습니다.");
        return false;
      }
    }
    if(permission == LocationPermission.deniedForever){
      print("위치 권한이 영구적으로 거부되었습니다. 설정에서 허용해야 합니다.");
      return false;
    }
    print("위치 권한 허용됨");
    return true;
  }

  Future<void> checkDistance(List<Schedule> schedules) async {
    bool granted = await requestLocationPermission();
    if(!granted) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    for (var schedule in schedules) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        schedule.lat,
        schedule.lng,
      );
      print('[${schedule.title}]와의 거리 : ${distance.toStringAsFixed(2)}m');
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('여행 상세'),),
      body: FutureBuilder<List<Schedule>>(
          future: _futureSchedules,
          builder: (context, snapshot) {
            if(snapshot.connectionState == ConnectionState.waiting){
              return Center(child: CircularProgressIndicator());
            }
            if(!snapshot.hasData || snapshot.data!.isEmpty){
              return Center(child: Text("일정이 없습니다."));
            }

            final schedules = snapshot.data!;
            WidgetsBinding.instance.addPostFrameCallback((_){
              checkDistance(schedules);
            });
            return ListView.builder(

                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  return ListTile(
                    title: Text(schedule.title),
                    subtitle: Text(schedule.placeName),
                    trailing: schedule.isDone
                        ? Icon(Icons.check_circle, color: Colors.green,)
                        : Icon(Icons.circle_outlined),
                  );
                },
            );
          },
      ),
    );
  }
}

