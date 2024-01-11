import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mainHelpers.dart';
import 'package:location/location.dart';
import 'navigation.dart';
import 'login.dart'; // Import the login screen file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  static final _defaultLightColorScheme =
  ColorScheme.fromSwatch(primarySwatch: Colors.blue);

  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, brightness: Brightness.dark);

  @override
  Widget build(BuildContext context) {
    Brightness currentBrightness = MediaQuery.of(context).platformBrightness;

    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
        title: 'Story Trail',
        theme: ThemeData(
          useMaterial3: true, colorScheme: lightColorScheme ?? _defaultLightColorScheme.copyWith(background: lightColorScheme?.primaryContainer ?? Colors.white),
        ),
        darkTheme: ThemeData(
          useMaterial3: true, colorScheme: darkColorScheme ?? _defaultDarkColorScheme.copyWith(background: darkColorScheme?.primaryContainer ?? Colors.black),
        ),
        themeMode: currentBrightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: FutureBuilder<bool>(
          future: isLoggedIn(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return MyHomePage(
                title: 'Weicheng Story Trail',
              );
            } else {
              return Scaffold(body: CircularProgressIndicator());
            }
          },
        ),
        debugShowCheckedModeBanner: false, // Disable debug banner
        // You can also use a different color for dark mode if needed
      );
    });
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool isLoggedIn = false;
  String username = 'Guest'; // Default username when not logged in
  late String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    _loadLoggedInUsername();
  }

  Future<void> _loadLoggedInUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    if (username != null) {
      setState(() {
        loggedInUsername = username;
      });
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    String greeting = getGreeting();
    Size size = MediaQuery.of(context).size;
    int currentPageIndex = 0;
    Color color_sec = Theme.of(context).colorScheme.secondaryContainer;

    // Set the system UI overlay style in the main build method
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor:
        Theme.of(context).colorScheme.secondaryContainer,
        statusBarColor: Theme.of(context).colorScheme.background,
      ),
    );

    return WillPopScope(
      onWillPop: () async {
        // If the current page is not the home page, simulate a back press
        if (currentPageIndex != 0) {
          _navigatorKey.currentState?.pop();
          return false;
        }
        return true; // Allow the default back button behavior on the home page
      },
      child: Scaffold(
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
              // Add logic for LoginScreen navigation here
              if (currentPageIndex == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(),
                  ),
                );
              }
            });
          },
          height: 70,
          backgroundColor: color_sec,
          surfaceTintColor: color_sec,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              selectedIcon: Icon(Icons.home),
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Badge(child: Icon(Icons.notifications_sharp)),
              label: 'Notifications',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text('1'),
                child: Icon(Icons.messenger_sharp),
              ),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.login),
              label: 'Login',
            ),
          ],
        ),
        appBar: currentPageIndex == 0
            ? null
            : AppBar(
          backgroundColor: color_sec, // Use the regular color for other pages
          actions: [
            isLoggedIn
                ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Welcome, $username!',
                style: TextStyle(fontSize: 16),
              ),
            )
                : SizedBox.shrink(),
          ],
          title: Text(widget.title),
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            systemNavigationBarColor: color_sec,
            statusBarColor: Theme.of(context).colorScheme.background,
          ),
        ),
        body: SafeArea(
          child: Navigator(
            key: _navigatorKey,
            onGenerateRoute: (routeSettings) {
              // Add logic to generate routes based on currentIndex if needed
              return MaterialPageRoute(builder: (context) {
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(
                            // fontFamily: 'caveat',
                            fontWeight: FontWeight.w500,
                            fontSize: 30,
                          ),
                        ),
                        const Text(
                          "Welcome to Story Trail",
                          style: TextStyle(
                            fontFamily: 'mplus_rounded1c',
                            fontWeight: FontWeight.w400,
                            fontSize: 30,
                          ),
                        ),
                        if (loggedInUsername.isNotEmpty)
                          ElevatedButton(
                            onPressed: () {
                              loggedInUsername = '';
                              logoutUser();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Logged out successfully!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              setState(() {});
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.logout),
                                SizedBox(width: 8),
                                Text('Logged in as: $loggedInUsername'),
                              ],
                            ),
                          ),
                        if (loggedInUsername.isEmpty)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person),
                                SizedBox(width: 8),
                                Text('Welcome, Guest'),
                              ],
                            ),
                          ),
                        Container(
                          width: size.width * 0.95, // Set width to 95% of the screen width
                          child: Text(
                            textAlign: TextAlign.center, // Horizontal alignment
                            encouragementSentences[Random().nextInt(encouragementSentences.length - 1)],
                            style: const TextStyle(
                              fontFamily: 'lobster_two',
                              fontWeight: FontWeight.w400,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        // Text(
                        //   '$_counter',
                        //   style: Theme.of(context).textTheme.headlineMedium,
                        // ),
                        // FloatingActionButton(
                        //   onPressed: () async {
                        //     // Call the function when the FAB is tapped
                        //     _loadLoggedInUsername();
                        //     SharedPreferences prefs = await SharedPreferences.getInstance();
                        //     String? storedValue = prefs.getString('username');
                        //     print('Stored value: $storedValue');
                        //     setState(() {});
                        //   },
                        //   child: Icon(Icons.refresh),
                        // ),
                        SizedBox(
                          height: size.height * 0.45,
                          width: size.width * 0.95,
                          child: MapSample(),
                        ),
                      ],
                    )
                  ],
                );
              });
            },
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      ),
    );
  }
}

void logoutUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('username', '');
}