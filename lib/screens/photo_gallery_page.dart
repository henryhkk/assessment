import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoGalleryPage extends StatefulWidget {
  PhotoGalleryPage({Key? key}) : super(key: key);

  @override
  _PhotoGalleryPageState createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  final int _pageSize = 36;
  int currentPage = 0;

  List<AssetPathEntity> photoAlbums = [];
  List<AssetEntity> imageList = [];
  bool loadMore = false;

  void _onImageItemLongPressed(File imageFile) {
    String imageFileName = imageFile.path.split('/').last;
    Fluttertoast.showToast(
        msg: imageFileName,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white);
  }

  Future<void> _loadPhotoFromAlbum() async {
    List<AssetEntity> mediaList =
        await photoAlbums.first.getAssetListPaged(currentPage, _pageSize);
    setState(() {
      imageList.addAll(mediaList);
      currentPage++;
      loadMore = !(mediaList.length < _pageSize);
    });
  }

  Future<void> _getPhotoAlbum() async {
    photoAlbums = await PhotoManager.getAssetPathList(
        onlyAll: true, type: RequestType.image);
    if (photoAlbums.isNotEmpty) {
      _loadPhotoFromAlbum();
    }
  }

  @override
  void initState() {
    super.initState();
    _getPhotoAlbum();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Photo'),
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        child: (imageList.isEmpty)
            ? Container()
            : NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo is ScrollUpdateNotification) {
                    if (loadMore &&
                        scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent) {
                      loadMore = false;
                      _loadPhotoFromAlbum();
                    }
                  }
                  return true;
                },
                child: GridView.builder(
                    scrollDirection: Axis.vertical,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, childAspectRatio: 1),
                    itemCount: imageList.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder(
                          future: imageList[index].file,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return GestureDetector(
                                onLongPress: () {
                                  _onImageItemLongPressed(
                                      snapshot.data as File);
                                },
                                child: Card(
                                  child: Image.file(
                                    snapshot.data as File,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            }
                            return Container();
                          });
                    }),
              ),
      ),
    );
  }
}
