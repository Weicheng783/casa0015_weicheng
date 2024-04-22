import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:torch_controller/torch_controller.dart';
import 'package:volume_controller/volume_controller.dart';

import 'main.dart';
import 'dart:io' show Platform;

// This is the data fetcher for all variables which need to contain
// and restore or initialise its data.
class DataFetcher extends StatefulWidget {
  @override
  _DataFetcherState createState() => _DataFetcherState();
}

class _DataFetcherState extends State<DataFetcher> {
  int intervalSeconds = 10; // Default interval
  String receiverName = loggedInUsername; // Default receiver name
  int counter = 0;
  final TorchController _torchController = TorchController();
  final player = AudioPlayer();

  List<int> notifiedEntryIds = []; // List to store notified entry IDs

  double _volumeListenerValue = 0;
  double _getVolume = 0;
  double _setVolumeValue = 0;

  @override
  void initState() {
    _torchController.initialize();
    super.initState();
    fetchEntriesPeriodically();
    fetchEntriesWithoutReceiver();
    emergencyLightService();

    // Listen to system volume change
    VolumeController().listener((volume) {
      setState(() => _volumeListenerValue = volume);
    });

    VolumeController().getVolume().then((volume) => _setVolumeValue = volume);
  }

  @override
  void dispose() {
    VolumeController().removeListener();
    super.dispose();
  }

  Future<void> emergencyLightService() async {
    Timer.periodic(Duration(seconds: 5), (timer) async {
      // User Experiencing Emergency
      if (emergencyId != "") {
        // Define the duration for long and short flashes (in milliseconds)
        const longFlashDuration = Duration(milliseconds: 300);
        const shortFlashDuration = Duration(milliseconds: 100);

        // S.O.S pattern: ...---...
        final sosPattern = [shortFlashDuration, shortFlashDuration, shortFlashDuration, longFlashDuration, longFlashDuration, longFlashDuration, shortFlashDuration, shortFlashDuration, shortFlashDuration];

        // Toggle the flashlight in the S.O.S pattern
        for (var duration in sosPattern) {
          // Turn on the flashlight
          _torchController.toggle();

          // Wait for the specified duration
          await Future.delayed(duration);

          // Turn off the flashlight
          _torchController.toggle();
        }

        var tempVol = await VolumeController().getVolume();
        _setVolumeValue = 0.7;
        VolumeController().setVolume(_setVolumeValue);
        setState(() {});
        await player.setVolume(1);
        await player.play(AssetSource('sos.wav'));
        VolumeController().setVolume(tempVol);
        setState(() {});
      }
    });
  }

  // Periodically fetch private messages per 6 seconds.
  Future<void> fetchEntriesPeriodically() async {
    Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      if (friendMode) {
        if (!dataSaver || (dataSaver && counter == 6)) {
          try {
            var request = http.MultipartRequest(
                'POST', Uri.parse('https://weicheng.app/flutter/device.php'));
            request.fields['mode'] = 'find';
            request.fields['status'] = 'sent';
            request.fields['receiver'] = loggedInUsername;

            var response = await request.send();
            var responseBody = await response.stream.bytesToString();

            if (response.statusCode == 200) {
              // Successful response
              var jsonResponse = json.decode(responseBody);
              // print("Response: $jsonResponse");
              // print("USERNAME: $loggedInUsername");
              // Access the first element in the list
              if (jsonResponse.isNotEmpty) {
                for (var messageInfo in jsonResponse) {
                  // Check if entry ID is already notified
                  try{
                    if (!notifiedEntryIds.contains(int.parse(messageInfo['id']))) {
                      // Access the first element in the list
                      // Check if "id" appears in the response
                      // Check if message is "torch"
                      if (messageInfo['message'] == 'torch') {
                        // Turn on the torch
                        _torchController.toggle();
                      } else if (messageInfo['message'] != null &&
                          messageInfo['message'].contains('ring') && messageInfo['sender'] != loggedInUsername) {
                        var tempVol = await VolumeController().getVolume();
                        _setVolumeValue = 0.7;
                        VolumeController().setVolume(_setVolumeValue);
                        setState(() {});
                        await player.setVolume(1);
                        await player.play(UrlSource(
                            'https://weicheng.app/flutter/notification.wav'));
                        if(emergencyId != ""){
                          VolumeController().setVolume(tempVol);
                        }
                        setState(() {});
                        handleEmergencyEvent(messageInfo['message'], messageInfo['sender'], messageInfo);
                      } else if (messageInfo['message'] != null &&
                          messageInfo['message'].contains('lock')){
                        if(Platform.isAndroid){
                          updateStatus(int.parse(messageInfo['id']));
                          responseFromNativeCode();
                        }
                      }
                      if (messageInfo['id'] != null && messageInfo['sender'] != loggedInUsername) {
                        // Show dialog with message, sender, and time
                        await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: messageInfo['message'].contains('lat:')
                                  ? Text('!!!Emergency Event!!!')
                                  : Text('Message Details'),
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (messageInfo['message'].contains('lat:') &&
                                      messageInfo['message'].contains('long:'))
                                    ...handleEmergencyEvent(
                                        messageInfo['message'], messageInfo['sender'], messageInfo),
                                  if(!(messageInfo['message'].contains('lat:') &&
                                      messageInfo['message'].contains('long:')))
                                    Text('Message: ${messageInfo['message']}'),
                                  Text('Sender: ${messageInfo['sender']}'),
                                  Text('Time: ${messageInfo['time']}'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    // Convert 'id' from String to int before passing to updateStatus
                                    // Other Users Cannot Dismiss Emergency Message, Only to add them to the fetched list temporally
                                    if (messageInfo['message'].contains('lat:') &&
                                        messageInfo['message'].contains(
                                            'long:')) {
                                    } else {
                                      updateStatus(int.parse(messageInfo['id']));
                                    }

                                    notifiedEntryIds.add(
                                        int.parse(messageInfo['id']));
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    }
                  }catch(e){
                    print("Response is empty");
                  }
                }
              } else {
                print("Response is empty or invalid");
              }

            } else {
              // Error in response
              print("Request failed with status: ${response.statusCode}");
            }
          } catch (e) {
            // Error in request
            // print("Error: $e");
          }
          if (dataSaver && counter == 6) {
            counter = 0;
          }
        } else {
          counter += 1;
        }
      }
    });
  }

  List<Widget> handleEmergencyEvent(String message, String sender, dynamic response) {
    List<String> parts = message.split(',');
    List<Widget> details = [];
    String latitude = "0.0";
    String longitude = "0.0";

    details.add(Text('Emergency Event Triggered, Please Give Your Hand Wherever Possible.'));
    for (var part in parts) {
      String trimmedPart = part.trim();
      if (trimmedPart.startsWith('lat:')) {
        latitude = trimmedPart.substring(4); // Remove "lat:"
        details.add(Text('Latitude: $latitude'));
      } else if (trimmedPart.startsWith('long:')) {
        longitude = trimmedPart.substring(5); // Remove "long:"
        details.add(Text('Longitude: $longitude'));
      }
    }
    emergencyPlaces.add(Marker(
      onTap: () {
        setState(() {
          endLat = latitude;
          endLong = longitude;
          emergencyLat = latitude;
          emergencyLong = longitude;
          emergencyTappedMarker = response;
        });
      },
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
      markerId: MarkerId(sender),
      position: LatLng(double.parse(latitude), double.parse(longitude)),
      infoWindow: InfoWindow(
        title: 'Emergency Call (SOS)',
        snippet: '${sender} has initiated an Emergency Service, please check out if possible.\nAt Time: ${response['time']}.\nLatitude: ${response['lat']}.\nLongitude: ${response['long']}.\nMessage ID: ${response['id']}.',
        onTap: () {
          setState(() {
            endLat = latitude;
            endLong = longitude;
            emergencyLat = latitude;
            emergencyLong = longitude;
            emergencyTappedMarker = response;
          });
        },
      ),
    ));
    emergencyPeople.add(sender);
    details.add(Text('Emergency Coordinate Has Been Marked In Your Map.'));
    return details;
  }

  Future<void> fetchEntriesWithoutReceiver() async {
    var count = 0;
    Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      // Function to make request without including receiver
      if (!dataSaver || (dataSaver && count == 6)) {
        try {
          var request = http.MultipartRequest(
              'POST', Uri.parse('https://weicheng.app/flutter/device.php'));
          request.fields['mode'] = 'find';
          request.fields['status'] = 'sent';

          var response = await request.send();
          var responseBody = await response.stream.bytesToString();

          if (response.statusCode == 200) {
            // Successful response
            var jsonResponse = json.decode(responseBody);
            // print("Response (without receiver): $jsonResponse");
            // Handle response as needed
            if (jsonResponse.isNotEmpty) {
              // Access the first element in the list
              for (var messageInfo in jsonResponse) {
                // Check if entry ID is already notified
                if (!notifiedEntryIds.contains(int.parse(messageInfo['id']))) {
                  // Entry is not notified, process it
                  // Check if "id" appears in the response
                  // Check if message is "torch"
                  if(messageInfo['message'] != null &&
                      messageInfo['message'].contains('ring') &&
                      messageInfo['message'].contains('lat') &&
                      messageInfo['message'].contains('long') &&
                      messageInfo['sender'] != loggedInUsername) {
                    var tempVol = await VolumeController().getVolume();
                    _setVolumeValue = 0.7;
                    if(emergencyId != ""){
                      VolumeController().setVolume(_setVolumeValue);
                    }
                    setState(() {});
                    await player.setVolume(1);
                    await player.play(UrlSource('https://weicheng.app/flutter/notification.wav'));
                    if(emergencyId != ""){
                      VolumeController().setVolume(tempVol);
                    }
                    setState(() {});
                    handleEmergencyEvent(messageInfo['message'], messageInfo['sender'], messageInfo);

                    // TODO: Area Notification (Currently Will Notify All Online Users)
                    // Show dialog with message, sender, and time
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: messageInfo['message'].contains('lat:')? Text('!!!Area Emergency Event!!!'): Text('Message Details'),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (messageInfo['message'].contains('lat:') && messageInfo['message'].contains('long:'))
                                ...handleEmergencyEvent(messageInfo['message'], messageInfo['sender'], messageInfo),
                              if(!(messageInfo['message'].contains('lat:') && messageInfo['message'].contains('long:')))
                                Text('Message: ${messageInfo['message']}'),
                              Text('Sender: ${messageInfo['sender']}'),
                              Text('Time: ${messageInfo['time']}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                // Convert 'id' from String to int before passing to updateStatus
                                // updateStatus(int.parse(messageInfo['id']));
                                notifiedEntryIds.add(int.parse(messageInfo['id']));
                                Navigator.of(context).pop();
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }else if (messageInfo['message'] != null &&
                      messageInfo['message'].contains('lock')){
                    if(Platform.isAndroid){
                      updateStatus(int.parse(messageInfo['id']));
                      responseFromNativeCode();
                    }
                  }
                  // Add entry ID to notified list
                  notifiedEntryIds.add(int.parse(messageInfo['id']));
                  // Stop processing further entries
                  // break;
                }
              }

            } else {
              print("Response is empty or invalid");
            }
          } else {
            // Error in response
            print("Request failed with status: ${response.statusCode}");
          }
        } catch (e) {
          // Error in request
          // print("Error: $e");
        }
        if (dataSaver && count == 6) {
          count = 0;
        }
      }else{
        count = 0;
      }
    });
  }

  Future<void> updateStatus(int messageId) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('https://weicheng.app/flutter/device.php'));
      request.fields['mode'] = 'update';
      request.fields['id'] = messageId.toString();
      request.fields['status'] = 'received';

      var response = await request.send();
      if (response.statusCode == 200) {
        // Successful response
        print('Status updated to "received" for message ID: $messageId');
      } else {
        // Error in response
        print("Request failed with status: ${response.statusCode}");
      }
    } catch (e) {
      // Error in request
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // This widget doesn't render anything
  }
}