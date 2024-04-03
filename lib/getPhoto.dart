import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:story.trail/submitTrail.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show File, Platform;

import 'main.dart';

// Photo details class
class Photo {
  // Properties of a photo
  final String username;
  final String session_id;
  final String pictureAddress;
  final String datetime;
  int rotation;

  Photo({
    required this.username,
    required this.session_id,
    required this.pictureAddress,
    required this.datetime,
    this.rotation = 0,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      username: json['username'],
      session_id: json['session_id'],
      pictureAddress: json['picture_address'],
      datetime: json['datetime'],
    );
  }
}

class ImageLoader extends StatefulWidget {
  final String imageUrl;

  const ImageLoader({Key? key, required this.imageUrl}) : super(key: key);

  @override
  _ImageLoaderState createState() => _ImageLoaderState();
}

Future<String?> _localImagePath(imageUrl) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = directory.path;
  return '$path/${imageUrl.split('/').last}';
}

class _ImageLoaderState extends State<ImageLoader> {
  bool _loaded = false;

  Future<String?> _localImagePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    return '$path/${widget.imageUrl.split('/').last}';
  }

  Future<void> _downloadImage() async {
    final response = await http.get(Uri.parse(widget.imageUrl));
    final imagePath = await _localImagePath();
    final file = File(imagePath!);
    await file.writeAsBytes(response.bodyBytes);
  }

  @override
  void initState() {
    super.initState();
    _localImagePath().then((imagePath) {
      setState(() {
        _loaded = File(imagePath!).existsSync();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if(useLocalPhoto || (!useLocalPhoto && !_loaded))
          ElevatedButton(
            onPressed: () async {
              await _downloadImage();
              setState(() {
                _loaded = true;
              });
            },
            child: Row(children: [Icon(Icons.file_download_outlined), SizedBox(width: 5,), Text('Load Image'),]),
          ),
        if(useLocalPhoto)
          ElevatedButton(
            onPressed: () {
              setState(() {
                _loaded = false;
              });
            },
            child: Row(children: [Icon(Icons.clear_all_rounded), SizedBox(width: 5,), Text('Clear Download'),]),
          ),
        if (_loaded)
          if(useLocalPhoto)
            FutureBuilder<String?>(
              future: _localImagePath(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.file(File(snapshot.data!), width: 200, height: 200,);
                } else {
                  return Text('Error loading image');
                }
              },
            ),
        if(_loaded)
          if(!useLocalPhoto)
            CachedNetworkImage(
              width: 200,
              height: 200,
              imageUrl: widget.imageUrl,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
              filterQuality: FilterQuality.medium,
              fit: BoxFit.cover,
            ),
      ],
    );
  }
}

// Stateful widget to get and display photos
class GetPhoto extends StatefulWidget {
  final int entryId;
  // Constructor with required parameter
  GetPhoto({required this.entryId});

  @override
  _GetPhotoState createState() => _GetPhotoState();
}

bool useLocalPhoto = true;

// State class for GetPhoto widget
class _GetPhotoState extends State<GetPhoto> {
  // State variables and initialization
  var _photoList = <Photo>[];
  bool isUploading = false;
  List<File> _selectedPhoto = [];
  bool loadPhotosOverCellular = false;

  @override
  void initState() {
    // Initialize state when the widget is created
    super.initState();
    _loadUserPreferences();
    _loadLocalPhotoPreferences();
    _checkConnection();
  }

  // Method to fetch photo data from the server
  Future<void> fetchData() async {
    // Fetch data using HTTP request
    try {
      final response = await http.get(
        Uri.parse('https://weicheng.app/flutter/getPhoto.php')
            .replace(queryParameters: {'entry_id': '${widget.entryId}'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedList = json.decode(response.body) ?? [];
        if (decodedList.length == 0) {
          _photoList = [];
        } else {
          _photoList = decodedList.map((photo) => Photo.fromJson(photo)).toList();
        }
        setState(() {});
      } else {
        print('Failed to fetch data');
        throw Exception('Failed to fetch data');
      }
    } catch (error) {
      print('Error: $error');
      // Handle error gracefully
    }
  }

  Future<void> _selectPhoto(String photo1) async {
    setState(() {
      imgCmpMsg = "Waiting User Submit Challenge...";
    });
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${pickedFiles.length} photos selected. But only the first one will be used for comparison."),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _selectedPhoto.addAll(pickedFiles.map((file) => File(file.path)));
      });
      _submitPhotoForCmp(photo1);
    }else{
      setState(() {
        showImgCmpResult = false;
        imgCmpResult = "";
      });
    }
  }

  Future<void> _submitPhotoForCmp(String image1) async {
    setState(() {
      isUploading = true; // Set the flag to true when starting the upload
      imgCmpMsg = "Waiting Photo Upload...";
    });

    for (int i = 0; i < 1; i++) {
      File photo = _selectedPhoto[i];

      if(Platform.isIOS){
        photo = await adjustImageRotation(photo.path);
      }

      // Create a request to addPhoto.php
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://weicheng.app/flutter/addPhotoCmp.php"),
      );

      // Add photo as a file
      request.files.add(await http.MultipartFile.fromPath(
        "photos[]",
        photo.path,
        filename: "photo_$i.jpg", // Set the filename as needed
      ));

      var response;
      try {
        response = await request.send();
        setState(() {});
      } catch (e) {
        print("Error sending request: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error sending request: $e"),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Check the response continuously
      if (response == null) {
        int maxAttempts = 10; // Maximum number of attempts to check for response
        int currentAttempt = 0;
        while (response == null && currentAttempt < maxAttempts) {
          await Future.delayed(Duration(seconds: 1)); // Delay between attempts
          currentAttempt++;
        }

        // Check if response is still null after attempts
        if (response == null) {
          print("No response received within the timeout period.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No response received within the timeout period."),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // If response is received, continue with status code check
      if (response != null) {
        if (response.statusCode == 200) {
          print("Photo $i uploaded successfully!");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Photo uploaded successfully! Now waiting for their comparison result..."),
              duration: Duration(seconds: 2),
            ),
          );

          // Parse the response body
          var responseBody = await response.stream.bytesToString();
          Map<String, dynamic> jsonResponse = json.decode(responseBody);

          // Check if the response contains the file address
          if (jsonResponse.containsKey("file_address")) {
            String fileAddress = jsonResponse["file_address"];
            print("File address: $fileAddress");
            _imageComparison(image1, fileAddress);

            // Now you can use the file address as needed
          } else {
            print("Response does not contain a file address. Failed, please try it again.");
          }
        } else {
          print("Failed to upload photo $i. Error ${response.statusCode}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to upload photo $i. Error ${response.statusCode}"),
              duration: Duration(seconds: 2),
            ),
          );
          setState(() {
            showImgCmpResult = false;
            imgCmpResult = "";
          });
        }
      }

    }

    setState(() {
      isUploading = false; // Set the flag to false when the upload is complete
      _selectedPhoto.clear();
    });

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text("Photo upload completed, waiting for the comparison result..."),
    //     duration: Duration(seconds: 2),
    //   ),
    // );
  }

  // Method to load user preferences from SharedPreferences
  Future<void> _loadUserPreferences() async {
    // Load user preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      loadPhotosOverCellular = prefs.getBool('loadPhotosOverCellular') ?? false;
    });
  }
  Future<void> _loadLocalPhotoPreferences() async {
    // Load user preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      useLocalPhoto = prefs.getBool('useLocalPhoto') ?? false;
    });
  }

  // Method to save user preferences to SharedPreferences
  Future<void> _saveUserPreferences(bool value) async {
    // Save user preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('loadPhotosOverCellular', value);
  }

  // Method to save user preferences to SharedPreferences
  Future<void> _saveLocalPhotoPreferences(bool value) async {
    // Save user preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('useLocalPhoto', value);
  }

  // Method to check internet connection and load photos accordingly
  Future<void> _checkConnection() async {
    // Check connectivity and load photos based on conditions
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile && !loadPhotosOverCellular) {
      // Do not load photos over cellular
      _photoList = [];
      setState(() {});
    } else {
      // Load photos based on user preference or Wi-Fi connection
      fetchData();
    }
  }

  // Method to build user widgets based on photo data
  List<Widget> _buildUserWidgets() {
    // Build widgets for each user
    List<Widget> userWidgets = [];

    // Group photos by username and session_id
    Map<String, Map<String, List<Photo>>> groupedPhotos = {};

    for (var photo in _photoList.reversed) {
      if (!groupedPhotos.containsKey(photo.username)) {
        groupedPhotos[photo.username] = {};
      }

      if (!groupedPhotos[photo.username]!.containsKey(photo.session_id)) {
        groupedPhotos[photo.username]![photo.session_id] = [];
      }

      groupedPhotos[photo.username]![photo.session_id]!.add(photo);
    }

    // Build widgets for each user
    groupedPhotos.forEach((username, sessions) {
      sessions.forEach((session_id, photos) {
        userWidgets.add(_buildSessionWidget(username, session_id, photos));
      });
    });

    return userWidgets;
  }

  var imgCmpResult = "";
  var showImgCmpResult = false;
  var imgCmpResultFinal = false;
  var imgCmpMsg = "Starting Comparison...";
  // Method to fetch photo data from the server
  Future<String> fetchCmpResult(String path1, String path2) async {
    // Fetch data using HTTP request
    setState(() {
      imgCmpMsg = "Waiting Comparison Response...";
    });

    try {
      final response = await http.post(
        Uri.parse('https://weicheng.app/flutter/image_cmp.php'),
        body: {
          'image1_path': path1,
          'image2_path': path2,
        },
      );

      if (response.statusCode == 200) {
        // if (decodedList.length == 0) {
        //   _photoList = [];
        // } else {
        //   _photoList = decodedList.map((photo) => Photo.fromJson(photo)).toList();
        // }
        // Parse the response body
        var responseBody = response.body;
        Map<String, dynamic> jsonResponse = json.decode(responseBody);

        // Check if the response contains the file address
        if (jsonResponse.containsKey("match_count")) {
          int match_count = jsonResponse["match_count"];
          bool similarity = jsonResponse["similar"];
          print("Match Count: $match_count");
          // Now you can use the file address as needed

          setState(() {
            if(!similarity){
              imgCmpResult = "Not Matched, Please Try Again. Your Current Matched No. Features: $match_count (< 2500)";
            }else{
              imgCmpResult = "MATCHED!!! Congratulations!!! Your Matched No. Features: $match_count (>= 2500)";
            }
          });
        } else {
          print("Response does not contain a file address. Failed, please try it again.");

          setState(() {
            imgCmpResult = "Response does not contain a file address. Failed, please try it again.";
          });
        }
        return response.body;
      } else {
        setState(() {
          imgCmpResult = 'Failed to fetch data';
        });
        return('Failed to fetch data');
        // throw Exception('Failed to fetch data');
      }
    } catch (error) {
      setState(() {
        imgCmpResult = 'Error: $error';
      });
      return ('Error: $error');
      // Handle error gracefully
    }
  }

  void _imageComparison(image1, image2) {
    fetchCmpResult(image1, image2);
  }

  // Method to build a widget for a photo session
  Widget _buildSessionWidget(String username, String session_id, List<Photo> photos) {
    // Build a widget for a photo session
    return PageStorage(
      bucket: PageStorageBucket(),
      child:  Container(
        padding: EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(color: Colors.blueGrey, width: 2.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '$username - ${photos.first.datetime}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: photos.reversed.map((photo) {
                  return GestureDetector(
                    onTap: () {
                      _showFullScreenDialog(photos, photos.indexOf(photo), photo.rotation);
                    },
                    onLongPress: () {
                      _openPhotoInBrowser(photo);
                    },
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.all(8.0),
                          child: Transform.rotate(
                            angle: (photo.rotation / 180) * 3.14159265,
                            child: dataSaver?
                            Center(
                              child: ImageLoader(
                                imageUrl: 'https://weicheng.app/flutter/pics/${photo.pictureAddress}.jpg',
                              ),
                            )
                                : Image.network(
                              'https://weicheng.app/flutter/pics/${photo.pictureAddress}.jpg',
                              width: 200,
                              height: 200,
                              filterQuality: FilterQuality.medium,
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                return Center(
                                  child: Column(
                                    children: [
                                      if (loadingProgress?.cumulativeBytesLoaded != loadingProgress?.expectedTotalBytes)
                                        CircularProgressIndicator(),
                                      if (loadingProgress?.cumulativeBytesLoaded == loadingProgress?.expectedTotalBytes)
                                        child,
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if(!useLocalPhoto)
                          ElevatedButton(
                            onPressed: () {
                              _changeImageOrientation(photo);
                            },
                            child: Row(children: [
                              Icon(Icons.rotate_right_sharp),
                              SizedBox(width: 8),
                              Text('Change Orientation'),
                            ]
                            ),
                          ),
                        // Adding Image Comparison Support
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              imgCmpResultFinal = false;
                              imgCmpResult = "";
                              showImgCmpResult = true;
                              imgCmpMsg = "Starting Comparison...";
                            });
                            _selectPhoto(photo.pictureAddress);
                          },
                          child: Row(children: [
                            Icon(Icons.image_search),
                            SizedBox(width: 8),
                            Text('I Found It!'),
                          ]
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            if(showImgCmpResult)
              if(imgCmpResult != "")
                Center(
                  child: Text(
                    imgCmpResult,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
            if(imgCmpResult == "" && showImgCmpResult)
              Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 15,),
                      Text(imgCmpMsg),
                    ],)
              )
          ],
        ),
      ),
    );

  }

  // Method to change the orientation of an image
  void _changeImageOrientation(Photo photo) {
    // Change the image orientation
    setState(() {
      photo.rotation += 90;
    });
  }

  // Method to show a full-screen dialog with a photo gallery
  void _showFullScreenDialog(List<Photo> photos, int initialIndex, int initialRotation) {
    // Show a full-screen dialog with a photo gallery
    showDialog(
      useSafeArea: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            width: MediaQuery.of(context).size.width * 1.5,
            child: dataSaver?
            useLocalPhoto?
            FutureBuilder<String?>(
              future: _localImagePath(photos[initialIndex].pictureAddress+".jpg"),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.file(File(snapshot.data!), width: 200, height: 200,);
                } else {
                  return Text('Error loading image');
                }
              },
            )
            : CachedNetworkImage(
              // width: 200,
              // height: 200,
              imageUrl: 'https://weicheng.app/flutter/pics/${photos[initialIndex].pictureAddress}.jpg',
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
              filterQuality: FilterQuality.medium,
              fit: BoxFit.cover,
            ) : PhotoViewGallery.builder(
              itemCount: photos.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(
                    'https://weicheng.app/flutter/pics/${photos[photos.length - index - 1].pictureAddress}.jpg',
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.contained * 6.5,
                  heroAttributes: PhotoViewHeroAttributes(tag: photos.length - index - 1),
                  onTapUp: (context, details, controllerValue) {},
                );
              },
              scrollPhysics: BouncingScrollPhysics(),
              backgroundDecoration: BoxDecoration(
                color: Colors.transparent,
              ),
              pageController: PageController(initialPage: photos.length - initialIndex - 1),
            ),
          ),
        );
      },
    );
  }

  // Method to open a photo in the browser
  void _openPhotoInBrowser(Photo photo) async {
    // Open a photo in the browser
    final url = 'https://weicheng.app/flutter/pics/${photo.pictureAddress}.jpg';
    launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    // Build the main widget structure
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Text('\\->Long press the image will open it in browser<-/'),
          Padding(
            padding: const EdgeInsets.all(0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Allow Loading Photos Over Cellular'),
                SizedBox(width: 10,),
                Switch(
                  value: loadPhotosOverCellular,
                  onChanged: (value) {
                    setState(() {
                      loadPhotosOverCellular = value;
                    });
                    _saveUserPreferences(value);
                    _checkConnection();
                  },
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Using Local Downloaded Photos'),
              SizedBox(width: 10,),
              Switch(
                value: useLocalPhoto,
                onChanged: (value) {
                  setState(() {
                    useLocalPhoto = value;
                  });
                  _saveLocalPhotoPreferences(value);
                  // _checkConnection();
                },
              ),
            ],
          ),
          if (!loadPhotosOverCellular && _photoList.isEmpty)
            Center(
              child: Icon(Icons.no_photography, size: 80),
            ),
          _photoList.isEmpty
              ? Center(
            child: Text(
              loadPhotosOverCellular
                  ? 'No Photos Available'
                  : 'No Photos Available or they are not loaded in cellular network in order to save your data charges',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          )
              : Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: _buildUserWidgets(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}