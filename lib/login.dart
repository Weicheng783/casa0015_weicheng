import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode usernameFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  Future<void> loginUser(BuildContext context) async {
    final String loginUrl = 'https://weicheng.app/flutter/login.php';

    final Map<String, String> body = {
      'username': usernameController.text,
      'userpassword': passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              duration: Duration(seconds: 2),
            ),
          );

          ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
          ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;

          controller = scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(data['message']),
              duration: Duration(seconds: 2),
            ),
          );
          controller.closed.then((reason) {
            if (reason == SnackBarClosedReason.timeout) {
              // SnackBar closed due to timeout
              // Implement your logic here
              // For example, save username to SharedPreferences
              saveUsername(usernameController.text);
              Navigator.pop(context, usernameController.text);
            } else if (reason == SnackBarClosedReason.dismiss) {
              // SnackBar closed due to user's action
              // Implement your logic here
              // For example, clear password if it's incorrect
              _forgiveFocusToFields();
              passwordController.clear();
            }
          });

          saveUsername(usernameController.text); // Save username to SharedPreferences
          Navigator.pop(context, usernameController.text);
        } else {
          _forgiveFocusToFields();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void saveUsername(String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', username);
    print("username"+username);
  }

  void _giveFocusToFields() {
    Future.delayed(Duration.zero, () {
      usernameFocus.requestFocus();
      passwordFocus.requestFocus();
    });
  }

  void _forgiveFocusToFields() {
    Future.delayed(Duration.zero, () {
      usernameFocus.unfocus();
      passwordFocus.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: usernameController,
                focusNode: usernameFocus,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                focusNode: passwordFocus,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _giveFocusToFields();
                  loginUser(context);
                  // testSharedPreferences();
                },
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> testSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Write to SharedPreferences
  prefs.setString('testKey', 'testValue');

  // Read from SharedPreferences
  String? storedValue = prefs.getString('testKey');
  print('Stored value: $storedValue');
}
