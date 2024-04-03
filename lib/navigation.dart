import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:story.trail/login.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

import 'main.dart';
import 'mapHelper.dart';

// This is the location service as a whole
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

  // Pops-up a window for requesting user location permission
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

// MapSample widget, a test for the map implementation
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

// When one of the markers is tapped.
class TappedMarkerInfo {
  final EntryMarker entryMarker;

  TappedMarkerInfo({required this.entryMarker});
}

// The following variables, constants are serving the functionality of detecting nearest distance.
List<EntryMarker> entryMarkers = [];
Set<MarkerId> tappedMarkerIds = Set();
Set<TappedMarkerInfo> tappedMarkerInfos = Set();

TextEditingController commentController = TextEditingController();
late EntryMarker? nearestUnexploredEntry;
bool showButtonNow = false;
bool vibrationOn = true;
double nowDistance = 999.99;
double mapZoomLevel = 15;
String friendsUserNameList = '';

// The main map markers logic
class MapSampleState extends State<MapSample> {
  GoogleMapController? mapController;
  LocationData? currentLocation;
  bool locationPermissionGranted = false;

  String loggedInUsername = '';
  bool isNearby = false;
  bool autoFindNearestEnabled = true;

  @override
  void initState() {
    super.initState();
    _initMap();
    _fetchLoggedInUsername();
    _fetchFriendsUsername();
    _checkNearbyMarkers();
    _findNearestUnexploredEntry();
  }

  Future<void> _findNearestUnexploredEntry() async {
    // Get the user's location
    LocationData userLocation = await LocationService.getLocation();

    // Filter unexplored entries
    List<EntryMarker> unexploredEntries = entryMarkers.where((entry) {
      return !hasExploredOrOwnedEntry(userHistoryPub, entry.entryId);
    }).toList();

    if (unexploredEntries.isNotEmpty) {
      // Calculate distances to unexplored entries
      unexploredEntries.forEach((entry) {
        print("unexplored entries id: "+entry.entryId);
        entry.distanceToUser = calculateDistance(
          userLocation.latitude!,
          userLocation.longitude!,
          double.parse(entry.latitude),
          double.parse(entry.longitude),
        );
      });

      // Find the nearest unexplored entry
      nearestUnexploredEntry = unexploredEntries.reduce((a, b) =>
      a.distanceToUser < b.distanceToUser ? a : b);

      nowDistance = nearestUnexploredEntry!.distanceToUser;

      // Automatically set the map scale factor based on distance
      double zoomLevel = _calculateZoomLevel(nearestUnexploredEntry!.distanceToUser);
      print("zoomlevel: $zoomLevel");
      mapZoomLevel = zoomLevel;

      // Update the map camera to show both user and entry
      try {
        mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                min(userLocation.latitude!,
                    double.parse(nearestUnexploredEntry!.latitude)),
                min(userLocation.longitude!,
                    double.parse(nearestUnexploredEntry!.longitude)),
              ),
              northeast: LatLng(
                max(userLocation.latitude!,
                    double.parse(nearestUnexploredEntry!.latitude)),
                max(userLocation.longitude!,
                    double.parse(nearestUnexploredEntry!.longitude)),
              ),
            ),
            50.0, // Padding in pixels
          ),
        );
      }catch(e){
        _initMap();
      }

      // mapController.animateCamera(
      //   CameraUpdate.zoomTo(zoomLevel),
      // );

      // Automatically display information for the selected entry
      try {
        setState(() {
          tappedMarkerIds.clear();
          tappedMarkerInfos.clear();
          tappedMarkerIds.add(MarkerId(nearestUnexploredEntry!.entryId));
          tappedMarkerInfos.add(
              TappedMarkerInfo(entryMarker: nearestUnexploredEntry!));
        });
      }catch(e){
        _initMap();
      }
    }
  }

  double _calculateZoomLevel(double distance) {
    // You can customize this formula based on your preferences
    const double maxDistance = 5000; // Maximum distance in meters for maximum zoom
    const double minZoom = 10.0; // Minimum zoom level
    const double maxZoom = 18.0; // Maximum zoom level

    double zoomLevel =
        maxZoom - ((distance / maxDistance) * (maxZoom - minZoom)).clamp(0.0, maxZoom - minZoom);

    return zoomLevel;
  }

  bool commentBoxShown = false;

  // The following code performs markers distance checking
  Future<void> _checkNearbyMarkers() async {
    Timer.periodic(Duration(seconds: 10), (timer) async {
      if(!commentBoxShown){
        LocationData userLocation = await LocationService.getLocation();
        if (autoFindNearestEnabled) {
          _findNearestUnexploredEntry();
        }

        for (EntryMarker marker in entryMarkers) {
          double distance = calculateDistance(
            userLocation.latitude!,
            userLocation.longitude!,
            double.parse(marker.latitude),
            double.parse(marker.longitude),
          );

          marker.distanceToUser = distance; // Update the distance for each marker

          if (distance <= 50 && distance != 0.00) {
            if (showButtonNow) {
              // Trigger vibration
              if(vibrationOn){
                Vibration.vibrate(duration: 500);
              }

              // Trigger sound
              // AudioPlayer audioPlayer = AudioPlayer();
              // await audioPlayer.play(Uri.parse('notification_sound.mp3').toString());

              try {
                setState(() {
                  isNearby = true;
                });
              }catch(e){
                isNearby = false;
                showButtonNow = false;
              }
            }else{
              try {
                setState(() {
                  isNearby = false;
                  showButtonNow = false;
                });
              }catch(e){
                isNearby = false;
                showButtonNow = false;
              }
            }
            return;
          }else{
            setState(() {
              showButtonNow = false;
            });
          }
        }

        setState(() {
          isNearby = false;
        });
      }

    });
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371; // Earth's radius in kilometers
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = radius * c;

    return distance * 1000; // Convert to meters
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  List<String> parseFriendNames() {
    // Split the input string by commas
    List<String> names = ("$loggedInUsername,$friendsUserNameList").split(',');

    // Trim each name to remove leading and trailing spaces
    for (int i = 0; i < names.length; i++) {
      names[i] = names[i].trim();
    }

    return names;
  }

  Future<void> getVibrationMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tempString = prefs.getString('vibration');
    if (tempString != null && tempString != "") {
      vibrationOn = true;
    }else{
      vibrationOn = false;
    }
  }

  Future<void> getAutoFinderMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tempString = prefs.getString('autoFinder');
    if (tempString != null && tempString != "") {
      autoFindNearestEnabled = true;
    }else{
      autoFindNearestEnabled = false;
    }
  }

  // Logged-in user names fetching
  Future<void> _fetchLoggedInUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');

    setState(() {
      loggedInUsername = username ?? '';
    });
  }

  // Friends user names fetching
  Future<void> _fetchFriendsUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usernames = prefs.getString('friendsList');

    setState(() {
      friendsUserNameList = usernames ?? '';
    });
  }

  void _initMap() async {
    try {
      locationPermissionGranted = await LocationService.requestLocationPermission();
      getVibrationMode();
      getAutoFinderMode();

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
        setState(() {
          _checkNearbyMarkers();
          if (autoFindNearestEnabled) {
            _findNearestUnexploredEntry();
          }
        });
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
    if(mapController == null){
      _initMap();
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        alignment: Alignment.center,
        // padding: EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!locationPermissionGranted)
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
                    "To use this app, please grant location permission.\n The map might be loading, please wait a moment.",
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
                      setMapTheme(mapController!, currentBrightness == Brightness.dark);
                      updateMapCamera(); // Center the map initially
                      getLoggedInUsername();
                      _fetchLoggedInUsername();
                      _fetchFriendsUsername();
                      _checkNearbyMarkers();
                      _findNearestUnexploredEntry(); // Move it here
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
                            _checkNearbyMarkers();
                            // setState(() {});
                          });
                        },
                      );
                    })),
                    onTap: (_) {
                      // Clear tapped markers when the map is tapped
                      setState(() {
                        tappedMarkerIds.clear();
                        tappedMarkerInfos.clear();
                        _checkNearbyMarkers();
                      });
                    },
                  ),
                ),
              ),
            if(Platform.isIOS)
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:[
                    ElevatedButton(
                      onPressed: () {
                        if(mapZoomLevel >= 17){
                          mapZoomLevel = 17;
                        }else{
                          mapZoomLevel += 1;
                        }
                        mapController?.animateCamera(
                          CameraUpdate.zoomTo(mapZoomLevel),
                        );
                        setState(() {});
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in),
                          SizedBox(width: 8),
                          Text('Zoom In'),
                        ],
                      ),
                    ),
                    // Switch widget to toggle automatic calls
                    // SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () {
                        if(mapZoomLevel <= 1){
                          mapZoomLevel = 1;
                        }else{
                          mapZoomLevel -= 1;
                        }
                        mapController?.animateCamera(
                          CameraUpdate.zoomTo(mapZoomLevel),
                        );
                        setState(() {});
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_out),
                          SizedBox(width: 8),
                          Text('Zoom Out'),
                        ],
                      ),
                    ),

                  ]
              ),
            SizedBox(height: 5.0),
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

              // The following shows the details in the card, below the map
              NavigationHelper.buildEntryDetailsCard(tappedMarkerIds, entryMarkers),
              if (showButtonNow && username!='' && nowDistance <= 50.0 && nowDistance != 0.0 && isNearby)
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      showButtonNow = false;
                    });
                    // Generate a random comment including current time, date, and a surprising string
                    String randomString = _generateRandomString();
                    String currentTime = _getCurrentTime();
                    String currentDate = _getCurrentDate();
                    String randomComment = 'Time: $currentTime\nDate: $currentDate\nSurprising String: $randomString';

                    // Perform the HTTPS POST request
                    var response;
                    try {
                      if(friendMode){
                        var friendNames = parseFriendNames();
                        for(int i=0; i<friendNames.length; i++){
                          // Send the exploration for every friend engaged
                          // if(friendNames[i] != ""){
                            response = await http.post(
                              Uri.parse('https://weicheng.app/flutter/addExplore.php'),
                              body: {
                                'user_identifier': friendNames[i],
                                'entry_id': nearestUnexploredEntry!.entryId,
                                'time': _getCurrentTime(),
                                'date': _getCurrentDate(),
                                'comment': randomComment + "\n This exploration was registered by ${friendNames[0]}, together with friends ${friendsUserNameList}, enjoy your day!",
                              },
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Explore data posted: ${response.body}'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        // }
                      }else{
                        // Fetch user_id from the user.php API response
                        response = await http.post(
                          Uri.parse('https://weicheng.app/flutter/addExplore.php'),
                          body: {
                            'user_identifier': username,
                            'entry_id': nearestUnexploredEntry!.entryId,
                            'time': _getCurrentTime(),
                            'date': _getCurrentDate(),
                            'comment': randomComment,
                          },
                        );
                      }

                      if (response.statusCode == 200) {
                        Vibration.vibrate(duration: 5000);
                        print('Explore data posted successfully');
                        // Display the user response in the app
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Explore data posted successfully: ${response.body}'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } else {
                        print('Failed to post explore data: ${response.statusCode}');
                        // Display the error response in the app
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to post explore data: ${response.body}'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      Vibration.vibrate(duration: 500);
                      print('Error posting explore data: $e');
                      // Display the error message in the app
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error posting explore data: $e'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }

                    // Refresh the page to refetch all data
                    _fetchEntries();
                    _findNearestUnexploredEntry();
                  },
                  child: Text('Register & Congratulations!'),
                ),

              // The button for auto find mode
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:[
                  SizedBox(height: 16.0),
                  // Switch widget to toggle automatic calls
                  Text("Auto Find Nearest Entry & Follow Mode"),
                  Switch(
                    value: autoFindNearestEnabled,
                    onChanged: (value) {
                      setState(() {
                        autoFindNearestEnabled = value;
                        if (autoFindNearestEnabled) {
                          _findNearestUnexploredEntry();
                          setVariableModes("autoFinder", "On");
                        }else{
                          setVariableModes("autoFinder", "");
                        }
                      });
                      getAutoFinderMode();
                    },
                  ),
                ]
              ),

            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:[
                  SizedBox(height: 16.0),
                  // Switch widget to toggle automatic calls
                  Text("Vibration Haptics"),
                  Switch(
                    value: vibrationOn,
                    onChanged: (value) {
                      setState(() {
                        vibrationOn = value;
                        if(vibrationOn){
                          setVariableModes("vibration", "On");
                        }else{
                          setVariableModes("vibration", "");
                        }
                      });
                      getVibrationMode();
                    },
                  ),
                ]
            ),

          ],
        ),
      ),
    );
  }

  Future<String?> _showCommentDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Enter your comment:'),
          content: TextField(
            controller: commentController,
            onChanged: (comment) {},
            decoration: InputDecoration(hintText: 'Type your comment here'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                commentBoxShown = false;
                Navigator.of(dialogContext).pop(commentController.text);
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _postExploreData(String userComment) async {
    try {
      // Fetch user_id from the user.php API response
      String? userId = await _fetchUserId();
      if (userId == null) {
        print('Failed to fetch user_id');
        return;
      }

      // Replace 'your_server_url/addExplore.php' with the actual URL of your addExplore.php script
      final response = await http.post(
        Uri.parse('https://weicheng.app/flutter/addExplore.php'),
        body: {
          'user_id': userId,
          'entry_id': nearestUnexploredEntry!.entryId,
          'time': _getCurrentTime(),
          'date': _getCurrentDate(),
          'comment': userComment,
        },
      );

      if (response.statusCode == 200) {
        print('Explore data posted successfully');
        // Display the user response in the app
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Explore data posted successfully: ${response.body}'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        print('Failed to post explore data: ${response.statusCode}');
        // Display the error response in the app
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post explore data: ${response.body}'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error posting explore data: $e');
      // Display the error message in the app
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error posting explore data: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<String?> _fetchUserId() async {
    try {
      // Fetch user.php API response
      final response = await http.post(
        Uri.parse('https://weicheng.app/flutter/user.php'),
        body: {'username': loggedInUsername},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['user_id'] as String?;
      } else {
        print('Failed to fetch user data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Map Center Updates
  void updateMapCamera() {
    mapController?.animateCamera(
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

// Random String for easter egg
String _generateRandomString() {
  const String characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#%^&*()-=_+[]{}|;:,.<>?';
  const int length = 10;

  Random random = Random();
  String randomString = '';

  for (int i = 0; i < length; i++) {
    randomString += characters[random.nextInt(characters.length)];
  }

  return randomString;
}

Future<void> _postExploreData(String userComment) async {
  try {
    // Replace 'your_server_url/addExplore.php' with the actual URL of your addExplore.php script
    final response = await http.post(
      Uri.parse('https://weicheng.app/flutter/addExplore.php'),
      body: {
        'user_id': 'your_user_id', // replace with actual user_id
        'entry_id': nearestUnexploredEntry!.entryId, // replace with actual entry_id
        'time': _getCurrentTime(),
        'date': _getCurrentDate(),
        'comment': userComment,
      },
    );

    if (response.statusCode == 200) {
      print('Explore data posted successfully');
    } else {
      print('Failed to post explore data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error posting explore data: $e');
  }
}

String _getCurrentTime() {
  DateTime now = DateTime.now();
  String formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  return formattedTime;
}

String _getCurrentDate() {
  DateTime now = DateTime.now();
  String formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return formattedDate;
}

// Check if the user has explored or owned the entry
bool hasExploredOrOwnedEntry(List<Map<String, dynamic>> userHistory, String entryId) {
  // print('User History: $userHistory');

  return userHistory.any((entry) {
    // print('Entry: $entry');

    if (entry['entry_id'] == entryId) {
      return true;
    } else {
      return false;
    }
  });
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

List<Map<String, dynamic>> userHistoryPub = [];

class EntryDetailsWidget extends StatelessWidget {
  final EntryMarker entryMarker;
  bool hasSeen = false;

  EntryDetailsWidget({required this.entryMarker});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Display latitude and longitude for all users
        Text("Latitude: ${entryMarker.latitude}"),
        Text("Longitude: ${entryMarker.longitude}"),
        Text("Distance from you: ${entryMarker.distanceToUser.toStringAsFixed(2)} meters"),

        // Fetch user history and determine if the user has explored or owned the marker
        FutureBuilder<List<Map<String, dynamic>>?>(
          future: fetchUserHistory(),
          builder: (context, snapshot) {
            // if (snapshot.connectionState == ConnectionState.waiting) {
            //   // return CircularProgressIndicator();
            // } else
            if (snapshot.hasError) {
              return Text("Error fetching user history: ${snapshot.error}");
            } else {
              final List<Map<String, dynamic>> userHistory = snapshot.data ?? [];
              userHistoryPub = userHistory;
              // print("ALl data:$userHistory");

              // Check if the user has explored or owned the marker position using userHistory
              hasSeen = hasExploredOrOwnedEntry(userHistory, entryMarker.entryId);

              // print("hasSeen: $hasSeen");

              // Conditionally display additional information based on user's history
              if (hasSeen) {
                showButtonNow = false;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                showButtonNow = true;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if(username=='')
                      Text("Login to register your footprints."),
                    Text("You haven't explored this memory yet.\n Walk nearby (<=50m) and click here to unlock."),
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

}

// Get users history by using the following structure
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