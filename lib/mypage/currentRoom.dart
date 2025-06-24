import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/bottom_nav_bar.dart';
import '../travelroom/travelDetail.dart';
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

    // ✅ travel_rooms 기준으로 변경
    Query query = FirebaseFirestore.instance
        .collection('travel_rooms')
        .where('is_done', isEqualTo: false) // ✅ 진행 중인 방만
        .where('owner_id', isEqualTo: widget.userId) // ✅ 본인만
        .orderBy('cdatetime', descending: true)
        .limit(6);

    // 🔹 페이지네이션 커서 처리
    if (page > 1 && pageCursors.length >= page - 1) {
      final last = pageCursors[page - 2];
      query = query.startAfterDocument(last);
    }

    try {
      final snapshot = await query.get();
      final docs = snapshot.docs;

      // 🔍 travel_rooms 문서에서 필요한 필드 추출
      final rooms = docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'room_id': doc.id, // ✅ 문서 ID 사용
          'title': '${data['region']} 여행',
          'members': 1, // 🔹 인원은 추후 members 서브컬렉션 length로 대체 가능
          'theme': data['theme'],
          'cdatetime': data['cdatetime'],
        };
      }).toList();

      setState(() {
        travelRooms = rooms;
        currentPage = page;
        hasMore = docs.length == 6;

        if (docs.isNotEmpty && pageCursors.length < page) {
          pageCursors.add(docs.last);
        }

        isLoading = false;
      });
    } catch (e) {
      print('🔥 Firestore 조회 오류: $e');
      setState(() {
        isLoading = false;
      });
    }
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
                                            final doc = query.docs.first;
                                            final docId = doc.id; // ✅ 문서 ID (문서 자체의 ID)
                                            final detailData = doc.data(); // 👉 참고용

                                            print('✅ travel_rooms 상세 정보:');
                                            print(detailData);

                                            // ✅ 상세 페이지로 이동
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
