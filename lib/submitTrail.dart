import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File, Platform;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart';
import 'package:url_launcher/url_launcher.dart';

import 'mapHelper.dart';

// This is the submit trail page when user clickes the FAB.
class SubmitTrailPage extends StatefulWidget {
  @override
  _SubmitTrailPageState createState() => _SubmitTrailPageState();
}

// These are the states managed by the page as a stateful widget
class _SubmitTrailPageState extends State<SubmitTrailPage> {
  TextEditingController contentController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng currentLocation = LatLng(0.0, 0.0);
  String username = "";
  bool isGuestMode = false;
  DateTime currentDate = DateTime.now();
  List<File> selectedPhotos = [];
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _initData();
    _getLocation();
  }

  Future<void> _initData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    username = prefs.getString("username") ?? "";
    setState(() {
      isGuestMode = username.isEmpty;
    });
  }

  Future<void> _getLocation() async {
    try {
      LocationData locationData = await Location().getLocation();
      setState(() {
        currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
        _moveCameraToCurrentLocation();
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _moveCameraToCurrentLocation() {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(currentLocation));
    }
  }

  Future<void> _pickPhotos() async {
    List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      List<File> selectedPhotos = pickedFiles.map((file) => File(file.path)).toList();

      setState(() {
        this.selectedPhotos = selectedPhotos;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${selectedPhotos.length} photos selected."),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No photos selected."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Trail submission logic
  Future<void> _submitTrail() async {
    setState(() {
      isUploading = true;
    });

    _getLocation();

    // Enforcing location fetched correctly
    if (currentLocation.longitude == 0.0 && currentLocation.latitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to submit trail at this time. Please wait for the location to be fetched."),
          duration: Duration(seconds: 2),
        ),
      );
      _getLocation();
      _moveCameraToCurrentLocation();
      setState(() {
        isUploading = false;
      });
    } else {
      final response = await http.post(
        Uri.parse("https://weicheng.app/flutter/addEntry.php"),
        body: {
          "long": currentLocation.longitude.toString(),
          "lat": currentLocation.latitude.toString(),
          "username": username,
          "time": "${currentDate.hour}:${currentDate.minute}:${currentDate.second}",
          "date": "${currentDate.year}-${currentDate.month}-${currentDate.day}",
          "content": contentController.text,
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        int entryId = responseData["entry_id"];

        await _uploadPhotos(entryId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Entry and Photos uploaded successfully!"),
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit trail. Error ${response.statusCode}"),
            duration: Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        isUploading = false;
      });
    }
  }

  // Photos uploading logic
  Future<void> _uploadPhotos(int entryId) async {
    for (int i = 0; i < selectedPhotos.length; i++) {
      File photo = selectedPhotos[i];

      if(Platform.isIOS){
        photo = await adjustImageRotation(photo.path);
      }

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://weicheng.app/flutter/addPhoto.php"),
      );

      request.fields["username"] = username;
      request.fields["entry_id"] = entryId.toString();

      request.files.add(await http.MultipartFile.fromPath(
        "photos[]",
        photo.path,
        filename: "photo_$i.jpg",
      ));

      // Monitor the upload progress
      http.Client().send(request).then((responseStream) {
        var contentLength = responseStream.contentLength;
        var bytesUploaded = 0;

        responseStream.stream.listen(
              (List<int> chunk) {
            bytesUploaded += chunk.length;
            // Calculate progress percentage and update UI as needed
            double progress = bytesUploaded / contentLength!;
            print("Photo $i upload progress: ${(progress * 100).toStringAsFixed(2)}%");
          },
          onDone: () {
            print("Photo $i uploaded successfully!");
          },
          onError: (error) {
            print("Error uploading photo $i: $error");
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Brightness currentBrightness = MediaQuery.of(context).platformBrightness;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text("New Memory Submission"),
          ],
        ),
        backgroundColor: Platform.isIOS ? null : Theme.of(context).colorScheme.secondaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/story_trail.png',
              height: 100,
              width: 100,
            ),
            SizedBox(height: 16),
            if (isGuestMode)
              Column(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(height: 10),
                  Text("You are in guest mode. Log in to submit a trail."),
                ],
              ),
            if (!isGuestMode)
              Text(
                "Current Date and Time: \n${currentDate.toLocal().toString().split('.')[0]}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            if (!isGuestMode)
              TextField(
                focusNode: FocusNode(),
                decoration: InputDecoration(labelText: "Content"),
                maxLines: 10,
                autofocus: true,
                onEditingComplete:() {
                  FocusScope.of(context).unfocus();
                },
                onChanged: (content) {
                  contentController.text = content;
                },
              ),
            if (!isGuestMode)
              SizedBox(height: 16),
            if (!isGuestMode)
              Container(
                height: 200,
                child: GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _moveCameraToCurrentLocation();
                    setMapTheme(controller, currentBrightness == Brightness.dark);
                    if (currentLocation.latitude == 0.0 && currentLocation.longitude == 0.0) {
                      _getLocation();
                      if (currentLocation.latitude == 0.0 && currentLocation.longitude == 0.0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Location is not currently fetched, please wait a while."),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        _getLocation();
                      }
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: currentLocation,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId("currentLocation"),
                      position: currentLocation,
                      infoWindow: InfoWindow(title: "Current Location"),
                    ),
                  },
                ),
              ),
            if (!isGuestMode)
              SizedBox(height: 16),
            if (isUploading)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Uploading..."),
                ],
              ),
            if (!isGuestMode)
              ElevatedButton(
                onPressed: isUploading ? null : () async => await _submitTrail(),
                child: Text("Submit Your Memory"),
              ),
            if (!isGuestMode)
              SizedBox(height: 16),
            if (!isGuestMode)
              ElevatedButton(
                onPressed: isUploading ? null : () async => await _pickPhotos(),
                child: Text("Select Photos"),
              ),
            if(!isGuestMode && Platform.isAndroid)
              ElevatedButton(
                onPressed: isUploading ? null : () => _openCameraApp(context),
                child: Text("Open Camera & Return"),
              ),
          ],
        ),
      ),
    );
  }
}

void _openCameraApp(BuildContext context) async {
  final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);

  if (image != null) {
    // Save the captured image to the gallery
    await _saveImageToGallery(image.path);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Image saved to gallery."),
        duration: Duration(seconds: 2),
      ),
    );
    // Navigate back to the previous page
    // Navigator.pop(context);
  }
}

Future<void> _saveImageToGallery(String imagePath) async {
  final result = await ImageGallerySaver.saveFile(imagePath);

  if (result != null && result.isNotEmpty) {
    print("Image saved to gallery");
  } else {
    print("Failed to save image to gallery");
  }
}

Future<File> adjustImageRotation(String imagePath) async {
  // This function is helpful when iOS devices has different image exif data
  final sourceFile = File(imagePath);
  Uint8List imageData = await sourceFile.readAsBytes();

  final sourceImage = img.decodeImage(imageData);

  final imageHeight = sourceImage?.height;
  final imageWidth = sourceImage?.width;

  if (imageHeight! >= imageWidth!) {
    return sourceFile;
  }

  final exifInfo = await readExifFromBytes(imageData);

  img.Image rotatedImage = img.Image(width: 0, height: 0);

  if (imageHeight < imageWidth) {
    if (exifInfo['Image Orientation']!.printable.contains('Horizontal')) {
      rotatedImage = img.copyRotate(sourceImage!, angle: 90);
    } else if (exifInfo['Image Orientation']!.printable.contains('180')) {
      rotatedImage = img.copyRotate(sourceImage!, angle: -90);
    } else {
      rotatedImage = img.copyRotate(sourceImage!, angle: 0);
    }
  }

  final rotatedFile = await sourceFile.writeAsBytes(img.encodeJpg(rotatedImage));

  return rotatedFile;
}