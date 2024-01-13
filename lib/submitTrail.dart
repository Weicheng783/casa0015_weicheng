import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io' show Platform;
import 'package:location/location.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:story.trail/mapHelper.dart';

import 'main.dart';

class SubmitTrailPage extends StatefulWidget {
  @override
  _SubmitTrailPageState createState() => _SubmitTrailPageState();
}

class _SubmitTrailPageState extends State<SubmitTrailPage> {
  TextEditingController contentController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng currentLocation = LatLng(0.0, 0.0); // Initial placeholder
  String username = "";
  bool isGuestMode = false;
  DateTime currentDate = DateTime.now();

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
      // Handle location retrieval error here
    }
  }

  void _moveCameraToCurrentLocation() {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(currentLocation));
    }
  }

  Future<void> _submitTrail() async {
    if (isGuestMode) {
      // Show appropriate message and prevent submission in guest mode
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
      if(currentLocation.longitude == 0.0 && currentLocation.latitude == 0.0){
        // Handle error
        print("Failed to submit trail at this time, this is due to the location is not fetched, wait until the map moves.");
        // You can display an error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit trail at this time, this is due to the location is not fetched, wait until the map moves."),
            duration: Duration(seconds: 2),
          ),
        );
        _getLocation();
        _moveCameraToCurrentLocation();
      }else{
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
          // Handle success
          print("Trail submitted successfully!");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Trail submitted successfully! Restart the app to view."),
              duration: Duration(seconds: 2),
            ),
          );

          Navigator.pop(context, true); // Return to previous page with a success indicator
        } else {
          // Handle error
          print("Failed to submit trail. Error ${response.statusCode}");
          // You can display an error message to the user
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

  @override
  Widget build(BuildContext context) {
    Brightness currentBrightness = MediaQuery.of(context).platformBrightness;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.green), // Relevant icon
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
                "Current Date and Time: ${currentDate.toLocal().toString().split('.')[0]}", // Format date and time
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            if (!isGuestMode)
              TextField(
                // controller: contentController,
                focusNode: FocusNode(),
                decoration: InputDecoration(labelText: "Content"),
                maxLines: 10,
                onChanged: (content){
                  contentController.text = content;
                },
              ),
            if (!isGuestMode)
              SizedBox(height: 16),
            if (!isGuestMode)
              Container(
              height: 200, // Set the height as needed
              child: GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  _moveCameraToCurrentLocation();
                  setMapTheme(controller, currentBrightness == Brightness.dark);
                  if(currentLocation.latitude == 0.0 && currentLocation.longitude == 0.0){
                    _getLocation();
                    if(currentLocation.latitude == 0.0 && currentLocation.longitude == 0.0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Location is not currently fetched, please wait a while."),
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
                onPressed: _submitTrail,
                child: Text("Submit Your Memory"),
              ),
          ],
        ),
      ),
    );
  }
}