import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

import 'package:story.trail/main.dart';

class MessageSender extends StatefulWidget {
  @override
  _MessageSenderState createState() => _MessageSenderState();
}

class _MessageSenderState extends State<MessageSender> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  Future<void> _postData() async {
    try {
      var url = Uri.https('weicheng.app', '/flutter/device.php');
      var response = await http.post(
        url,
        body: {
          'mode': 'insert',
          'status': 'sent',
          'receiver': _usernameController.text,
          'message': _messageController.text,
          'sender': loggedInUsername,
        },
      );

      // Show response in dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Response'),
            content: Text(response.body),
            actions: <Widget>[
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.done),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  SizedBox(width: 8),
                  Text('OK'),
                ],
              ),
            ],
          );
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred: $e'),
            actions: <Widget>[
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.error),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  SizedBox(width: 8),
                  Text('OK'),
                ],
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: Platform.isIOS? null : _usernameController,
          focusNode: FocusNode(),
          decoration: InputDecoration(labelText: 'Receiver Name'),
          onChanged: (name) {
            _usernameController.text = name;
          },
        ),
        SizedBox(height: 20),
        TextField(
          controller: Platform.isIOS? null : _messageController,
          focusNode: FocusNode(),
          decoration: InputDecoration(labelText: 'Message'),
          onChanged: (msg) {
            _messageController.text = msg;
          },
        ),
        SizedBox(height: 20),
        Container(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: _postData,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.send),
                SizedBox(width: 8),
                Text('Send'),
              ],
            ),
          ),
        ),
        SizedBox(height: 80),
      ],
    );
  }
}
