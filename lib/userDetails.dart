import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:story.trail/login.dart';
import 'package:story.trail/main.dart';
import 'package:story.trail/navigation.dart';
import 'dart:io' show File, Platform;

import 'getPhoto.dart';
import 'mapHelper.dart';

class UserDetailsPage extends StatefulWidget {
  final String username;

  UserDetailsPage({required this.username});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

List<MapEntry> displayedEntries = [];

class _UserDetailsPageState extends State<UserDetailsPage> {
  List<MapEntry> entriesCreated = [];
  List<MapEntry> entriesExplored = [];

  PageController _pageController = PageController();
  GoogleMapController? _mapController;
  int _currentPageIndex = 0;
  bool showCreatedEntries = false;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    fetchUserDetails(widget.username);
  }

  void fetchUserDetails(String username) async {
    final response = await http.post(
      Uri.parse("https://weicheng.app/flutter/user.php"),
      body: {"username": username},
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> userData = json.decode(response.body);

      setState(() {
        entriesCreated = List<MapEntry>.from(
          userData['entries_created']?.map((entry) => MapEntry.fromMap(entry)) ?? [],
        );
        entriesExplored = List<MapEntry>.from(
          userData['entries_explored']?.map((entry) => MapEntry.fromMap(entry)) ?? [],
        );

        // Reverse the order of the lists
        entriesCreated = entriesCreated.reversed.toList();
        entriesExplored = entriesExplored.reversed.toList();

        updateDisplayedEntries();
      });

      // Fetch details for each entry
      for (var entry in entriesCreated) {
        await fetchEntryDetails(entry, username);
      }

      for (var entry in entriesExplored) {
        await fetchEntryDetails(entry, username);
      }
    } else {
      // Handle error
      print("Failed to fetch user details. Error ${response.statusCode}");
    }
  }

  Future<void> fetchEntryDetails(MapEntry entry, String username) async {
    final response = await http.post(
      Uri.parse("https://weicheng.app/flutter/getEntry.php"),
      body: {"entryid": entry.entryId},
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> entryDetails = json.decode(response.body);

      setState(() {
        entry.long = entryDetails['long'] ?? "0.0";
        entry.lat = entryDetails['lat'] ?? "0.0";
        entry.time = entryDetails['time'] ?? "";
        entry.content = entryDetails['content'] ?? "";
        entry.authorUsername = entryDetails['author_username'] ?? "";
        entry.authorUserId = entryDetails['author_user_id'] ?? "";

        // Check if it's an explored entry, update date accordingly
        if (entryDetails['explore_username'] != null && entryDetails['explore_user_id'] != null) {
          entry.date = entryDetails['explore_date'] ?? ""; // Use the explore date for explored entries
        } else {
          entry.date = entryDetails['date'] ?? ""; // Use the created date for created entries
        }

        // Fetch comment from user.php response
        if (entryDetails.containsKey('entries_explored')) {
          List<dynamic> exploredEntries = entryDetails['entries_explored'];
          for (var exploredEntry in exploredEntries) {
            if (exploredEntry['entry_id'] == entry.entryId) {
              entry.comment = exploredEntry['comment'] ?? "";
              break;
            }
          }
        }
      });
    } else {
      // Handle error
      print("Failed to fetch entry details. Error ${response.statusCode}");
    }
  }

  void updateDisplayedEntries() {
    displayedEntries = showCreatedEntries ? entriesCreated : entriesExplored;
    applyDateRangeFilter();
    moveCameraToCurrentPoint();
  }

  void applyDateRangeFilter() {
    if (startDate != null && endDate != null) {
      displayedEntries = displayedEntries.where((entry) {
        DateTime entryDate = DateTime.parse(entry.date);
        return entryDate.isAfter(startDate!) && entryDate.isBefore(endDate!.add(Duration(days: 1)));
      }).toList();
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          startDate = pickedDate;
        } else {
          endDate = pickedDate;
        }
        updateDisplayedEntries();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Brightness currentBrightness = MediaQuery.of(context).platformBrightness;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
            children: [
              Icon(Icons.my_library_books),
              SizedBox(width: 8),
              Text("My Trail Adventure"),
            ]
        ),
        backgroundColor: Platform.isIOS ? null : Theme.of(context).colorScheme.secondaryContainer,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              fetchUserDetails(widget.username);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "Hi ${widget.username}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Show Explored Entries"),
                  Switch(
                    value: showCreatedEntries,
                    onChanged: (value) {
                      setState(() {
                        showCreatedEntries = value;
                        updateDisplayedEntries();
                      });
                    },
                  ),
                  Text("Show Created Entries"),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Start Date: "),
                  Text(startDate?.toLocal().toString().split(' ')[0] ?? "Not set"),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, true),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("End Date: "),
                  Text(endDate?.toLocal().toString().split(' ')[0] ?? "Not set"),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, false),
                  ),
                ],
              ),
              if (displayedEntries.isNotEmpty)
                Container(
                  height: 300, // Set the height as needed
                  child: GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                      // Assuming setMapTheme and moveCameraToCurrentPoint methods are correctly implemented
                      // Set map theme based on brightness
                      setMapTheme(controller, currentBrightness == Brightness.dark);
                      moveCameraToCurrentPoint();
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(0.0, 0.0),
                      zoom: 15,
                    ),
                    markers: createMarkers(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text("No entries to display."),
                ),
              SizedBox(height: 20),
              if (displayedEntries.isNotEmpty)
                SizedBox(
                  height: 1000, // Set the height as needed
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: displayedEntries.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                      moveCameraToCurrentPoint();
                    },
                    itemBuilder: (context, index) {
                      if (index < 0 || index >= displayedEntries.length) {
                        // Handle index out of bounds error, return an empty widget or null
                        print("index index index:" + index.toString());
                        return Container(); // Return an empty container for now
                      } else {
                        return Card(
                          // Your card widget displaying all information for one entry
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Memory #${index + 1}",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                Divider(),
                                if (showCreatedEntries)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Date Created: ${entriesCreated[index].date}"),
                                      Text("Time Created: ${entriesCreated[index].time}"),
                                    ],
                                  ),

                                if (!showCreatedEntries)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Date Explored: ${entriesExplored[index].date}"),
                                      Text("Time Explored: ${entriesExplored[index].time}"),
                                    ],
                                  ),
                                Text("Latitude: ${displayedEntries[index].lat}"),
                                Text("Longitude: ${displayedEntries[index].long}"),
                                Text("Content: ${displayedEntries[index].content}"),
                                Text("Comment: ${displayedEntries[index].comment}"),
                                Text("Author Username: ${displayedEntries[index].authorUsername}"),
                                Text("Author User ID: ${displayedEntries[index].authorUserId}"),

                                // Display photos
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.5,
                                  width: MediaQuery.of(context).size.height * 0.6,
                                  child: Container(
                                    // color: , // Set your desired background color here
                                    child: GetPhoto(entryId: int.parse(displayedEntries[index].entryId)),
                                  ),
                                ),

                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    PhotoUploadPage(entryId: int.parse(displayedEntries[index].entryId)), // Pass entryId here
                                  ],
                                ),
                                // Expanded(
                                //   child: GetPhoto(entryId: int.parse(displayedEntries[index].entryId)),
                                // ),

                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Set<Marker> createMarkers() {
    Set<Marker> markers = Set();

    for (var entry in displayedEntries) {
      markers.add(
        Marker(
          markerId: MarkerId(entry.entryId),
          position: LatLng(double.parse(entry.lat), double.parse(entry.long)),
          infoWindow: InfoWindow(
            title: "Adventure Point",
            snippet: entry.content,
          ),
        ),
      );
    }

    return markers;
  }

  void moveCameraToCurrentPoint() {
    if (_mapController != null && displayedEntries.isNotEmpty) {
      MapEntry currentEntry = displayedEntries[_currentPageIndex];
      LatLng targetPosition = LatLng(double.parse(currentEntry.lat), double.parse(currentEntry.long));
      _mapController!.animateCamera(CameraUpdate.newLatLng(targetPosition));
    }
  }
}

class MapEntry {
  String entryId;
  String long;
  String lat;
  String time;
  String date;
  String content;
  String comment;
  String authorUsername;
  String authorUserId;
  String exploreUsername; // Added explorer username
  String exploreUserId;   // Added explorer user ID

  MapEntry.fromMap(Map<String, dynamic> map)
      : entryId = map['entry_id'] ?? "",
        long = map['long'] ?? "0.0",
        lat = map['lat'] ?? "0.0",
        time = map['time'] ?? "",
        date = map['date'] ?? "",
        content = map['content'] ?? "",
        comment = map['comment'] ?? "",
        authorUsername = map['author_username'] ?? "",
        authorUserId = map['author_user_id'] ?? "",
        exploreUsername = map['explore_username'] ?? "", // Added explorer username
        exploreUserId = map['explore_user_id'] ?? "";   // Added explorer user ID
}



class PhotoUploadPage extends StatefulWidget {
  final int entryId;

  PhotoUploadPage({super.key, required this.entryId});

  @override
  _PhotoUploadPageState createState() => _PhotoUploadPageState(currentEntryId: entryId);
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  List<File> _selectedPhotos = [];
  int? currentEntryId;

  // Add entryId parameter to the constructor
  _PhotoUploadPageState({required this.currentEntryId});

  Future<void> _selectPhotos() async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${pickedFiles.length} photos selected."),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _selectedPhotos.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }


  Future<void> _submitPhotos() async {
    for (int i = 0; i < _selectedPhotos.length; i++) {
      File photo = _selectedPhotos[i];

      // Create a request to addPhoto.php
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://weicheng.app/flutter/addPhoto.php"),
      );

      // Add parameters
      request.fields["username"] = loggedInUsername;
      request.fields["entry_id"] = currentEntryId.toString();

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
    _selectedPhotos.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Photos upload completed."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _selectPhotos,
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(
              Theme.of(context).colorScheme.secondaryContainer,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo),
              SizedBox(width: 8,),
              Text('Select Photos'),
            ],
          ),
        ),
        SizedBox(height: 20),
        if (_selectedPhotos.isNotEmpty)
          ElevatedButton(
            onPressed: () => _submitPhotos(),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                Theme.of(context).colorScheme.secondaryContainer,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_sharp),
                SizedBox(width: 8,),
                Text('Upload Photos Now'),
              ],
            ),
          ),
      ],
    );
  }

}
