import 'package:flutter/material.dart';
import 'dart:io';
import 'album_service.dart';
import 'album_grid.dart';
import '../user/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlbumPage extends ConsumerStatefulWidget {
  const AlbumPage({
    super.key,
  }); //, required this.roomId, required this.uploaderId Todo:추후 파라미터로 받아오기

  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage> {
  final String roomId = 'album_test';

  //업로드 후 그리드 새로고침
  final GlobalKey<AlbumGridState> _gridKey = GlobalKey();

  void _refreshPhotos() {
    _gridKey.currentState?.loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final uploaderId = user?.uid;

    return Scaffold(
      body: AlbumGrid(key: _gridKey, roomId: roomId),
      floatingActionButton:
          uploaderId == null
              ? null
              : FloatingActionButton(
                backgroundColor: Color(0xFF1E6FD9),
                child: Icon(Icons.add, color: Colors.white),
                onPressed: () async {
                  //사진 업로드
                  await AlbumService.uploadAlbumPhoto(roomId, uploaderId);
                  //리스트 새로고침
                  _refreshPhotos();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('사진 업로드 완료!')));
                },
              ),
    );
  }
}
