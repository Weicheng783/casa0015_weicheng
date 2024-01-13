import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:story.trail/login.dart';

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

  String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    _initMap();
    _fetchLoggedInUsername();
  }

  Future<void> _fetchLoggedInUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');

    setState(() {
      loggedInUsername = username ?? '';
    });
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 96.0,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        "/",
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.0),
                      Icon(
                        Icons.downloading,
                        size: 96.0,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),

                  SizedBox(height: 16.0),
                  Text(
                    "Location Permission Required \n Map Loading",
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
                      _fetchLoggedInUsername();
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
                            tappedMarkerIds.clear();
                            tappedMarkerInfos.clear();
                            tappedMarkerIds.add(MarkerId(marker.entryId.toString()));
                            tappedMarkerInfos.add(TappedMarkerInfo(entryMarker: marker));
                            setState(() {});
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

              NavigationHelper.buildEntryDetailsCard(tappedMarkerIds, entryMarkers),

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

class NavigationHelper {
  static Widget buildEntryDetailsCard(Set<MarkerId> tappedMarkerIds, List<EntryMarker> entryMarkers) {
    if (tappedMarkerIds.isNotEmpty) {
      return Card(
        elevation: 5.0,
        margin: EdgeInsets.all(16.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Only display details for the first tapped marker
              EntryDetailsWidget(
                entryMarker: entryMarkers.firstWhere(
                      (marker) => marker.toMarker().markerId == tappedMarkerIds.first,
                ),
              ),
              // ... (add more details as needed)
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink(); // Return an empty container if there are no tapped markers
    }
  }
}

class EntryDetailsWidget extends StatelessWidget {
  final EntryMarker entryMarker;
  bool hasSeen = false;

  EntryDetailsWidget({required this.entryMarker});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display latitude and longitude for all users
        Text("Latitude: ${entryMarker.latitude}"),
        Text("Longitude: ${entryMarker.longitude}"),

        // Fetch user history and determine if the user has explored or owned the marker
        FutureBuilder<List<Map<String, dynamic>>?>(
          future: fetchUserHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text("Error fetching user history: ${snapshot.error}");
            } else {
              final List<Map<String, dynamic>> userHistory = snapshot.data ?? [];
              print("ALl data:$userHistory");

              // Check if the user has explored or owned the marker position using userHistory
              hasSeen = hasExploredOrOwnedEntry(userHistory, entryMarker.entryId);

              print("hasSeen: $hasSeen");

              // Conditionally display additional information based on user's history
              if (hasSeen) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Display additional information for users who have owned or explored the marker
                    Text("Entry ID: ${entryMarker.entryId}"),
                    Text("Time: ${entryMarker.time}"),
                    Text("Date: ${entryMarker.date}"),
                    Text("Content: ${entryMarker.content}"),
                  ],
                );
              } else {
                // return SizedBox.shrink(); // Hide details for users who haven't explored or owned the marker
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("You haven't explored this memory yet."),
                    // Text("Latitude: ${entryMarker.latitude}"),
                    // Text("Longitude: ${entryMarker.longitude}"),
                  ],
                );
              }
            }
          },
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>?> fetchUserHistory() async {
    try {
      // Fetch user history by calling the API endpoint
      final response = await http.post(
        Uri.parse('https://weicheng.app/flutter/user.php'),
        body: {'username': loggedInUsername},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Extract entries_created and entries_explored data from the response
        final List<dynamic> entriesData = responseData['entries_created'] ?? [];
        final List<dynamic> exploredData = responseData['entries_explored'] ?? [];

        return List<Map<String, dynamic>>.from(entriesData + exploredData);
      } else {
        throw Exception('Failed to fetch user history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user history: $e');
    }
  }


// Check if the user has explored the entry
  bool hasExploredOrOwnedEntry(List<Map<String, dynamic>> userHistory, String entryId) {
    print('User History: $userHistory');

    return userHistory.any((entry) {
      print('Entry: $entry');

      if (entry['entry_id'] == entryId) {
        return true;
      } else {
        return false;
      }
    });
  }

}

class UserHistory {
  final String username;
  final List<Map<String, dynamic>> entriesCreated;
  final List<Map<String, dynamic>> entriesExplored;

  UserHistory({
    required this.username,
    required this.entriesCreated,
    required this.entriesExplored,
  });

  factory UserHistory.fromMap(Map<String, dynamic> map) {
    return UserHistory(
      username: map['username'],
      entriesCreated: List<Map<String, dynamic>>.from(map['entries_created']),
      entriesExplored: List<Map<String, dynamic>>.from(map['entries_explored']),
    );
  }

  bool hasExplored(String entryId) {
    return entriesExplored.any((entry) => entry['entry_id'] == entryId);
  }

  bool hasOwned(String entryId) {
    return entriesCreated.any((entry) => entry['entry_id'] == entryId);
  }
}