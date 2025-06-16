import 'package:flutter/material.dart';
import 'album_service.dart';
import 'album_detail.dart';

class AlbumGrid extends StatefulWidget {
  final String roomId;

  const AlbumGrid({super.key, required this.roomId});

  @override
  State<AlbumGrid> createState() => AlbumGridState();
}

class AlbumGridState extends State<AlbumGrid> {
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;
  bool _selectionMode = false;
  Set<String> _selectedPhotoIds = {};

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    final data = await AlbumService.fetchAlbumPhotos(widget.roomId);
    setState(() {
      _photos = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteSelectedPhotos() async {
    await AlbumService.deletePhotos(widget.roomId, _selectedPhotoIds.toList());
    await loadPhotos(); //삭제 후 리스트 갱신
    setState(() {
      _selectedPhotoIds.clear();
      _selectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("사진을 불러오는 중이에요", style: TextStyle(fontSize: 14)),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: _selectionMode ? Text('${_selectedPhotoIds.length}개 선택됨') : Text("앨범"),
        leading: _selectionMode
            ? IconButton(
            onPressed: (){
              setState(() {
                _selectionMode = false;
                _selectedPhotoIds.clear();
              });
            },
            icon: Icon(Icons.close),
        ) : null,
        actions: [
          if(_selectionMode) ...[
            TextButton(onPressed: (){
              setState(() {
                if(_selectedPhotoIds.length == _photos.length) {
                  _selectedPhotoIds.clear();
                } else {
                  _selectedPhotoIds = _photos.map((photo) => photo['id'] as String).toSet();
                }
              });
            }, child: Text(
              _selectedPhotoIds.length == _photos.length ? '선택 해제' : '전체 선택',
              style: TextStyle(color: Colors.blue),
            ),
            ),
            IconButton(onPressed: _deleteSelectedPhotos, icon: Icon(Icons.delete))
          ]
        ],
      ),
      body:
      _photos.isEmpty
          ? Center(child: Text("사진이 없습니다.", style: TextStyle(fontSize: 14)))
          : GridView.builder(
        padding: EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];
          return GestureDetector(
            onTap: () {
              if (_selectionMode) {
                final id = photo['id'];
                setState(() {
                  if (_selectedPhotoIds.contains(id)) {
                    _selectedPhotoIds.remove(id);
                    if (_selectedPhotoIds.isEmpty) {
                      _selectionMode = false;
                    }
                  } else {
                    _selectedPhotoIds.add(id);
                  }
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                        AlbumDetail(
                          roomId: widget.roomId,
                          imageUrl: photo['image_url'],
                          uploaderId: photo['uploader_id'],
                          timestamp: photo['cdatetime'],
                        ),
                  ),
                );
              }
            },
            onLongPress: () {
              final id = photo['id'];
              setState(() {
                _selectionMode = true;
                _selectedPhotoIds.add(id);
              });
            },
            child: Stack(
              children: [
                Image.network(
                  photo['image_url'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                if (_selectionMode)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(
                      _selectedPhotoIds.contains(photo['id'])
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
