import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: DiceDotPage()));

class DiceDotPage extends StatefulWidget {
  const DiceDotPage({super.key});

  @override
  State<DiceDotPage> createState() => _DiceDotPageState();
}

class _DiceDotPageState extends State<DiceDotPage> {
  int diceNumber = 1;

  void rollDice() {
    setState(() {
      diceNumber = Random().nextInt(6) + 1;
    });
  }

  Widget buildDot(double top, double left) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  List<Widget> getDotsForNumber(int number) {
    // 100x100 기준 위치
    switch (number) {
      case 1:
        return [buildDot(42, 42)];
      case 2:
        return [
          buildDot(20, 20),
          buildDot(65, 65),
        ];
      case 3:
        return [
          buildDot(20, 20),
          buildDot(42, 42),
          buildDot(65, 65),
        ];
      case 4:
        return [
          buildDot(20, 20),
          buildDot(20, 65),
          buildDot(65, 20),
          buildDot(65, 65),
        ];
      case 5:
        return [
          buildDot(20, 20),
          buildDot(20, 65),
          buildDot(65, 20),
          buildDot(65, 65),
          buildDot(42, 42),
        ];
      case 6:
        return [
          buildDot(20, 20),
          buildDot(20, 65),
          buildDot(42, 20),
          buildDot(42, 65),
          buildDot(65, 20),
          buildDot(65, 65),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎲 도트 주사위')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black),
                  ),
                ),
                ...getDotsForNumber(diceNumber),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: rollDice,
              child: const Text('🎲 굴리기'),
            ),
          ],
        ),
      ),
    );
  }
}
