import 'package:flutter/material.dart';

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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(child: Text((schedule.placeName))),
          schedule.isDone
              ? const Icon(Icons.check_circle, color: Colors.green)
              : ElevatedButton(
              onPressed: schedule.canStamp? onStampPressed : null,
              child: const Text('스탬프 찍기')
          )
        ],
      ),
    );
  }
}
