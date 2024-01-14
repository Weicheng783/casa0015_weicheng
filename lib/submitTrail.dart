import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File, Platform;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mapHelper.dart';

class SubmitTrailPage extends StatefulWidget {
  @override
  _SubmitTrailPageState createState() => _SubmitTrailPageState();
}

class _SubmitTrailPageState extends State<SubmitTrailPage> {
  TextEditingController contentController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng currentLocation = LatLng(0.0, 0.0);
  String username = "";
  bool isGuestMode = false;
  DateTime currentDate = DateTime.now();
  List<File> selectedPhotos = [];

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

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      List<File> selectedPhotos = pickedFiles.map((file) => File(file.path)).toList();

      setState(() {
        this.selectedPhotos = selectedPhotos;
      });

      // You can handle the selected photos as needed
      // For example, display them in your UI or show the number of selected photos
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

  Future<void> _submitTrail() async {
    if (isGuestMode) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Guest Mode"),
            content: Column(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(height: 10),
                Text("You are in guest mode. Log in to submit a trail."),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } else {
      _getLocation();
      if (currentLocation.longitude == 0.0 && currentLocation.latitude == 0.0) {
        print("Failed to submit trail at this time, this is due to the location is not fetched, wait until the map moves.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit trail at this time, this is due to the location is not fetched, wait until the map moves."),
            duration: Duration(seconds: 2),
          ),
        );
        _getLocation();
        _moveCameraToCurrentLocation();
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
          print("Trail submitted successfully!");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Trail submitted successfully! Now, wait for photos uploading."),
              duration: Duration(seconds: 2),
            ),
          );

          // Get entry_id from the successful response
          Map<String, dynamic> responseData = jsonDecode(response.body);
          int entryId = responseData["entry_id"];

          // Upload photos
          await _uploadPhotos(entryId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Entry and Photos uploaded successfully!"),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        } else {
          print("Failed to submit trail. Error ${response.statusCode}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to submit trail. Error ${response.statusCode}"),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _uploadPhotos(int entryId) async {
    for (int i = 0; i < selectedPhotos.length; i++) {
      File photo = selectedPhotos[i];

      // Create a request to addPhoto.php
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://weicheng.app/flutter/addPhoto.php"),
      );

      // Add parameters
      request.fields["username"] = username;
      request.fields["entry_id"] = entryId.toString();

      // Add photo as a file
      request.files.add(await http.MultipartFile.fromPath(
        "photos[]",
        photo.path,
        filename: "photo_$i.jpg", // Set the filename as needed
      ));

      // Send the request
      var response = await request.send();

      // Check the response
      if (response.statusCode == 200) {
        print("Photo $i uploaded successfully!");
      } else {
        print("Failed to upload photo $i. Error ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to upload photo $i. Error ${response.statusCode}"),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
                "Current Date and Time: ${currentDate.toLocal().toString().split('.')[0]}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            if (!isGuestMode)
              TextField(
                focusNode: FocusNode(),
                decoration: InputDecoration(labelText: "Content"),
                maxLines: 10,
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
            if (!isGuestMode)
              ElevatedButton(
                onPressed: () async {
                  await _submitTrail();
                },
                child: Text("Submit Your Memory"),
              ),
            if (!isGuestMode)
              SizedBox(height: 16),
            if (!isGuestMode)
              ElevatedButton(
                onPressed: () async {
                  await _pickPhotos(); // Assume _pickPhotos is a method to select photos
                },
                child: Text("Select Photos"),
              ),
          ],
        ),
      ),
    );
  }
}
