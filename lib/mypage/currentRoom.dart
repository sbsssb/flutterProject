import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/bottom_nav_bar.dart';
import '../travelroom/travelDetail.dart';
import 'prevRoom_detail.dart';
import 'appbar.dart';

class CurrentRoomApp extends StatelessWidget {
  final String userId; // 🔹 추가
  const CurrentRoomApp({super.key, required this.userId}); // 🔹 생성자에 추가

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CurrentRoomIn(userId: userId), // 🔹 전달
    );
  }
}

class CurrentRoomIn extends StatefulWidget {
  final String userId;

  const CurrentRoomIn({super.key, required this.userId});

  @override
  State<CurrentRoomIn> createState() => _CurrentRoomInState();
}

class _CurrentRoomInState extends State<CurrentRoomIn> {
  List<Map<String, dynamic>> travelRooms = [];
  DocumentSnapshot? lastDocument;
  int currentPage = 1;
  bool hasMore = true;
  bool isLoading = false;

  // 🔹 여기! 페이지 커서 리스트 추가
  List<DocumentSnapshot> pageCursors = [];

  @override
  void initState() {
    super.initState();
    fetchTravelRooms(page: 1); // ✅ 초기 진입
  }

  Future<void> fetchTravelRooms({required int page}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('join_rooms')
        .orderBy('cdatetime', descending: true)
        .limit(6);

    if (page > 1 && pageCursors.length >= page - 1) {
      final last = pageCursors[page - 2];
      query = query.startAfterDocument(last);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;

    // 🔍 is_done == false 필터링 (진행 중인 방만)
    final filteredDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final isDone = data['is_done'] ?? false;
      return isDone == false;
    }).toList();

    // 🔄 members 수를 Firestore에서 불러오는 병렬 작업
    final rooms = await Future.wait(filteredDocs.map((doc) async {
      final data = doc.data() as Map<String, dynamic>;
      final roomId = data['room_id'];
      final isOwner = data['is_owner'] ?? false;

      // 🔍 travel_rooms/{roomId}/members 서브컬렉션에서 참여 인원 수 가져오기
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('travel_rooms')
          .doc(roomId)
          .collection('members')
          .get();

      return {
        'room_id': roomId,
        'title': '${data['region']} 여행',
        'members': membersSnapshot.size, // ✅ 실제 인원 수
        // 'members': 1, // ❌ 기존 하드코딩된 값 (참고용)
        'theme': data['theme'],
        'cdatetime': data['cdatetime'],
        'is_owner': isOwner, // ✅ 방장 여부 저장
      };
    }).toList());

    setState(() {
      travelRooms = rooms;
      currentPage = page;
      hasMore = docs.length == 6;

      if (docs.isNotEmpty && pageCursors.length < page) {
        pageCursors.add(docs.last);
      }

      isLoading = false;
    });
  }

  Future<void> deleteTravelRoom(String roomId) async {
    final firestore = FirebaseFirestore.instance;

    // 🔸 모든 유저의 join_rooms에서 해당 room_id 삭제
    final joinRoomsSnapshot = await firestore.collectionGroup('join_rooms')
        .where('room_id', isEqualTo: roomId)
        .get();

    for (final doc in joinRoomsSnapshot.docs) {
      await doc.reference.delete();
    }

    // 🔸 travel_rooms의 모든 서브컬렉션 삭제
    final subcollections = ['members', 'schedules', 'stamp_logs', 'album_photos'];
    for (final sub in subcollections) {
      final subSnap = await firestore
          .collection('travel_rooms')
          .doc(roomId)
          .collection(sub)
          .get();

      for (final doc in subSnap.docs) {
        await doc.reference.delete();
      }
    }

    // 🔸 travel_rooms 문서 자체 삭제
    await firestore.collection('travel_rooms').doc(roomId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(userId: widget.userId),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '진행 중인 여행',
              style: TextStyle(
                fontSize: 26,
                fontFamily: 'Jalnan',
                color: Color(0xFF1E6FD9),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: travelRooms.isEmpty
                  ? const Center(
                child: Text(
                  '여행 방이 없습니다',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
                  : GridView.builder(
                itemCount: travelRooms.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final room = travelRooms[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF1E6FD9)),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('참여인원 : ${room['members']}명'),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 삭제 버튼 (조건부 렌더링)
                              if (room['is_owner'] == true)
                                ElevatedButton(
                                  onPressed: () async {
                                    final roomId = room['room_id'];

                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('방 삭제'),
                                        content: const Text('정말로 이 여행방을 삭제하시겠습니까? 모든 데이터가 사라집니다.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('취소'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            child: const Text('삭제'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (shouldDelete == true) {
                                      await deleteTravelRoom(roomId);
                                      await fetchTravelRooms(page: currentPage); // 삭제 후 목록 갱신
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('여행방이 삭제되었습니다.')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('삭제'),
                                )
                              else
                                const SizedBox(), // 삭제 안 보일 때 공간 차지용

                              // 이동 버튼
                              ElevatedButton(
                                onPressed: () async {
                                  final roomId = room['room_id'];
                                  print('📦 클릭된 room_id: $roomId');

                                  try {
                                    final query = await FirebaseFirestore.instance
                                        .collection('travel_rooms')
                                        .where('room_id', isEqualTo: roomId)
                                        .limit(1)
                                        .get();

                                    if (query.docs.isNotEmpty) {
                                      final doc = query.docs.first;
                                      final docId = doc.id;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TravelRoomDetailPage(roomId: docId),
                                        ),
                                      );
                                    } else {
                                      print('❌ 해당 room_id를 가진 travel_rooms 문서를 찾을 수 없습니다.');
                                    }
                                  } catch (e) {
                                    print('🚨 Firestore 조회 중 오류 발생: $e');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('이동'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ◀️ 이전
                  IconButton(
                    onPressed: currentPage > 1 ? () {
                      fetchTravelRooms(page: currentPage - 1);
                    } : null,
                    icon: const Icon(Icons.chevron_left),
                  ),

                  // 📄 숫자 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () {},
                      child: Text('$currentPage',style: TextStyle(fontFamily: 'AstaSans', fontSize: 18, color: Color(0xFF1E6FD9)),),
                    ),
                  ),

                  // ▶️ 다음
                  IconButton(
                    onPressed: hasMore ? () {
                      fetchTravelRooms(page: currentPage + 1);
                    } : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
