import 'package:flutter/material.dart';
import 'album_service.dart';
import 'album_detail.dart';
import '../models/photo_model.dart';

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

  List<Photo> get photoList =>
      _photos
          .map(
            (map) => Photo(
              photoId: map['id'],
              imageUrl: map['image_url'],
              uploaderId: map['uploader_id'],
              timestamp: map['timestamp'],
              uploaderNickname: map['uploader_nickname'],
            ),
          )
          .toList();

  Widget _buildGridBody() {
    if (_photos.isEmpty) {
      return Center(child: Text("사진이 없습니다.", style: TextStyle(fontSize: 14)));
    }

    return GridView.builder(
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
        final id = photo['id'];

        return GestureDetector(
          onTap: () {
            if (_selectionMode) {
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
                      (context) => AlbumDetail(
                        photos: photoList,
                        roomId: widget.roomId,
                        initialIndex: index,
                      ),
                ),
              );
            }
          },
          onLongPress: () {
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
                    _selectedPhotoIds.contains(id)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: Color(0xFF1E6FD9),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultAlbumLayout() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/common_images/logo-main-ver1.png',
                height: 52,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF1E6FD9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '앨범',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildGridBody()),
        ],
      ),
    );
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
    return _selectionMode
        ? Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            title:
                _selectionMode
                    ? Text('${_selectedPhotoIds.length}개 선택됨')
                    : Text("앨범"),
            leading:
                _selectionMode
                    ? IconButton(
                      onPressed: () {
                        setState(() {
                          _selectionMode = false;
                          _selectedPhotoIds.clear();
                        });
                      },
                      icon: Icon(Icons.close),
                    )
                    : null,
            actions: [
              if (_selectionMode) ...[
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedPhotoIds.length == _photos.length) {
                        _selectedPhotoIds.clear();
                      } else {
                        _selectedPhotoIds =
                            _photos
                                .map((photo) => photo['id'] as String)
                                .toSet();
                      }
                    });
                  },
                  child: Text(
                    _selectedPhotoIds.length == _photos.length
                        ? '선택 해제'
                        : '전체 선택',
                    style: TextStyle(color: Color(0xFF1E6FD9)),
                  ),
                ),
                IconButton(
                  onPressed: _deleteSelectedPhotos,
                  icon: Icon(Icons.delete),
                ),
              ],
            ],
          ),
          body: _buildGridBody(),
        )
        : Scaffold(body: _buildDefaultAlbumLayout());
  }
}
