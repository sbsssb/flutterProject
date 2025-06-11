import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule_model.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onStampPressed;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onStampPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${DateFormat('HH:mm').format(schedule.start.toDate())} ${schedule.placeName}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          schedule.isDone
              ? Column(
            children: [
              Image.asset('assets/images/stamp-done.png', width: 40),
              const Text('완료'),
            ],
          )
              : ElevatedButton(
            onPressed: schedule.canStamp ? onStampPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('스탬프\n찍기', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
