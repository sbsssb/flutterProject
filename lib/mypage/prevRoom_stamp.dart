import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../common/bottom_nav_bar.dart';

class PrevRoomStampPage extends StatelessWidget {
  final String roomId;

  const PrevRoomStampPage({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    final scheduleStream = FirebaseFirestore.instance
        .collection('travel_rooms')
        .doc(roomId)
        .collection('schedules')
        .orderBy('start')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('스탬프 보기',style: TextStyle(
          fontFamily: 'Jalnan',
        ),),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF1E6FD9),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.secondary,
        child: StreamBuilder<QuerySnapshot>(
          stream: scheduleStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final schedules = snapshot.data!.docs;
            final total = schedules.length;

            final done = schedules.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['is_done'] == true;
            }).length;

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(done, total),
                  const SizedBox(height: 16),
                  ...schedules.asMap().entries.map((entry) {
                    final index = entry.key;
                    final doc = entry.value;
                    final data = doc.data() as Map<String, dynamic>;

                    final startRaw = data['start'];
                    DateTime time;
                    if (startRaw is Timestamp) {
                      time = startRaw.toDate();
                    } else if (startRaw is String) {
                      time = DateTime.tryParse(startRaw) ?? DateTime.now();
                    } else {
                      time = DateTime.now();
                    }

                    final placeNameRaw = data['place_name'];
                    final placeName = (placeNameRaw != null && placeNameRaw.toString().trim().isNotEmpty)
                        ? placeNameRaw
                        : '장소 미정';

                    final is_done = data['is_done'] ?? false;

                    return _buildStampCard(time, placeName, is_done);
                  }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int done, int total) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/stamp_images/stamp-icon.png', width: 80),
            const SizedBox(width: 8),
            Text(
              '$done / $total개',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E6FD9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Transform.translate(
          offset: const Offset(0, -20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E6FD9),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Text(
              '종료된 일정',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStampCard(DateTime time, String placeName, bool is_done) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // ✅ 시간 + 장소명
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('HH:mm').format(time),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  placeName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // ✅ 상태에 따라 분기: 완료 vs 미완료
          is_done
              ? Column(
                children: [
                  Image.asset(
                            'assets/stamp_images/stamp-icon.png',
                            width: 70, // ✅ 적당한 사이즈 조절
                            height: 70,
                            fit: BoxFit.contain,
                            ),
                  const Text(
                    '완료',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E6FD9),
                    ),
                  ),
                ],
              )
              : Column(
            children: [
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F5),
                  foregroundColor: Colors.black87,
                  disabledBackgroundColor: Colors.grey[200],
                  disabledForegroundColor: Colors.grey,
                  side: const BorderSide(
                    color: Color(0xFF1E6FD9),
                    width: 3,
                  ),
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(15),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text(
                  '스탬프\n미완료',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}