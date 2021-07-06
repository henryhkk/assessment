import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_assessment/screens/photo_gallery_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _onPhotoGalleryBtnPressed() async {
    if (await PhotoManager.requestPermission()) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => PhotoGalleryPage()));
    }
  }

  void _onCapturePhotoBtnPressed() async {
    bool isPermissionsGranted = await _isAllPermissionsGranted();
    if (isPermissionsGranted) {
      try {
        final PickedFile? photoPickedFile = await ImagePicker().getImage(
          source: ImageSource.camera,
        );
        if (photoPickedFile != null) {
          Fluttertoast.showToast(msg: 'Saving...');
          final Directory appDir = await getApplicationDocumentsDirectory();
          File capturedPhotoFile = File(photoPickedFile.path);

          //Coordinates
          Position currentPosition = await Geolocator.getCurrentPosition();
          String latitude =
              currentPosition.latitude.toString().replaceAll('.', '');
          String longitude =
              currentPosition.longitude.toString().replaceAll('.', '');
          String coordinateFilename =
              '$latitude-$longitude-${(DateTime.now().millisecondsSinceEpoch / 1000).truncate()}.jpg';

          File imageFile = File(path.join(appDir.path, coordinateFilename));
          imageFile.writeAsBytesSync(capturedPhotoFile.readAsBytesSync());

          //Address
          List<Placemark> placeMarks = await placemarkFromCoordinates(
              currentPosition.latitude, currentPosition.longitude);
          String? street = placeMarks.first.street ?? '';
          String? countryCode = placeMarks.first.isoCountryCode ?? '';
          String? postcode = placeMarks.first.postalCode ?? '';
          String? area =
              (placeMarks.first.administrativeArea ?? '').replaceAll(' ', '');
          String? subLocality =
              (placeMarks.first.subLocality ?? '').replaceAll(' ', '');
          String address = '$street-$subLocality-$postcode-$area-$countryCode';
          String fileName = '$address-${path.basename(imageFile.path)}';

          imageFile =
              imageFile.renameSync(path.join(imageFile.parent.path, fileName));

          final AssetEntity? imageEntity = await PhotoManager.editor
              .saveImageWithPath(imageFile.path, title: fileName);
          File? savedFile = await imageEntity?.file;
          Fluttertoast.showToast(
              msg: (savedFile != null)
                  ? '${path.basename(savedFile.path)} saved'
                  : 'Failed',
              toastLength: Toast.LENGTH_LONG);
        }
      } catch (ex) {
        Fluttertoast.showToast(msg: ex.toString());
      }
    } else {
      Fluttertoast.showToast(
          msg: 'Please allow camera, location, storage permissions');
    }
  }

  Future<bool> _isAllPermissionsGranted() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.location,
      Permission.storage,
      Permission.accessMediaLocation,
    ].request();
    return statuses.values.every((permission) => permission.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Assessment'),
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _onPhotoGalleryBtnPressed,
                style: ElevatedButton.styleFrom(primary: Colors.indigo),
                child: Text(
                  'Photo Gallery',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.tealAccent,
                  ),
                ),
              ),
              ElevatedButton(
                  onPressed: _onCapturePhotoBtnPressed,
                  style: ElevatedButton.styleFrom(primary: Colors.indigo),
                  child: Text(
                    'Capture Photo',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.tealAccent,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
