
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AlbumService {

  static Future<bool> uploadAlbumPhoto(String roomId, String uploaderId) async {
    try {
      //1. 이미지 선택
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        return false;
      };

      //2. 이미지 스토리지 업로드
      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('album_photos/$roomId/$filename');

      final fileBytes = await pickedFile.readAsBytes();
      await storageRef.putData(fileBytes);

      final imageUrl = await storageRef.getDownloadURL();

      //3. 컬렉션에서 닉네임 가져오기
      final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uploaderId)
        .get();

      final nickname = userDoc.data()?['nickname'] ?? '닉네임 없음';

      //4. 파이어스토어 저장
      await FirebaseFirestore.instance
          .collection('travel_rooms')
          .doc(roomId)
          .collection('album_photos')
          .add({
        'uploader_id': uploaderId,
        'uploader_nickname' : nickname,
        'image_url': imageUrl,
        'cdatetime': FieldValue.serverTimestamp(),
      });

      // print('✅ 업로드 및 Firestore 저장 성공');
      return true;
    } catch (e) {
      // print('❌ 업로드 실패: $e');
      return false;
    }
  }

  static Future<List<Map<String,dynamic>>>fetchAlbumPhotos(String roomId) async{
    final snapshot = await FirebaseFirestore.instance
        .collection('travel_rooms')
        .doc(roomId)
        .collection('album_photos')
        .orderBy('cdatetime', descending: false) //오름차순
        .get();

    return snapshot.docs.map((doc) => {
      'id' : doc.id,
      ...doc.data()
    }).toList(); //문서를 하나씩 꺼내서 그 안의 데이터를 Map형태로 꺼내서 리스트로 만든다. [{1...},{2...}]
  }

  static deletePhotos(String roomId, List<String>photoDocIds) async{
    final fireStore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    for(final docId in photoDocIds){
      final docRef = fireStore
          .collection('travel_rooms')
          .doc(roomId)
          .collection('album_photos')
          .doc(docId);

      final docSnapshot = await docRef.get();
      final imageUrl = docSnapshot.data()?['image_url'];

      //fireStore 삭제
      await docRef.delete();

      //storage 삭제
      if(imageUrl != null) {
        final ref = storage.refFromURL(imageUrl);
        await ref.delete();
      }
    }
  }
}