import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/photo_model.dart';
import 'album_service.dart';

class AlbumDetail extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;
  final String roomId;

  const AlbumDetail({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.roomId,
  });

  @override
  State<AlbumDetail> createState() => _AlbumDetailState();
}

class _AlbumDetailState extends State<AlbumDetail> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  Photo get currentPhoto => widget.photos[_currentIndex];

  Future<void> saveImage(String imageUrl, BuildContext context) async {
    final status = await Permission.photos.request(); // Android 33+ 대응
    if (status.isGranted) {
      try {
        final response = await Dio().get(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        final result = await ImageGallerySaverPlus.saveImage(
          Uint8List.fromList(response.data),
          quality: 100,
          name: "photo_${DateTime.now().millisecondsSinceEpoch}",
        );
        if (result['isSuccess'] == true || result['filePath'] != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('사진이 저장되었습니다.')));
        } else {
          throw Exception("저장 실패");
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 중 오류 발생')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 권한이 필요합니다.')));
    }
  }

  Future<void> deletePhoto(BuildContext context) async {
    if (currentPhoto.photoId != null) {
      await AlbumService.deletePhotos(widget.roomId, [currentPhoto.photoId!]);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('사진이 삭제되었습니다.')));
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'yyyy.MM.dd. HH:mm',
    ).format(currentPhoto.timestamp?.toDate() ?? DateTime.now());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('상세보기'),
        actions: [
          TextButton(
            onPressed: () => saveImage(currentPhoto.imageUrl, context),
            child: Text('저장', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 이미지 스와이프 뷰
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.photos.length,
                  onPageChanged:
                      (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final photo = widget.photos[index];
                    return Hero(
                      tag: photo.imageUrl,
                      child: InteractiveViewer(
                        child: Center(
                          child: Image.network(
                            photo.imageUrl,
                            fit: BoxFit.contain,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.6,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // 왼쪽 화살표
                if (_currentIndex > 0)
                  Positioned(
                    left: 12,
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white70,
                      size: 32,
                    ),
                  ),
                // 오른쪽 화살표
                if (_currentIndex < widget.photos.length - 1)
                  Positioned(
                    right: 12,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 32,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '업로더: ${currentPhoto.uploaderNickname ?? '알 수 없음'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '업로드 시간: $formattedDate',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
