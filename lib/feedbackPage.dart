import 'package:flutter/material.dart';
import 'dart:convert'; // Add this import for json decoding
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

class FeedbackPage extends StatefulWidget {
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.feedback_rounded),
            SizedBox(width: 8),
            Text('Feedbacker'),
          ],
        ),
        backgroundColor: Platform.isIOS
            ? null
            : Theme.of(context).colorScheme.secondaryContainer,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/story_trail.png',
                    height: 100,
                    width: 100,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Story Trail",
                    style: TextStyle(
                      fontFamily: 'caveat',
                      fontWeight: FontWeight.w400,
                      fontSize: 40,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _feedbackController,
                    maxLines: 10,
                    focusNode: FocusNode(),
                    decoration: InputDecoration(
                      hintText: 'Type your feedback here...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your feedback';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your feedback will be anonymous. Only the app build version, device type, and phone model will be uploaded to the server.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _submitFeedback();
                      }
                    },
                    child: Text('Submit'),
                  ),
                  Text('Build Version: 240114'),
                  FutureBuilder(
                    future: _getDeviceDetails(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error fetching device info');
                      } else {
                        return Text('${snapshot.data}');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _getDeviceDetails() async {
    String deviceType = await _getDeviceType();
    String deviceModel = await _getDeviceModel();

    return '$deviceType, Model: $deviceModel';
  }

  Future<String> _getDeviceType() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return 'Android ${androidInfo.version.sdkInt}';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return 'iOS ${iosInfo.systemVersion}';
    }
    return 'Unknown';
  }

  Future<String> _getDeviceModel() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model + "\nCode Name: " + androidInfo.product ?? 'Unknown';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.utsname.machine;
    }
    return 'Unknown';
  }

  Future<void> _submitFeedback() async {
    String deviceDetails = await _getDeviceDetails();

    Map<String, String> data = {
      "message": _feedbackController.text,
      "build": "240114", // Replace with your actual build version
      "device_details": deviceDetails,
    };

    http.Response response = await http.post(
      Uri.parse("https://weicheng.app/flutter/feedback.php"),
      body: data,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final String feedbackId = responseData['feedback_id'].toString() ?? 'Unknown';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback submitted successfully!'),
        ),
      );

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Feedback Submitted'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Thank you for your feedback! Please note down your feedback ID if you want to track progress later on.'),
                SizedBox(height: 8),
                Text('Your feedback ID: $feedbackId'),
                SizedBox(height: 8),
                Text('Build Version: 240114'),
                Text('Device Details: $deviceDetails'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate back upon successful submission
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit feedback. Please try again later.'),
        ),
      );
    }
  }
}