import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
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
          colorScheme: lightColorScheme ?? _defaultLightColorScheme,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          useMaterial3: true,
        ),
        themeMode: currentBrightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: const MyHomePage(title: 'Weicheng Story Trail'),
        debugShowCheckedModeBanner: false, // Disable debug banner
      );
    });
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
                  MaterialPageRoute(builder: (context) => LoginScreen()),
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
                        Text(
                          encouragementSentences[Random().nextInt(encouragementSentences.length-1)],
                          style: const TextStyle(
                            fontFamily: 'lobster_two',
                            fontWeight: FontWeight.w400,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center, // Horizontal alignment
                        ),
                        Text(
                          '$_counter',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(
                          height: 600,
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