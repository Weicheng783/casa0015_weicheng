import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class FeedbackPage extends StatefulWidget {
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.feedback_rounded),
            SizedBox(width: 8), // Adjust the space between the icon and text
            Text('Provide Feedback'),
          ],
        ),
        backgroundColor:
        Platform.isIOS ? null : Theme.of(context).colorScheme.secondaryContainer,
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
                    maxLines: 10,
                    focusNode: FocusNode(),
                    decoration: InputDecoration(
                      hintText: 'Type your feedback here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        // Dummy button action (simulate back gesture)
                        Navigator.of(context).pop();
                        // Display feedback submission success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Feedback submitted successfully!'),
                          ),
                        );
                      }
                    },
                    child: Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}