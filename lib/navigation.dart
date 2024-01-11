import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

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

  @override
  Widget build(BuildContext context) {
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
                    color: Colors.red,
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
                      updateMapCamera(); // Center the map initially
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