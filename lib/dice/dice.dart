import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vibration/vibration.dart';
import '../firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shake/shake.dart';
import '../gemini/gemini_service.dart';
import '../travellist/ScheduleListPage.dart';
import '../mypage/profile_avatar.dart';

final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MaterialApp(
      home: DoubleDiceOnBoard(roomId: '',)));
}


class DoubleDiceOnBoard extends StatefulWidget {



  final String roomId;
  const DoubleDiceOnBoard({super.key, required this.roomId});

  @override
  State<DoubleDiceOnBoard> createState() => _DoubleDiceOnBoardState();
}
late ShakeDetector _shakeDetector;
bool _hasRolled = false;
class _DoubleDiceOnBoardState extends State<DoubleDiceOnBoard> {
  int _sharedDiceResult = 0;
  final GlobalKey<_DiceCubeState> _dice1Key = GlobalKey();
  final GlobalKey<_DiceCubeState> _dice2Key = GlobalKey();

  @override
  void dispose() {
    _diceListener.cancel();
    _shakeDetector.stopListening();

    FirebaseFirestore.instance
        .collection('travel_rooms')
        .doc(widget.roomId)
        .update({'host_is_active': false});

    super.dispose();
  }
  String? _ownerProfileImg;


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
      Offset(startX + tileSize * 0.10 + dxFix, startY + tileSize * 0.20 + dyFix),
      Offset(startX + tileSize * 0.95 + dxFix, startY + tileSize * 0.24 + dyFix),
      Offset(startX + tileSize * 1.82 + dxFix, startY + tileSize * 0.24 + dyFix),
      Offset(startX + tileSize * 2.65 + dxFix, startY + tileSize * 0.24 + dyFix),
      Offset(startX + tileSize * 3.49 + dxFix, startY + tileSize * 0.2 + dyFix),
      Offset(startX + tileSize * 3.52 + dxFix, startY + tileSize * 1.1 + dyFix),
      Offset(startX + tileSize * 3.52 + dxFix, startY + tileSize * 1.95 + dyFix),
      Offset(startX + tileSize * 3.52 + dxFix, startY + tileSize * 2.8 + dyFix),
      Offset(startX + tileSize * 3.48 + dxFix, startY + tileSize * 3.6 + dyFix),
      Offset(startX + tileSize * 2.65 + dxFix, startY + tileSize * 3.70 + dyFix),
      Offset(startX + tileSize * 1.82 + dxFix, startY + tileSize * 3.70 + dyFix),
      Offset(startX + tileSize * 0.97 + dxFix, startY + tileSize * 3.70 + dyFix),
      Offset(startX + tileSize * 0.09 + dxFix, startY + tileSize * 3.6 + dyFix),
      Offset(startX + tileSize * 0.08 + dxFix, startY + tileSize * 2.8 + dyFix),
      Offset(startX + tileSize * 0.08 + dxFix, startY + tileSize * 1.96 + dyFix),
      Offset(startX + tileSize * 0.08 + dxFix, startY + tileSize * 1.1 + dyFix),
    ];

    return positions[index];
  }

  int _lastSharedSeed = -1;

  void _setupSharedDiceAnimationListener() {
    FirebaseFirestore.instance
        .collection('travel_rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) async {
      final data = snapshot.data();
      if (data == null) return;

      final diceValue = data['dice_value'] ?? 0;
      final rollerUid = data['roller_uid'];
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final animationSeed = data['animation_seed'] ?? 0;
      final route = List<int>.from(data['route'] ?? []);
      final landedArea = data['landed_area'];

      if (_lastSharedSeed == animationSeed) return;
      _lastSharedSeed = animationSeed;
      _hasArrived = false;
      if (diceValue == 0) return;
      if (rollerUid == currentUid) return;

      _lastSharedSeed = animationSeed;

      final rand = Random(animationSeed);
      final v1 = rand.nextInt(6) + 1;
      final v2 = rand.nextInt(6) + 1;

      await Future.wait([
        _dice1Key.currentState?.playDiceWithValue(v1) ?? Future.value(),
        _dice2Key.currentState?.playDiceWithValue(v2) ?? Future.value(),
      ]);

      await Future.delayed(const Duration(milliseconds: 500));

      await _moveTokenAlongRoute(route);

      setState(() {
        _landedArea = landedArea ?? '';
        _showDiceResult = false;
        _showLandedArea = true;
        _hasArrived = true;
      });
    });
  }


  bool _hasArrived = false;
  bool _isMovingToken = false;

  Future<void> _moveTokenAlongRoute(List<int> route) async {
    if (route.isEmpty) return;

    int? last = route.last;

    if (_currentPosition == last) {

      return;
    }

    setState(() {
      _currentPosition = route.first;
    });

    for (int i = 0; i < route.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        _currentPosition = route[i];
      });
    }
  }





  bool _showDiceResult = false;
  bool _showLandedArea = false;

  Future<void> rollBothDice() async {
    final roomDocRef = FirebaseFirestore.instance.collection('travel_rooms').doc(widget.roomId);
    final doc = await roomDocRef.get();
    final data = doc.data();

    if (data == null) return;

    final isRollingRemote = data['is_rolling'] == true;
    final diceAlreadyRolled = (data['dice_value'] ?? 0) > 0;

    if (isRollingRemote || diceAlreadyRolled) {

      return;
    }

    await roomDocRef.update({'is_rolling': true});

    try {
      _dice1Key.currentState?.rollDice();
      _dice2Key.currentState?.rollDice();

      await Future.delayed(const Duration(milliseconds: 600));
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
        _sharedDiceResult = stepsNeeded;
        _showResultOverlay = true;
        _showDiceResult = true;
        _showLandedArea = false;
      });


      await Future.delayed(const Duration(seconds: 2));
      for (int i = 0; i < fullRoute.length; i++) {
        await Future.delayed(const Duration(milliseconds: 400));
        setState(() {
          _currentPosition = fullRoute[i];
        });
      }

      final landed = _getLandedAreaName(_currentPosition);
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "anonymous";
      final animationSeed = Random().nextInt(100000);

      setState(() {
        _diceTotal = stepsNeeded;
        _landedArea = landed;
        _subRegion = landed;
        _showDiceResult = false;
        _showLandedArea = true;
      });

      await Future.delayed(const Duration(milliseconds: 10));

      await saveDiceRollResult(
        roomId: widget.roomId,
        diceValue: stepsNeeded,
        route: fullRoute,
        landedPosition: _currentPosition,
        landedArea: landed,
        rollerUid: uid,
        animationSeed: animationSeed,
      );

      await roomDocRef.update({
        'board_areas': selectedSubAreas,
        'dice_result': stepsNeeded,
      });
      if (landed.isNotEmpty) {
        await roomDocRef.update({"sub_region": landed});
      }
    } catch (e) {

    } finally {
      await roomDocRef.update({'is_rolling': false});
    }
  }




  Future<void> saveDiceRollResult({
    required String roomId,
    required int diceValue,
    required List<int> route,
    required int landedPosition,
    required String landedArea,
    required String rollerUid,
    required int animationSeed,
  }) async {
    final roomDocRef = FirebaseFirestore.instance.collection('travel_rooms').doc(roomId);

    await roomDocRef.update({
      'is_rolling': true,
    });

    await roomDocRef.update({
      'dice_value': diceValue,
      'route': route,
      'landed_position': landedPosition,
      'landed_area': landedArea,
      'roller_uid': rollerUid,
      'rolled_at': FieldValue.serverTimestamp(),
      'animation_seed': animationSeed,
      'is_rolling': false,
    }).then((_) {

    }).catchError((error) {

    });
  }


  String _getLandedAreaName(int position) {
    const boardTileOrder = [1, 2, 3, 5, 6, 7, 9, 10, 11, 13, 14, 15];
    int index = boardTileOrder.indexOf(position);
    if (index != -1 && index < selectedSubAreas.length) {
      return selectedSubAreas[index];
    } else {
      return '';
    }
  }




  Widget _buildParticipantRow(String nickname, String title, String profileImgPath) {
    return Row(
      children: [
        Image.asset(profileImgPath, width: 30, height: 30),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  String? _selectedRegion;
  String? _nickname;

  late StreamSubscription<DocumentSnapshot> _diceListener;


  void _listenToDiceResult() {
    FirebaseFirestore.instance
        .collection('travel_rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data == null) return;

      final diceResult = data['dice_result'] ?? 0;


      if (diceResult <= 0) {

        return;
      }

      setState(() {
        _sharedDiceResult = diceResult;
        _showResultOverlay = true;
      });
    });
  }


  Future<void> waitForRoomReady(String roomId) async {
    final docRef = FirebaseFirestore.instance.collection('travel_rooms').doc(roomId);

    for (int i = 0; i < 20; i++) {
      final doc = await FirebaseFirestore.instance.collection('travel_rooms').doc(roomId).get();
      final data = doc.data();
      final boardAreas = data?['board_areas'];
      final region = data?['region'];
      final ownerId = data?['owner_id'];

      if (doc.exists && ownerId != null && region != null && boardAreas != null && boardAreas is List && boardAreas.isNotEmpty) {

        break;
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }



  late final String _roomId;

  @override
  void initState() {
    super.initState();
    _roomId = widget.roomId;

    FirebaseFirestore.instance.collection('travel_rooms').doc(widget.roomId).update({
      'host_is_active': true,
    });

    _setupSharedDiceAnimationListener();
    _listenToDiceResult();

    _shakeDetector = ShakeDetector.autoStart(
      shakeThresholdGravity: 1.8,
      onPhoneShake: onPhoneShake,
    );

    Future(() async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {

        return;
      }

      final userId = currentUser.uid;


      await fetchRegionAndLoadAreas(widget.roomId);
      await waitForRoomReady(widget.roomId);
      await fetchParticipants(widget.roomId);

      final nickname = await fetchNickname(widget.roomId, userId);


      setState(() {
        _nickname = nickname ?? "익명";
      });
    });
  }




  bool _isRolling = false;
  bool _isOwner = false;

  void onPhoneShake(ShakeEvent event) async {
    if (_isRolling) {
      return;
    }

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 300);
    }

    _isRolling = true;

    try {
      final roomDocRef = FirebaseFirestore.instance.collection('travel_rooms').doc(widget.roomId);
      final doc = await roomDocRef.get();
      final data = doc.data();

      if (data == null) return;

      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final ownerId = data['owner_id'];

      if (currentUid != ownerId) {
        return;
      }

      await rollBothDice();
    } catch (e) {
    } finally {
      _isRolling = false;
    }
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
          'user_id': data['user_id'] ?? '',
        });
      }

      loaded.sort((a, b) {
        if (a['is_owner'] == true && b['is_owner'] != true) return -1;
        if (a['is_owner'] != true && b['is_owner'] == true) return 1;
        return 0;
      });

      setState(() {
        _participants = loaded;
      });

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      Map<String, dynamic>? owner;
      try {
        owner = loaded.firstWhere((p) => p['is_owner'] == true);
      } catch (_) {
        owner = null;
      }


      if (owner != null && owner['user_id'] == currentUserId) {
        setState(() {
          _isOwner = true;
        });
      } else {

      }

      try {
        final owner = loaded.firstWhere((p) => p['is_owner'] == true, orElse: () => {});
        final ownerUid = owner['user_id'];

        if (ownerUid != null && ownerUid != '') {
          final stampCount = await getSumStampCount(ownerUid);
          final imgPath = getProfileImagePath(stampCount);

          setState(() {
            _ownerProfileImg = imgPath;
          });
        }
      } catch (e) {
      }
    } catch (e) {
    }
  }



  Future<String?> fetchNickname(String roomId, String userId) async {
    try {


      final doc = await FirebaseFirestore.instance
          .collection('travel_rooms')
          .doc(roomId)
          .collection('members')
          .doc(userId)
          .get();

      if (doc.exists) {
        final nickname = doc.data()?['nickname'];

        return nickname as String?;
      } else {
      }
    } catch (e) {
    }

    return null;
  }


  String? _region;
  String? _subRegion;
  List<String> _themes = [];
  String? _transport;
  String? _date;

  Future<void> fetchRegionAndLoadAreas(String roomId) async {
    final doc = await FirebaseFirestore.instance.collection("travel_rooms").doc(roomId).get();

    if (!doc.exists) {

      return;
    }

    final data = doc.data();
    if (data == null) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final ownerId = data['owner_id'];
    final isHost = currentUid == ownerId;

    final region = data['region'] as String?;
    final subRegion = data['sub_region'] as String?;
    final themesRaw = data['themes'];
    final transport = data['transport'] as String?;
    final date = data['date'] as String?;
    final boardAreasRaw = data['board_areas'] as List<dynamic>?;

    if (boardAreasRaw != null) {
      setState(() {
        selectedSubAreas = boardAreasRaw.map((e) => e.toString()).toList();
      });

    } else if (region != null && isHost) {
      final regionId = convertRegionNameToId(region);
      final newAreas = await loadRandomSubAreas(regionId);

      setState(() {
        selectedSubAreas = newAreas;
      });

      await FirebaseFirestore.instance
          .collection("travel_rooms")
          .doc(roomId)
          .update({'board_areas': newAreas});


    }

    setState(() {
      _region = region;
      _subRegion = subRegion;
      _themes = (themesRaw is List) ? themesRaw.map((e) => e.toString()).toList() : [];
      _transport = transport;
      _date = date;
    });


  }


  String convertRegionNameToId(String name) {
    switch (name) {
      case "부산광역시": return "busan";
      case "충청북도": return "chungcheongbuk-do";
      case "충청남도": return "chungcheongnam-do";
      case "대구광역시": return "daegu";
      case "대전광역시": return "daejeon";
      case "강원도": return "gangwon-do";
      case "광주광역시": return "gwangju";
      case "경기도": return "gyeonggi-do";
      case "경상북도": return "gyeongsangbuk-do";
      case "경상남도": return "gyeongsangnam-do";
      case "인천광역시": return "incheon";
      case "제주도": return "jeju";
      case "전라북도": return "jeollabuk-do";
      case "전라남도": return "jeollanam-do";
      case "세종시": return "sejong";
      case "서울특별시": return "seoul";
      case "울산광역시": return "ulsan";
      default:
        return name;
    }
  }
    

  Future<List<String>> loadRandomSubAreas(String region, {int count = 12}) async {
    final doc = await FirebaseFirestore.instance.collection('region_sets').doc(region).get();

    if (!doc.exists) {

      return [];
    }

    final List<dynamic> rawList = doc['areas'];
    final List<String> subAreas = rawList.map((e) => e.toString()).toList();
    subAreas.shuffle(Random());
    final selected = subAreas.take(count).toList();

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    try {
      final roomDoc = await FirebaseFirestore.instance.collection('travel_rooms').doc(widget.roomId).get();

      final data = roomDoc.data();
      final ownerId = data?['owner_id'];

      final isHost = (currentUid != null && currentUid == ownerId);

      if (isHost) {
        await FirebaseFirestore.instance
            .collection('travel_rooms')
            .doc(widget.roomId)
            .update({'board_areas': selected});

      } else {
      }

    } catch (e) {
    }

    return selected;
  }


  @override
  Widget build(BuildContext context) {

    int _diceValue = 0;
    const boardTileOrder = [1, 2, 3, 5, 6, 7, 9, 10, 11, 13, 14, 15];

    return Scaffold(

      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("🎲 주사위 게임판")),
      body: Center(
    child: DefaultTextStyle(
    style: const TextStyle(
    fontFamily: 'AstaSans',
    fontSize: 16,
    color: Colors.black,
    ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Image.asset(
                'assets/dice_images/logo-main-ver1.png',
                height: 70,
              ),
            ),

            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/dice_images/dice-board.png', width: 400, height: 400, fit: BoxFit.contain),

                Positioned(
                  left: _getTilePosition(_currentPosition).dx + 10,
                  top: _getTilePosition(_currentPosition).dy + 5,
                  child: _ownerProfileImg != null
                      ? ClipOval(
                    child: Image.asset(
                      _ownerProfileImg!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const SizedBox.shrink(),
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
                        fontFamily: 'AstaSans',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  )
                      : Image.asset('assets/dice_images/logo-main-ver1.png', width: 60),
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
                      child: Text(
                        areaName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,fontFamily: 'AstaSans'),
                      ),
                    ),
                  );
                }),

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


                if (_showResultOverlay)
                  Positioned(
                    top: 160,
                    child: Container(
                      width: 170,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '$_sharedDiceResult칸 이동!',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),


                if (_showLandedArea)
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
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: const Text(
                      '참여자',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._participants.map((p) {
                    final uid = p['user_id'];
                    final nickname = p['nickname'] ?? '익명';
                    final isOwner = p['is_owner'] == true;
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                    final isMe = uid == currentUserId;

                    return FutureBuilder<int>(
                      future: getSumStampCount(uid),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }

                        final stampCount = snapshot.data!;
                        final profileImg = getProfileImagePath(stampCount);
                        final titleWithNickname = getTitleWithNickname(stampCount, nickname);

                        String displayName = titleWithNickname;

                        if (isOwner) displayName += ' 👑';

                        return _buildParticipantRow(displayName, '', profileImg);
                      },
                    );
                  }).toList(),
                ],
              ),
            ),

            Text('지역: ${_region ?? '로딩 중...'}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            (_isOwner)
                ? ElevatedButton.icon(
              onPressed: () async {

                if ((_subRegion ?? '').trim().isEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('⚠ 일정 생성 불가'),
                      content: const Text('먼저 주사위를 굴려 도착 지역을 정해주세요!'),
                      actions: [
                        TextButton(
                          child: const Text('확인'),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    ),
                  );
                  return;
                }

                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    useRootNavigator: true,
                    builder: (context) {
                      return const AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 20),
                            Text("일정을 생성 중입니다..."),
                          ],
                        ),
                      );
                    },
                  );

                  final prompt = buildTravelPrompt(
                    region: _region ?? '',
                    subRegion: _subRegion ?? '',
                    themes: _themes,
                    transport: _transport ?? '',
                    date: _date ?? '',
                  );

                  final scheduleList = await fetchScheduleFromPrompt(
                    prompt: prompt,
                    apiKey: dotenv.env['GEMINI_API_KEY']!,
                  );

                  if (context.mounted) {
                    await FirebaseFirestore.instance
                        .collection('travel_rooms')
                        .doc(widget.roomId)
                        .update({'host_is_active': false});

                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScheduleListPage(
                          roomId: widget.roomId,
                          initialSchedules: scheduleList,
                          region: _region ?? '',
                          subRegion: _subRegion ?? '',
                          themes: _themes,
                          transport: _transport ?? '',
                          date: _date ?? '',
                        ),
                      ),
                    );
                  }
                } catch (e) {

                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("일정 생성 중 오류가 발생했어요 🥲")),
                    );
                  }
                }
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('일정 생성으로 이동'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: const Color(0xFFFACC15),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            )
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('travel_rooms')
                  .doc(widget.roomId)
                  .collection('schedules')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {

                  final scheduleDoc = snapshot.data!.docs.first;
                  return ElevatedButton.icon(
                    onPressed: () {
                      context.go('/stamp?roomId=${widget.roomId}');
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('📅 확정 일정 보기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1E6FD9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  );
                } else {
                  return const SizedBox();
                }
              },
            ),

            const SizedBox(height: 16),

            (_isOwner && !_isRolling && _diceValue == 0)
                ? ElevatedButton(
              onPressed: () async {
                setState(() {
                  _isRolling = true;
                });
                await rollBothDice();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E6FD9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text(
                "🎲 두 개 굴리기!",
                style: TextStyle(fontSize: 15),
              ),
            )
                : const SizedBox.shrink(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }
}

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

  Future<void> playDiceWithValue(int value) async {
    _diceValue = value;
    _fakeResult = value;

    final baseX = angleMap[value]![0];
    final baseY = angleMap[value]![1];

    final extraX = 4 * 2 * pi;
    final extraY = 4 * 2 * pi;

    setState(() {
      _x = baseX + extraX;
      _y = baseY + extraY;
      _showResultText = true;
    });

    _controller.forward(from: 0);

    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _showResultText = false;
    });
  }


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }
  bool _showResultText = false;
  int _fakeResult = 1;
  void rollDice() {

    final random = Random();
    _diceValue = random.nextInt(6) + 1;
    _fakeResult = _diceValue;

    final baseX = angleMap[_diceValue]![0];
    final baseY = angleMap[_diceValue]![1];

    final extraX = (4 + random.nextInt(3)) * 2 * pi * (random.nextBool() ? 1 : -1);
    final extraY = (4 + random.nextInt(3)) * 2 * pi * (random.nextBool() ? 1 : -1);

    setState(() {
      _x = baseX + extraX;
      _y = baseY + extraY;
      _showResultText = true;
    });

    _controller.forward(from: 0);

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showResultText = false;
      });
    });
  }

  StreamSubscription? _diceListener;



  @override
  void dispose() {
    _controller.dispose();
    _diceListener?.cancel();
    _shakeDetector.stopListening();



    super.dispose();
  }

  Future<void> checkAndEnterDiceRoom(BuildContext context, String roomId) async {
    final doc = await FirebaseFirestore.instance.collection('travel_rooms').doc(roomId).get();
    final data = doc.data();



    if (data != null && data['host_is_active'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoubleDiceOnBoard(roomId: roomId)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('방장이 현재 접속 중이 아닙니다 🥲')),
      );
    }
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
                _buildFace(image: 'assets/dice_images/dice1.PNG', y: _size / 2 + _thickness, xRot: -pi / 2),
                _buildFace(image: 'assets/dice_images/dice2.PNG', y: -_size / 2 - _thickness, xRot: pi / 2),
                _buildFace(image: 'assets/dice_images/dice3.PNG', z: _size / 2 + _thickness),
                _buildFace(image: 'assets/dice_images/dice4.PNG', z: -_size / 2 - _thickness, yRot: pi),
                _buildFace(image: 'assets/dice_images/dice5.PNG', x: -_size / 2 - _thickness, yRot: pi / 2),
                _buildFace(image: 'assets/dice_images/dice6.PNG', x: _size / 2 + _thickness, yRot: -pi / 2),
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