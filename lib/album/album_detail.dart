import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'album_service.dart';

class AlbumDetail extends StatelessWidget {
  final String imageUrl;
  final String uploaderId;
  final Timestamp? timestamp;
  final String ? photoId; //삭제 id
  final String roomId;

  const AlbumDetail({super.key, required this.imageUrl, required this.uploaderId, this.timestamp, this.photoId, required this.roomId});

  Future<void> saveImage(String imageUrl, BuildContext context) async {
    final status = await Permission.storage.request();
    if(status.isGranted) {
      try {
        final response = await Dio().get(imageUrl,options: Options(responseType: ResponseType.bytes));
        // final result = await ImageGallerySaver.saveImage(
        //   Uint8List.fromList(response.data),
        //   quality: 100,
        // );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진이 저장되었습니다.')),
        );
      }catch(e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류 발생')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 권한이 필요합니다.')),
      );
    }
  }

  Future<void> deletePhoto(BuildContext context) async {
    if (photoId != null) {
      await AlbumService.deletePhotos(roomId, [photoId!]);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진이 삭제되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateTime = timestamp?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('yyyy.MM.dd. HH:mm').format(dateTime);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('상세보기'),
        actions: [
          TextButton(
              onPressed: () => saveImage(imageUrl, context),
              child: Text('저장', style: TextStyle(color: Colors.red),)
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          //hero : 두 화면 간의 애니메이션 전환을 자연스럽게 연결
          children: [
            Hero(
              tag: imageUrl,
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            SizedBox(height: 20,),
            Text('업로더 : $uploaderId', style: TextStyle(color: Colors.white, fontSize: 16)),
            SizedBox(height: 8,),
            Text('업로드일 : $formattedDate', style: TextStyle(color: Colors.white, fontSize: 16))
          ],
        ),
      ),
    );
  }
}
