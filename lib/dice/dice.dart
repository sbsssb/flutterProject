// 🔁 전체 적용 코드
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterteam4/dice/test.dart';

final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';


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

  static const double diceTop = 150;
  static const double diceLeft1 = 120;
  static const double diceLeft2 = 200;

  final Set<int> _skippablePositions = {0, 4, 8, 12};

  Offset _getTilePosition(int index) {
    const tileSize = 85.0;
    const startX = 8.0;
    const startY = 20.0;

    const dxFix = 10.0;
    const dyFix = 5.0;

    List<Offset> positions = [
      Offset(startX + tileSize * 0.10 + dxFix, startY + tileSize * 0.19 + dyFix),
      Offset(startX + tileSize * 0.95 + dxFix, startY + tileSize * 0.24 + dyFix),
      Offset(startX + tileSize * 1.8 + dxFix, startY + tileSize * 0.24 + dyFix),
      Offset(startX + tileSize * 2.65 + dxFix, startY + tileSize * 0.24 + dyFix),
      Offset(startX + tileSize * 3.49 + dxFix, startY + tileSize * 0.2 + dyFix),
      Offset(startX + tileSize * 3.5 + dxFix, startY + tileSize * 1.1 + dyFix),
      Offset(startX + tileSize * 3.5 + dxFix, startY + tileSize * 1.9 + dyFix),
      Offset(startX + tileSize * 3.5 + dxFix, startY + tileSize * 2.8 + dyFix),
      Offset(startX + tileSize * 3.48 + dxFix, startY + tileSize * 3.6 + dyFix),
      Offset(startX + tileSize * 2.65 + dxFix, startY + tileSize * 3.65 + dyFix),
      Offset(startX + tileSize * 1.82 + dxFix, startY + tileSize * 3.65 + dyFix),
      Offset(startX + tileSize * 1 + dxFix, startY + tileSize * 3.65 + dyFix),
      Offset(startX + tileSize * 0.09 + dxFix, startY + tileSize * 3.6 + dyFix),
      Offset(startX + tileSize * 0.11 + dxFix, startY + tileSize * 2.8 + dyFix),
      Offset(startX + tileSize * 0.1 + dxFix, startY + tileSize * 1.9 + dyFix),
      Offset(startX + tileSize * 0.1 + dxFix, startY + tileSize * 1.1 + dyFix),
    ];

    return positions[index];
  }

  void rollBothDice() {
    _dice1Key.currentState?.rollDice();
    _dice2Key.currentState?.rollDice();

    Future.delayed(const Duration(milliseconds: 600), () {
      final v1 = _dice1Key.currentState?.diceValue ?? 1;
      final v2 = _dice2Key.currentState?.diceValue ?? 1;

      int tempPos = _currentPosition;
      List<int> fullRoute = [];
      int stepsNeeded = v1 + v2;

      while (fullRoute.where((p) => !_skippablePositions.contains(p)).length < stepsNeeded) {
        tempPos = (tempPos + 1) % 16;
        fullRoute.add(tempPos);
      }

      setState(() {
        _fakeResult = stepsNeeded;
        _showResultOverlay = true;
      });

      Future.delayed(const Duration(seconds: 2), () async {
        for (int i = 0; i < fullRoute.length; i++) {
          await Future.delayed(const Duration(milliseconds: 400));
          setState(() {
            _currentPosition = fullRoute[i];
          });
        }

        final landed = _getAreaName(_currentPosition);
        print("🎯 도착 지역: $landed"); // 로그 찍기

        setState(() {
          _diceTotal = stepsNeeded;
          _showResultOverlay = false;
          _landedArea = landed;
        });

        final roomDocRef = FirebaseFirestore.instance.collection('travel_rooms').doc("EjG545x9ujgu4z1aFMNm");

        if (landed.isNotEmpty) {
          await roomDocRef.update({"sub_region": landed}).then((_) {
            print("✅ Firestore에 저장 완료: $landed");
          }).catchError((error) {
            print("❌ Firestore 저장 실패: $error");
          });
        } else {
          print("⚠️ landed 값이 비어있어서 Firestore 저장 생략됨");
        }

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

  Widget _buildParticipantRow(String name, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 30), // ← 아이콘 + 텍스트 전체 오른쪽으로 이동
            child: Row(
              children: [
                const Icon(Icons.account_circle, size: 20),
                const SizedBox(width: 8),
                Text('“$description” $name', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),


        ],
      ),
    );
  }
  String? _selectedRegion;
  String? _nickname;


  @override
  void initState() {
    super.initState();

    print("🛠 initState 시작");

    // 1. 지역 정보 + 하위 지역 불러오기
    print("🌍 지역 로딩 시작: $roomId");
    fetchRegionAndLoadAreas(roomId);
    fetchParticipants(roomId);

    // 2. 닉네임 하드코딩으로 불러오기
    const hardcodedUserId = "yBGkS5yQ7Hc8tzbEEQYUSd3n8O23"; // ← Firestore에 있는 UID

    fetchNickname(roomId, hardcodedUserId).then((value) {
      print("🎯 받아온 닉네임: $value");
      setState(() {
        _nickname = value ?? "익명";
      });
    });
  }

  List<Map<String, dynamic>> _participants = [];

  Future<void> fetchParticipants(String roomId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('travel_rooms')
          .doc(roomId)
          .collection('members')
          .get();

      final List<Map<String, dynamic>> loaded = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        loaded.add({
          'nickname': data['nickname'] ?? '익명',
          'title': data['titles'] ?? '',
          'is_owner': data['is_owner'] ?? false,
        });
      }

      // 🔁 is_owner가 true인 사람을 맨 앞으로 정렬
      loaded.sort((a, b) {
        if (a['is_owner'] == true && b['is_owner'] != true) return -1;
        if (a['is_owner'] != true && b['is_owner'] == true) return 1;
        return 0;
      });

      setState(() {
        _participants = loaded;
      });

      print("✅ 참여자 목록 로딩 완료 (정렬 포함): $_participants");
    } catch (e) {
      print("🔥 참여자 로딩 실패: $e");
    }
  }



  Future<String?> fetchNickname(String roomId, String userId) async {
    try {
      print("📥 닉네임 불러오기 시도 → roomId: $roomId, userId: $userId");

      final doc = await FirebaseFirestore.instance
          .collection('travel_rooms')
          .doc(roomId)
          .collection('members')
          .doc(userId)
          .get();

      if (doc.exists) {
        final nickname = doc.data()?['nickname'];
        print("✅ Firestore 문서 있음, nickname: $nickname");
        return nickname as String?;
      } else {
        print("❌ 닉네임 문서 없음 → path: travel_rooms/$roomId/members/$userId");
      }
    } catch (e) {
      print("🔥 닉네임 불러오기 에러: $e");
    }

    return null;
  }



  final String roomId = "EjG545x9ujgu4z1aFMNm";
  Future<void> fetchRegionAndLoadAreas(String roomId) async {
    final doc = await FirebaseFirestore.instance.collection("travel_rooms").doc(roomId).get();

    if (doc.exists) {
      final region = doc.data()?['region'] as String?;
      if (region != null) {
        setState(() {
          _selectedRegion = region;
        });
        final regionId = convertRegionNameToId(region);
        await loadRandomSubAreas(regionId);
        await loadRandomSubAreas(region);
        print("🌍 불러온 지역: $region");
      } else {
        print("❗ region 필드 없음");
      }
    } else {
      print("❌ 문서가 존재하지 않음");
    }
  }


  String convertRegionNameToId(String name) {
    switch (name) {
      case "부산": return "busan";
      case "충청북도": return "chungcheongbuk-do";
      case "충청남도": return "chungcheongnam-do";
      case "대구": return "daegu";
      case "대전": return "daejeon";
      case "강원도": return "gangwon-do";
      case "광주": return "gwangju";
      case "경기도": return "gyeonggi-do";
      case "경상북도": return "gyeongsangbuk-do";
      case "경상남도": return "gyeongsangnam-do";
      case "인천": return "incheon";
      case "제주": return "jeju";
      case "전라북도": return "jeollabuk-do";
      case "전라남도": return "jeollanam-do";
      case "세종": return "sejong";
      case "서울": return "seoul";
      case "울산": return "ulsan";
      default:
        return name; // fallback - 혹시 매핑 안된 이름이면 그대로 전달
    }
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

      print("🎯 하위 지역 로딩 성공: $selectedSubAreas");
    } else {
      print("❌ 지역 문서 '$region' 없음");
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
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Image.asset(
                'assets/dice-images/logo-main-ver1.png', // 너가 쓰는 로고 경로로 바꿔!
                height: 70,
              ),
            ),

            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/dice-images/dice-board.png', width: 400, height: 400, fit: BoxFit.contain),

                Positioned(
                  left: _getTilePosition(_currentPosition).dx + 10,
                  top: _getTilePosition(_currentPosition).dy + 5,
                  child: Image.asset('assets/dice-images/1.PNG', width: 40),
                ),

                ...[0, 4, 8, 12].map((i) => Positioned(
                  left: _getTilePosition(i).dx,
                  top: _getTilePosition(i).dy,
                  child: i == 0
                      ? const SizedBox(
                    width: 60,
                    child: Text(
                      '🚩Start →',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  )
                      : Image.asset('assets/dice-images/logo-main-ver1.png', width: 60),
                )),

                ...List.generate(boardTileOrder.length, (index) {
                  final tileIndex = boardTileOrder[index];
                  final pos = _getTilePosition(tileIndex);
                  final areaName = (index < selectedSubAreas.length) ? selectedSubAreas[index] : '';

                  return Positioned(
                    left: pos.dx,
                    top: pos.dy,
                    child: SizedBox(
                      width: 60,
                      child: Text(areaName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  );
                }),

                if (!_showResultOverlay) ...[
                  Positioned(
                    top: diceTop,
                    left: diceLeft1,
                    child: DiceCube(key: _dice1Key),
                  ),
                  Positioned(
                    top: diceTop,
                    left: diceLeft2,
                    child: DiceCube(key: _dice2Key),
                  ),
                ],

                if (_showResultOverlay)
                  Positioned(
                    top: 160,
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ' $_fakeResult칸 이동!',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                if (!_showResultOverlay && _landedArea.isNotEmpty)
                  Positioned(
                    top: 160,
                    child: Container(
                      width: 170,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(1),
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
        Align(
          alignment: Alignment.centerLeft, // 리스트는 왼쪽 정렬 유지
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 30), // ✅ "참여자" 텍스트만 오른쪽으로 밀기
                child: const Text(
                  '참여자',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ..._participants.map((p) {
                final nickname = p['nickname'] ?? '익명';
                final title = p['title'] ?? '';
                final isOwner = p['is_owner'] == true;
                final displayName = isOwner ? '$nickname 👑' : nickname;

                return _buildParticipantRow(displayName, title);
              }),
            ],
          ),
        ),


            Text('지역: ${_selectedRegion ?? '로딩 중...'}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // ✅ 일정 생성 페이지로 이동하는 버튼
            // 버튼 부분
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DiceDotPage()),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('다음으로 이동'),
            ),


            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: rollBothDice,
              child: const Text("🎲 두 개 굴리기!"),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}



// DiceCube 클래스는 그대로 유지

// 주사위 클래스는 이전 코드 그대로 유지

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
  bool _showResultText = false; // 상태 변수 추가
  int _fakeResult = 1;
  void rollDice() {

    final random = Random();
    _diceValue = random.nextInt(6) + 1;
    _fakeResult = _diceValue; // 결과 텍스트에 바로 반영

    final baseX = angleMap[_diceValue]![0];
    final baseY = angleMap[_diceValue]![1];

    final extraX = (4 + random.nextInt(3)) * 2 * pi * (random.nextBool() ? 1 : -1);
    final extraY = (4 + random.nextInt(3)) * 2 * pi * (random.nextBool() ? 1 : -1);

    setState(() {
      _x = baseX + extraX;
      _y = baseY + extraY;
      _showResultText = true; // 🎯 텍스트 일찍 보이게 설정!
    });

    _controller.forward(from: 0);

    // 원한다면 애니메이션 끝나고 텍스트 숨기기 (예: 2초 뒤)
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showResultText = false;
      });
    });
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