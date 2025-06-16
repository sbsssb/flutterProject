import 'package:flutter/material.dart';
import 'dart:io';
import 'album_service.dart';
import 'album_grid.dart';

class AlbumPage extends StatefulWidget {

  const AlbumPage(
      {super.key}); //, required this.roomId, required this.uploaderId Todo:추후 파라미터로 받아오기

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  final String roomId = 'album_test';
  final String uploaderId = 'newStar';
  
  //업로드 후 그리드 새로고침
  final GlobalKey<AlbumGridState> _gridKey = GlobalKey();
  void _refreshPhotos(){
    _gridKey.currentState?.loadPhotos();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    body: AlbumGrid(
        key: _gridKey,
        roomId: roomId
    ),
    floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          //사진 업로드
          await AlbumService.uploadAlbumPhoto(roomId, uploaderId);
          //리스트 새로고침
          _refreshPhotos();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('사진 업로드 완료!')),
          );
        }
    ),
    );
  }
}
