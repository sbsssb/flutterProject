import 'package:cloud_firestore/cloud_firestore.dart';

class Photo {
  final String imageUrl;
  final String uploaderId;
  final Timestamp? timestamp;
  final String? photoId;
  final String? uploaderNickname;

  const Photo({
    required this.imageUrl,
    required this.uploaderId,
    required this.timestamp,
    this.photoId,
    this.uploaderNickname
  });
}