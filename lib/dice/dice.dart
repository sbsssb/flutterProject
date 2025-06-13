// 🔁 전체 적용 코드
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(home: DoubleDiceOnBoard()));
}

class DoubleDiceOnBoard extends StatefulWidget {
  const DoubleDiceOnBoard({super.key});

  @override
  State<DoubleDiceOnBoard> createState() => _DoubleDiceOnBoardState();
}

class _DoubleDiceOnBoardState extends State<DoubleDiceOnBoard> {
  final GlobalKey<_DiceCubeState> _dice1Key = GlobalKey();
  final GlobalKey<_DiceCubeState> _dice2Key = GlobalKey();

  List<String> selectedSubAreas = [];
  int _diceTotal = 0;
  int _currentPosition = 0;

  bool _showResultOverlay = false;
  int _fakeResult = 0;
  String _landedArea = '';

  Offset _getTilePosition(int index) {
    const tileSize = 85.0;
    const startX = 20.0;
    const startY = 20.0;

    const dxFix = 10.0;
    const dyFix = 5.0;

    List<Offset> positions = [
      Offset(startX + tileSize * 0.14 + dxFix, startY + tileSize * 0.2 + dyFix),
      Offset(startX + tileSize * 0.95 + dxFix, startY + tileSize * 0.24 + dyFix),
      Offset(startX + tileSize * 1.8 + dxFix, startY + tileSize * 0.24 + dyFix),
      Offset(startX + tileSize * 2.65 + dxFix, startY + tileSize * 0.24 + dyFix),
      Offset(startX + tileSize * 3.47 + dxFix, startY + tileSize * 0.2 + dyFix),
      Offset(startX + tileSize * 3.5 + dxFix, startY + tileSize * 1.1 + dyFix),
      Offset(startX + tileSize * 3.5 + dxFix, startY + tileSize * 1.9 + dyFix),
      Offset(startX + tileSize * 3.5 + dxFix, startY + tileSize * 2.8 + dyFix),
      Offset(startX + tileSize * 3.48 + dxFix, startY + tileSize * 3.6 + dyFix),
      Offset(startX + tileSize * 2.65 + dxFix, startY + tileSize * 3.65 + dyFix),
      Offset(startX + tileSize * 1.82 + dxFix, startY + tileSize * 3.65 + dyFix),
      Offset(startX + tileSize * 1 + dxFix, startY + tileSize * 3.65 + dyFix),
      Offset(startX + tileSize * 0.14 + dxFix, startY + tileSize * 3.6 + dyFix),
      Offset(startX + tileSize * 0.11 + dxFix, startY + tileSize * 2.8 + dyFix),
      Offset(startX + tileSize * 0.1 + dxFix, startY + tileSize * 1.9 + dyFix),
      Offset(startX + tileSize * 0.1 + dxFix, startY + tileSize * 1.1 + dyFix),
    ];

    return positions[index];
  }

  void rollBothDice() {
    _dice1Key.currentState?.rollDice();
    _dice2Key.currentState?.rollDice();

    setState(() {
      _fakeResult = Random().nextInt(12) + 1;
      _showResultOverlay = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      final v1 = _dice1Key.currentState?.diceValue ?? 1;
      final v2 = _dice2Key.currentState?.diceValue ?? 1;
      final sum = v1 + v2;
      final nextPos = (_currentPosition + sum) % 16;

      setState(() {
        _diceTotal = sum;
        _currentPosition = nextPos;
        _showResultOverlay = false;
        _landedArea = _getAreaName(nextPos);
      });
    });
  }

  String _getAreaName(int position) {
    const boardTileOrder = [1, 2, 3, 5, 6, 7, 9, 10, 11, 13, 14, 15];
    int index = boardTileOrder.indexOf(position);
    if (index != -1 && index < selectedSubAreas.length) {
      return selectedSubAreas[index];
    } else {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    loadRandomSubAreas("jeju");
  }

  Future<void> loadRandomSubAreas(String region, {int count = 12}) async {
    final doc = await FirebaseFirestore.instance.collection('region_sets').doc(region).get();
    if (doc.exists) {
      final List<dynamic> rawList = doc['areas'];
      final List<String> subAreas = rawList.map((e) => e.toString()).toList();
      subAreas.shuffle(Random());

      setState(() {
        selectedSubAreas = subAreas.take(count).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const boardTileOrder = [1, 2, 3, 5, 6, 7, 9, 10, 11, 13, 14, 15];

    return Scaffold(
      appBar: AppBar(title: const Text("🎲 주사위 게임판")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/dice-images/dice_board.png', width: 400, height: 400, fit: BoxFit.contain),

                Positioned(
                  left: _getTilePosition(_currentPosition).dx + 10,
                  top: _getTilePosition(_currentPosition).dy + 10,
                  child: Image.asset('assets/dice-images/1.PNG', width: 30),
                ),

                ...[0, 4, 8, 12].map((i) => Positioned(
                  left: _getTilePosition(i).dx,
                  top: _getTilePosition(i).dy,
                  child: Image.asset('assets/dice-images/logo-main-ver1.png', width: 60),
                )),

                ...List.generate(boardTileOrder.length, (index) {
                  final tileIndex = boardTileOrder[index];
                  final pos = _getTilePosition(tileIndex);
                  final areaName = (index < selectedSubAreas.length) ? selectedSubAreas[index] : '❓';

                  return Positioned(
                    left: pos.dx,
                    top: pos.dy,
                    child: SizedBox(
                      width: 60,
                      child: Text(areaName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  );
                }),

                if (!_showResultOverlay)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DiceCube(key: _dice1Key),
                      const SizedBox(width: 16),
                      DiceCube(key: _dice2Key),
                    ],
                  ),

                if (_showResultOverlay)
                  Positioned(
                    top: 160,
                    child: Container(
                      width: 130,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '🎯 $_fakeResult',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                if (!_showResultOverlay && _landedArea.isNotEmpty)
                  Positioned(
                    top: 160,
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '📍 $_landedArea',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: rollBothDice,
              child: const Text("🎲 두 개 굴리기!"),
            ),
            const SizedBox(height: 16),
            Text('🎯 주사위 합: $_diceTotal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// 주사위 클래스는 이전 코드 그대로 유
class DiceCube extends StatefulWidget {
  const DiceCube({super.key});

  @override
  State<DiceCube> createState() => _DiceCubeState();
}

class _DiceCubeState extends State<DiceCube> with SingleTickerProviderStateMixin {
  int get diceValue => _diceValue;
  double _x = pi / 2;
  double _y = 0;
  final double _size = 40;
  final double _thickness = 0.5;

  late AnimationController _controller;
  late Animation<double> _animation;

  final Map<int, List<double>> angleMap = {
    1: [pi / 2, 0],
    2: [-pi / 2, 0],
    3: [0, 0],
    4: [0, pi],
    5: [0, pi / 2],
    6: [0, -pi / 2],
  };

  int _diceValue = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  void rollDice() {
    final random = Random();
    _diceValue = random.nextInt(6) + 1;

    final baseX = angleMap[_diceValue]![0];
    final baseY = angleMap[_diceValue]![1];

    final extraX = (4 + random.nextInt(3)) * 2 * pi * (random.nextBool() ? 1 : -1);
    final extraY = (4 + random.nextInt(3)) * 2 * pi * (random.nextBool() ? 1 : -1);

    setState(() {
      _x = baseX + extraX;
      _y = baseY + extraY;
    });

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateY(_y + (_animation.value * 2 * pi))
            ..rotateX(_x + (_animation.value * 2 * pi)),
          child: SizedBox(
            width: _size * 2,
            height: _size * 2,
            child: Stack(
              children: [
                _buildFace(image: 'assets/dice-images/dice1.PNG', y: _size / 2 + _thickness, xRot: -pi / 2),
                _buildFace(image: 'assets/dice-images/dice2.PNG', y: -_size / 2 - _thickness, xRot: pi / 2),
                _buildFace(image: 'assets/dice-images/dice3.PNG', z: _size / 2 + _thickness),
                _buildFace(image: 'assets/dice-images/dice4.PNG', z: -_size / 2 - _thickness, yRot: pi),
                _buildFace(image: 'assets/dice-images/dice5.PNG', x: -_size / 2 - _thickness, yRot: pi / 2),
                _buildFace(image: 'assets/dice-images/dice6.PNG', x: _size / 2 + _thickness, yRot: -pi / 2),
              ],

            ),

          ),
        );
      },
    );
  }

  Widget _buildFace({
    required String image,
    double xRot = 0,
    double yRot = 0,
    double x = 0,
    double y = 0,
    double z = 0,
  }) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translate(x, y, z)
        ..rotateX(xRot)
        ..rotateY(yRot),
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
          border: Border.all(color: Colors.black26),
        ),
      ),
    );
  }
}