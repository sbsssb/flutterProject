import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/bottom_nav_bar.dart';

class PrevRoomApp extends StatelessWidget {
  final String userId; // 🔹 추가
  const PrevRoomApp({super.key, required this.userId}); // 🔹 생성자에 추가

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PrevRoomIn(userId: userId), // 🔹 전달
    );
  }
}

class PrevRoomIn extends StatefulWidget {
  final String userId;

  const PrevRoomIn({super.key, required this.userId});

  @override
  State<PrevRoomIn> createState() => _PrevRoomInState();
}

class _PrevRoomInState extends State<PrevRoomIn> {
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

    final rooms = await Future.wait(docs.map((doc) async {
      final data = doc.data() as Map<String, dynamic>;
      final roomId = data['room_id'];

      final participants = await FirebaseFirestore.instance
          .collectionGroup('join_rooms')
          .where('room_id', isEqualTo: roomId)
          .get();

      return {
        'room_id': roomId,
        'title': '${data['region']} 여행',
        'members': participants.size,
        'theme': data['theme'],
        'is_owner': data['is_owner'],
        'cdatetime': data['cdatetime'],
      };
    }));

    setState(() {
      travelRooms = rooms;
      currentPage = page;
      hasMore = docs.length == 6;

      // 페이지 커서 저장
      if (docs.isNotEmpty && pageCursors.length < page) {
        pageCursors.add(docs.last);
      }

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '이전 여행',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E6FD9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
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
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: ElevatedButton(
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
                                            final detailData = query.docs.first.data();
                                            print('✅ travel_rooms 상세 정보:');
                                            print(detailData);
                                          } else {
                                            print('❌ 해당 room_id를 가진 travel_rooms 문서를 찾을 수 없습니다.');
                                          }
                                        } catch (e) {
                                          print('🚨 Firestore 조회 중 오류 발생: $e');
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text('이동'),
                                    ),
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
                              child: Text('$currentPage'),
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
