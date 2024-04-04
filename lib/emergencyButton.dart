import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:story.trail/main.dart';

class EmergencyAlertButton extends StatefulWidget {
  @override
  _EmergencyAlertButtonState createState() => _EmergencyAlertButtonState();
}

class _EmergencyAlertButtonState extends State<EmergencyAlertButton> {
  @override
  void initState() {
    super.initState();
    getEmergencyId();
  }

  void sendAlert() async {
    if (emergencyId.isNotEmpty) {
      // If variable A is not empty, update existing alert
      final response = await http.post(
        Uri.parse('https://weicheng.app/flutter/device.php'),
        body: {
          'mode': 'update',
          'id': emergencyId,
          'status': 'cleared',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          emergencyId = "";
          setVariableModes("emergencyId", "");
          getEmergencyId();
        });
        // print('Alert Cleared');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Alert Cleared, Emergency Service Stopped."),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // print('Error clearing alert');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Alert Not Cleared, Please Try Again."),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // If variable A is empty, insert new alert
      final response = await http.post(
        Uri.parse('https://weicheng.app/flutter/device.php'),
        body: {
          'mode': 'insert',
          'sender': loggedInUsername,
          'message': 'ring,lat:'+startLat+',long:'+startLong,
          'receiver': 'EMERGENCY_SERVICE',
          'status': 'sent',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['id'] != null) {
          setState(() {
            emergencyId = data['id'].toString();
            setVariableModes("emergencyId", emergencyId);
            getEmergencyId();
          });
          // print('Alert Sent');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Alert Sent To Public, Emergency Service Started."),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // print('Error: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Emergency Not Started Due To: ${response.body}, Please Try Again Immediately."),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Emergency Not Started Due To Server Error, The Responded Code Was Not 200 OK. Please Try Again Immediately."),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: Platform.isIOS? null :
          emergencyId != "" ?
      ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
          Theme.of(context).colorScheme.errorContainer,
        ),
      ) : null,
      onLongPress: sendAlert,
      onPressed: emergencyId != "" ? null : () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("To start/clear emergency service, long press it."),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(emergencyId != "" ? Icons.emergency_share_rounded : Icons.emergency_share_outlined), // Change the icon based on the state
          SizedBox(width: 8),
          Text(emergencyId != "" ? 'Emergency ON' : 'Emergency OFF'), // Change the text based on the state
        ],
      ),
    );
  }

}

// void main() {
//   runApp(MaterialApp(
//     home: Scaffold(
//       appBar: AppBar(
//         title: Text('Emergency Alert Button'),
//       ),
//       body: Center(
//         child: EmergencyAlertButton(),
//       ),
//     ),
//   ));
// }