import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/schedule_model.dart';

class StampCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback? onStampPressed;
  final bool isTripDone;

  const StampCard({
    super.key,
    required this.schedule,
    required this.onStampPressed,
    required this.isTripDone,
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
              style: const TextStyle(fontSize: 20),
            ),
          ),
          schedule.isDone
              ? Column(
                children: [
                  Image.asset('assets/stamp_images/stamp-icon.png', width: 70),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (schedule.canStamp)
                    Text(
                      '스탬프 적립 가능!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  SizedBox(height: 4),
                  if (!isTripDone)
                    AnimatedScale(
                      scale: schedule.canStamp ? 1.1 : 1.0,
                      duration: Duration(milliseconds: 200),
                      child: ElevatedButton(
                        onPressed: schedule.canStamp ? onStampPressed : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF5F5F5),
                          foregroundColor: Colors.black87,
                          disabledBackgroundColor: Colors.grey[200],
                          disabledForegroundColor: Colors.grey,
                          side: const BorderSide(
                            color: Color(0xFF1E6FD9),
                            width: 3,
                          ),
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(15),
                          textStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text(
                          '스탬프\n찍기',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
        ],
      ),
    );
  }
}
