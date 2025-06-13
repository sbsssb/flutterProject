import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AlbumPage extends StatelessWidget {
  final String roomId = 'album_test';
  final String uploaderId = 'newStar';

  const AlbumPage({super.key}); //, required this.roomId, required this.uploaderId Todo:추후 파라미터로 받아오기

  Future<void> uploadAlbumPhoto(String roomId, String uploaderId) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('album_photos/$roomId/$filename');

      final fileBytes = await pickedFile.readAsBytes(); // ✅ 변경 핵심
      await storageRef.putData(fileBytes);              // ✅ 여기만 바뀜

      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('travel_rooms')
          .doc(roomId)
          .collection('album_photos')
          .add({
        'uploader_id': uploaderId,
        'image_url': imageUrl,
        'cdatetime': FieldValue.serverTimestamp(),
      });

      print('✅ 업로드 및 Firestore 저장 성공');
    } catch (e) {
      print('❌ 업로드 실패: $e');
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('앨범'),),
      body: Center(
        child: Text('사진 그리드 구현 예정'),
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            await uploadAlbumPhoto(roomId, uploaderId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('사진 업로드 완료!')),
            );
          }
      ),
    );
  }
}
