import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class Photo {
  final String username;
  final String session_id;
  final String pictureAddress;
  final String datetime;

  Photo({
    required this.username,
    required this.session_id,
    required this.pictureAddress,
    required this.datetime,
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

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse('https://weicheng.app/flutter/getPhoto.php')
            .replace(queryParameters: {'entry_id': '${widget.entryId}'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedList = json.decode(response.body) ?? [];
        if(decodedList.length == 0){
          _photoList = [];
        }else{
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Set your desired background color here
      body: _photoList.isEmpty
          ? Text("No Photo Available")
          : SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: _buildUserWidgets(),
        ),
      ),
    );
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
      margin: EdgeInsets.all(10.0), // Adjust the margin as needed
      padding: EdgeInsets.all(10.0), // Adjust the padding as needed
      decoration: BoxDecoration(
        color: Colors.transparent, // Set the background color to material color
        borderRadius: BorderRadius.circular(15.0), // Set the desired border radius
        border: Border.all(color: Colors.blueGrey, width: 2.0), // Add border if needed
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
              children: photos.map((photo) {
                return GestureDetector(
                  onTap: () {
                    _showFullScreenDialog(photos, photos.indexOf(photo));
                  },
                  child: Container(
                    margin: EdgeInsets.all(8.0),
                    child: Image.network(
                      'https://weicheng.app/flutter/pics/${photo.pictureAddress}.jpg',
                      width: 200, // Adjusted size for smaller images
                      height: 200, // Adjusted size for smaller images
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        return Center(
                          child: Column(
                            children: [
                              if (loadingProgress?.cumulativeBytesLoaded != loadingProgress?.expectedTotalBytes)
                                CircularProgressIndicator(),
                              if (loadingProgress?.cumulativeBytesLoaded == loadingProgress?.expectedTotalBytes) child,
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }




  void _showFullScreenDialog(List<Photo> photos, int initialIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Set background to transparent
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            child: PhotoViewGallery.builder(
              itemCount: photos.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(
                    'https://weicheng.app/flutter/pics/${photos[index].pictureAddress}.jpg',
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.contained * 2,
                  heroAttributes: PhotoViewHeroAttributes(tag: index),
                );
              },
              scrollPhysics: BouncingScrollPhysics(),
              backgroundDecoration: BoxDecoration(
                color: Colors.transparent, // Set background color to transparent
              ),
              pageController: PageController(initialPage: initialIndex),
            ),
          ),
        );
      },
    );
  }

}

// void main() {
//   runApp(MaterialApp(
//     home: GetPhoto(entryId: 1),
//   ));
// }
