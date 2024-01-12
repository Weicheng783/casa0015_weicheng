import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

import 'main.dart';
import 'mapHelper.dart';

class LocationService {
  static Future<LocationData> getLocation() async {
    Location location = Location();

    try {
      return await location.getLocation();
    } catch (e) {
      print('Error: $e');
      throw e;
    }
  }

  static Future<bool> requestLocationPermission() async {
    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return false;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }
}

class MapSample extends StatefulWidget {
  @override
  MapSampleState createState() => MapSampleState();
}

class LocationInfo extends StatelessWidget {
  final double latitude;
  final double longitude;

  LocationInfo({required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Latitude: $latitude"),
        Text("Longitude: $longitude"),
        // Add more information as needed, e.g., orientation, etc.
      ],
    );
  }
}

class TappedMarkerInfo {
  final EntryMarker entryMarker;

  TappedMarkerInfo({required this.entryMarker});
}

List<EntryMarker> entryMarkers = [];
Set<MarkerId> tappedMarkerIds = Set();
Set<TappedMarkerInfo> tappedMarkerInfos = Set();

class MapSampleState extends State<MapSample> {
  late GoogleMapController mapController;
  LocationData? currentLocation;
  bool locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  void _initMap() async {
    try {
      locationPermissionGranted = await LocationService.requestLocationPermission();

      if (locationPermissionGranted) {
        await _updateLocation();
        await _fetchEntries();
      }
    } catch (e) {
      print('Error initializing map: $e');
    }
  }

  Future<void> _updateLocation() async {
    try {
      currentLocation = await LocationService.getLocation();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  Future<void> _fetchEntries() async {
    try {
      // Replace 'your_server_url/getEntry.php' with the actual URL of your getEntry.php script
      final response = await http.post(
        Uri.parse('https://weicheng.app/flutter/getEntry.php'),
        body: {'username': 'your_logged_in_username', 'user_id': 'your_logged_in_user_id'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> entriesData = json.decode(response.body);

        setState(() {
          entryMarkers = entriesData.map((entry) {
            EntryMarker marker = EntryMarker.fromMap(entry);
            print('Entry ID: ${marker.entryId}, Latitude: ${marker.latitude}, Longitude: ${marker.longitude}');
            return marker;
          }).toList();
        });
      } else {
        print('Failed to fetch entries: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching entries: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Brightness currentBrightness = MediaQuery.of(context).platformBrightness;

    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        // padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!locationPermissionGranted || currentLocation == null)
              Column(
                children: [
                  // Large centered icon and explanatory text
                  Icon(
                    Icons.location_off,
                    size: 96.0,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    "Location Permission Required",
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    "To use this app, please grant location permission.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            if (locationPermissionGranted && currentLocation != null)
              Container(
                width: MediaQuery.of(context).size.width,
                height: 300,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 5.0,
                  child: GoogleMap(
                    onMapCreated: (controller) {
                      mapController = controller;
                      setMapTheme(mapController, currentBrightness == Brightness.dark);
                      updateMapCamera(); // Center the map initially
                      getLoggedInUsername();
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        currentLocation!.latitude ?? 0.0,
                        currentLocation!.longitude ?? 0.0,
                      ),
                      zoom: 15.0,
                    ),
                    myLocationEnabled: true,
                    tiltGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    // markers: {
                    //   const Marker(
                    //     markerId: MarkerId('Sydney'),
                    //     position: LatLng(51.536215, -0.011637),
                    //   ),
                    // },
                    markers: Set.from(entryMarkers.map((marker) {
                      return Marker(
                        markerId: MarkerId(marker.entryId.toString()),
                        position: LatLng(double.parse(marker.latitude), double.parse(marker.longitude)),
                        onTap: () {
                          print(marker.entryId.toString());
                          // Update state to show details for the tapped marker
                          setState(() {
                            tappedMarkerIds.add(MarkerId(marker.entryId.toString()));
                            tappedMarkerInfos.add(TappedMarkerInfo(entryMarker: marker));
                          });
                        },
                      );
                    })),
                    onTap: (_) {
                      // Clear tapped markers when the map is tapped
                      setState(() {
                        tappedMarkerIds.clear();
                        tappedMarkerInfos.clear();
                      });
                    },
                  ),
                ),
              ),
            SizedBox(height: 16.0),
            // Centered button with icon
            if (!locationPermissionGranted)
              ElevatedButton.icon(
                onPressed: () async {
                  bool granted = await LocationService.requestLocationPermission();
                  if (granted) {
                    setState(() {
                      locationPermissionGranted = true;
                    });
                    await _updateLocation();
                  }
                },
                icon: Icon(Icons.location_on),
                label: Text("Grant Location Permission"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void updateMapCamera() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            currentLocation!.latitude ?? 0.0,
            currentLocation!.longitude ?? 0.0,
          ),
          zoom: 15.0,
        ),
      ),
    );
  }
}