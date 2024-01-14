import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

import 'feedbackPage.dart';
import 'main.dart';

String? username = '';
String iosNameInput = '';
String iosPasswordInput = '';

Future<void> fetchPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Read from SharedPreferences
  if(prefs.getString('username') != null){
    username = prefs.getString('username');
  }else{
    username = '';
  }
}

final TextEditingController usernameController = TextEditingController();
final TextEditingController passwordController = TextEditingController();

class LoginScreen extends StatelessWidget {
  final FocusNode usernameFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  Future<bool> checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Widget buildNoInternetUI(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.signal_wifi_off,
          size: 96.0,
          color: Theme.of(context).colorScheme.error,
        ),
        SizedBox(height: 16.0),
        Text(
          "No Internet Connection",
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.0),
        Text(
          "Please check your internet connection and try again.",
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  LoginScreen({super.key});
  Future<void> logoutUser(BuildContext context) async {
    saveUsername("");
    Navigator.pop(context, "");
  }

  Future<void> loginUser(BuildContext context) async {
    final String loginUrl = 'https://weicheng.app/flutter/login.php';

    final Map<String, String> body = {
      'username': usernameController.text,
      'userpassword': passwordController.text,
    };

    // print(usernameController.text);
    // print(passwordController.text);

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

          if(Platform.isAndroid){
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(data['message']),
                    duration: Duration(seconds: 2),
                  ),
                );
                passwordController.clear();
              }
            });
          }

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
          passwordController.clear();
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

  void _giveFocusToUsername() {
    Future.delayed(Duration.zero, () {
      usernameFocus.requestFocus();
    });
  }

  void _giveFocusToPassword() {
    Future.delayed(Duration.zero, () {
      passwordFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.perm_contact_cal),
            SizedBox(width: 8), // Adjust the space between the icon and text
            Text('My Trail Membership'),
          ],
        ),
        backgroundColor: Platform.isIOS ? null : Theme.of(context).colorScheme.secondaryContainer,
      ),
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/story_trail.png',
                  height: 100,
                  width: 100,
                ),
                SizedBox(height: 16),
                if (username == null || username!.isEmpty)
                  Text(
                    "Welcome to Story Trail",
                    style: TextStyle(
                      fontFamily: 'caveat',
                      fontWeight: FontWeight.w400,
                      fontSize: 40,
                    ),
                  ),
                if (username != null && username!.isEmpty)
                  if (Platform.isAndroid)
                    TextFormField(
                      controller: usernameController,
                      focusNode: usernameFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(passwordFocus);
                        fetchPreferences();
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^[a-zA-Z][a-zA-Z0-9]*$'), // Allow letters and mixed numbers
                            replacementString: ''),
                      ],
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                      decoration: InputDecoration(labelText: 'User Name'),
                    ),
                if (username != null && username!.isEmpty)
                  if (Platform.isIOS)
                    TextFormField(
                      focusNode: usernameFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        fetchPreferences();
                      },
                      onChanged: (username) {
                        usernameController.text = username;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^[a-zA-Z][a-zA-Z0-9]*$'), // Allow letters and mixed numbers
                            replacementString: ''),
                      ],
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                      decoration: InputDecoration(labelText: 'User Name'),
                    ),
                if (username != null && username!.isEmpty)
                  if (Platform.isAndroid)
                    TextField(
                      controller: passwordController,
                      focusNode: passwordFocus,
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) {
                        _forgiveFocusToFields();
                        loginUser(context);
                        fetchPreferences();
                      },
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Password'),
                    ),
                if (username != null && username!.isEmpty)
                  if (Platform.isIOS)
                    TextField(
                      focusNode: passwordFocus,
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) {
                        _forgiveFocusToFields();
                        loginUser(context);
                        fetchPreferences();
                      },
                      onChanged: (password) {
                        passwordController.text = password;
                      },
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Password'),
                    ),
                if (username != null && username!.isEmpty)
                  SizedBox(height: 20),
                if (username != null && username!.isEmpty)
                  ElevatedButton(
                    onPressed: () {
                      _giveFocusToFields();
                      loginUser(context);
                      fetchPreferences();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.login),
                        Text('/'),
                        Icon(Icons.app_registration),
                        SizedBox(width: 8),
                        Text('Login/Register'),
                      ],
                    ),
                  ),
                if (username != null && username!.isNotEmpty)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        username!,
                        style: TextStyle(
                          fontFamily: 'mplus_rounded1c',
                          fontWeight: FontWeight.w400,
                          fontSize: 30,
                        ),
                      ),
                      Text(
                        "Welcome to Story Trail",
                        style: TextStyle(
                          fontFamily: 'caveat',
                          fontWeight: FontWeight.w400,
                          fontSize: 40,
                        ),
                      ),
                    ],
                  ),
                if (username == null)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 96.0,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        "Location Permission Required",
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        "To use this app, please grant location permission.",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                if (username != null && username!.isNotEmpty)
                  ElevatedButton(
                    onPressed: () async {
                      username = '';
                      logoutUser(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Logged out successfully!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      fetchPreferences();

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyHomePage(title: '',),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Log out/Sign out'),
                      ],
                    ),
                  ),

                // User Feedback
                ElevatedButton(
                  onPressed: () {
                    // This callback will be executed when returning from the FeedbackPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => Scaffold(
                          body: FeedbackPage(),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.feedback),
                      SizedBox(width: 8),
                      Text('Provide Feedback'),
                    ],
                  ),
                ),

              ],
            ),
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
