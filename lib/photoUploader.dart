import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:story.trail/login.dart';
import 'package:story.trail/main.dart';
import 'package:story.trail/navigation.dart';
import 'package:story.trail/submitTrail.dart';
import 'dart:io' show File, Platform;

import 'getPhoto.dart';
import 'mapHelper.dart';

class PhotoUploadPage extends StatefulWidget {
  final int entryId;

  PhotoUploadPage({super.key, required this.entryId});

  @override
  _PhotoUploadPageState createState() => _PhotoUploadPageState(currentEntryId: entryId);
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  List<File> _selectedPhotos = [];
  int? currentEntryId;
  bool isUploading = false; // Added flag to track upload status

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
    setState(() {
      isUploading = true; // Set the flag to true when starting the upload
    });

    for (int i = 0; i < _selectedPhotos.length; i++) {
      File photo = _selectedPhotos[i];

      if(Platform.isIOS){
        photo = await adjustImageRotation(photo.path);
      }

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

    setState(() {
      isUploading = false; // Set the flag to false when the upload is complete
      _selectedPhotos.clear();
    });

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
          onPressed: isUploading ? null : _selectPhotos,
          style: Platform.isIOS ? null : ButtonStyle(
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
        if(Platform.isAndroid)
          ElevatedButton(
            onPressed: isUploading ? null : () => _openCameraApp(context),
            child: Text("Open Camera & Return"),
          ),
        SizedBox(height: 20),
        if (_selectedPhotos.isNotEmpty)
          ElevatedButton(
            onPressed: isUploading ? null : () => _submitPhotos(),
            style: Platform.isIOS ? null : ButtonStyle(
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
        if (isUploading)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Please wait...'),
            ],
          ),
      ],
    );
  }
}

void _openCameraApp(BuildContext context) async {
  final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);

  if (image != null) {
    // Save the captured image to the gallery
    await _saveImageToGallery(image.path);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Image saved to gallery."),
        duration: Duration(seconds: 2),
      ),
    );
    // Navigate back to the previous page
    // Navigator.pop(context);
  }
}

Future<void> _saveImageToGallery(String imagePath) async {
  final result = await ImageGallerySaver.saveFile(imagePath);

  if (result != null && result.isNotEmpty) {
    print("Image saved to gallery");
  } else {
    print("Failed to save image to gallery");
  }
}