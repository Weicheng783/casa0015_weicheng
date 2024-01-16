import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class Photo {
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

class GetPhoto extends StatefulWidget {
  final int entryId;

  GetPhoto({required this.entryId});

  @override
  _GetPhotoState createState() => _GetPhotoState();
}

class _GetPhotoState extends State<GetPhoto> {
  var _photoList = <Photo>[];
  bool loadPhotosOverCellular = false;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _checkConnection();
  }

  Future<void> fetchData() async {
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

  Future<void> _loadUserPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      loadPhotosOverCellular = prefs.getBool('loadPhotosOverCellular') ?? false;
    });
  }

  Future<void> _saveUserPreferences(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('loadPhotosOverCellular', value);
  }

  Future<void> _checkConnection() async {
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

  List<Widget> _buildUserWidgets() {
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

  Widget _buildSessionWidget(String username, String session_id, List<Photo> photos) {
    return Container(
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
                          child: Image.network(
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
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _changeImageOrientation(Photo photo) {
    setState(() {
      photo.rotation += 90;
    });
  }

  void _showFullScreenDialog(List<Photo> photos, int initialIndex, int initialRotation) {
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
            child: PhotoViewGallery.builder(
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

  void _openPhotoInBrowser(Photo photo) async {
    final url = 'https://weicheng.app/flutter/pics/${photo.pictureAddress}.jpg';
    launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Text('\\->Long press the image will open it in browser<-/'),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Allow Loading Photos Over Cellular:'),
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