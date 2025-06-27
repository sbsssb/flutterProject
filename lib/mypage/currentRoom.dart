import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/bottom_nav_bar.dart';
import '../travelroom/travelDetail.dart';
import 'appbar.dart';

class CurrentRoomApp extends StatelessWidget {
  final String userId;
  const CurrentRoomApp({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CurrentRoomIn(userId: userId);
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


  List<DocumentSnapshot> pageCursors = [];

  @override
  void initState() {
    super.initState();
    fetchTravelRooms(page: 1);
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


    final filteredRooms = <Map<String, dynamic>>[];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final roomId = data['room_id'];
      final isOwner = data['is_owner'] ?? false;


      final travelRoomDoc = await FirebaseFirestore.instance
          .collection('travel_rooms')
          .doc(roomId)
          .get();

      final travelRoomData = travelRoomDoc.data();
      if (travelRoomData == null) continue;

      final isDone = travelRoomData['is_done'] ?? false;
      if (isDone == false) {

      }


      if (isDone == false) {

        final membersSnapshot = await FirebaseFirestore.instance
            .collection('travel_rooms')
            .doc(roomId)
            .collection('members')
            .get();

        filteredRooms.add({
          'room_id': roomId,
          'title': '${data['region']} 여행',
          'members': membersSnapshot.size,
          'theme': data['theme'],
          'cdatetime': data['cdatetime'],
          'is_owner': isOwner,
        });
      }
    }

    setState(() {
      travelRooms = filteredRooms;
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


    final joinRoomsSnapshot = await firestore.collectionGroup('join_rooms')
        .where('room_id', isEqualTo: roomId)
        .get();

    for (final doc in joinRoomsSnapshot.docs) {
      await doc.reference.delete();
    }


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


    await firestore.collection('travel_rooms').doc(roomId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                                      await fetchTravelRooms(page: currentPage);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('여행방이 삭제되었습니다.')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('삭제', style: TextStyle(color: Colors.white),),
                                )
                              else
                                const SizedBox(),

                              ElevatedButton(
                                onPressed: () async {
                                  final roomId = room['room_id'];


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

                                    }
                                  } catch (e) {

                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('이동', style: TextStyle(color: Colors.white),),
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

                  IconButton(
                    onPressed: currentPage > 1 ? () {
                      fetchTravelRooms(page: currentPage - 1);
                    } : null,
                    icon: const Icon(Icons.chevron_left),
                  ),


                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () {},
                      child: Text('$currentPage',style: TextStyle(fontFamily: 'AstaSans', fontSize: 18, color: Color(0xFF1E6FD9)),),
                    ),
                  ),


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
