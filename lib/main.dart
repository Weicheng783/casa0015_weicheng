import 'dart:async';
import 'dart:math' as math;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'mainHelpers.dart';
import 'package:location/location.dart';
import 'navigation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    String greeting = getGreeting();
    Size size = MediaQuery.of(context).size;
    int currentPageIndex = 0;
    Color color_sec = Theme.of(context).colorScheme.primaryContainer;
    final Completer<GoogleMapController> _controller =
    Completer<GoogleMapController>();

    const CameraPosition _kGooglePlex = CameraPosition(
      target: LatLng(37.42796133580664, -122.085749655962),
      zoom: 14.4746,
    );
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        height: 70,
        backgroundColor: color_sec,
        surfaceTintColor: color_sec,
        indicatorColor: Colors.amber,
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
        ],
      ),
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: color_sec,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(systemNavigationBarColor: color_sec,
            statusBarColor: color_sec),
      ),
      body: ListView( // Wrap your main content with a ListView
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                fontFamily: 'caveat',
                fontWeight: FontWeight.w500,
                fontSize: 24.0,
              ),
            ),
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            // GoogleMap(
            //   mapType: MapType.hybrid,
            //   initialCameraPosition: _kGooglePlex,
            //   onMapCreated: (GoogleMapController controller) {
            //     _controller.complete(controller);
            //   },
            // ),
            SizedBox(
                height: 600,
                width: size.width*0.95,
                child: MapSample()
            ),
          ],)

          // Theme.of(context).platform == TargetPlatform.iOS ? // ternary if statement to check for iOS
          // CupertinoAlertDialog() : // Cupertino style dialog
          // AlertDialog(),// Material style dialog
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  MapSampleState createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  late GoogleMapController mapController;
  late LocationData currentLocation;
  String? compassDirection;
  double? compassHeading;
  String? phoneOrientation;

  @override
  void initState() {
    super.initState();
    getLocation();
    initSensors();
  }

  Future<void> getLocation() async {
    Location location = Location();

    try {
      LocationData userLocation = await location.getLocation();
      setState(() {
        currentLocation = userLocation;
      });
    } catch (e) {
      print('Error: $e');
    }

    location.onLocationChanged.listen((LocationData newLocation) {
      setState(() {
        currentLocation = newLocation;
        updateMapCamera();
      });
    });
  }

  void updateMapCamera() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            currentLocation.latitude ?? 0.0,
            currentLocation.longitude ?? 0.0,
          ),
          zoom: 15.0,
        ),
      ),
    );
  }

  void initSensors() {
    magnetometerEvents.listen((MagnetometerEvent event) {
      double x = event.x;
      double y = event.y;

      double heading = math.atan2(y, x);
      heading = heading * (180 / math.pi);
      if (heading < 0) {
        heading = 360 + heading;
      }

      String direction = getCompassDirection(heading);

      setState(() {
        compassDirection = direction;
        compassHeading = heading;
      });
    });

    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        // Determine phone orientation based on accelerometer data
        if (event.y > 9.5) {
          phoneOrientation = "Portrait";
        } else if (event.y < -9.5) {
          phoneOrientation = "PortraitUpsideDown";
        } else if (event.x > 9.5) {
          phoneOrientation = "LandscapeLeft";
        } else if (event.x < -9.5) {
          phoneOrientation = "LandscapeRight";
        }
      });
    });
  }

  String getCompassDirection(double heading) {
    const List<String> directions = [
      'N', 'NNE', 'NE', 'ENE',
      'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW',
      'W', 'WNW', 'NW', 'NNW'
    ];

    int index = ((heading + 11.25) % 360 / 22.5).floor();
    return directions[index % 16];
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightnessValue = MediaQuery.of(context).platformBrightness;
    bool isDark = brightnessValue == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: 300,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 5.0,
                child: GoogleMap(
                  onMapCreated: (controller) {
                    mapController = controller;
                    updateMapCamera(); // Center the map initially
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      currentLocation.latitude ?? 0.0,
                      currentLocation.longitude ?? 0.0,
                    ),
                    zoom: 15.0,
                  ),
                  myLocationEnabled: true,
                  tiltGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              "User Location Information",
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            StreamBuilder<LocationData>(
              stream: Location().onLocationChanged,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  LocationData locationData = snapshot.data!;
                  return Column(
                    children: [
                      Text("Latitude: ${locationData.latitude ?? 0.0}"),
                      Text("Longitude: ${locationData.longitude ?? 0.0}"),
                      // Add more information as needed, e.g., orientation, etc.
                    ],
                  );
                } else {
                  return Text("Waiting for location data...");
                }
              },
            ),
            SizedBox(height: 16.0),
            Text(
              "Compass Information",
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text("Compass Direction: ${compassDirection ?? 'N/A'}"),
            // Text("Compass Heading: ${compassHeading ?? 'N/A'} degrees"),
            Text("Phone Orientation: ${phoneOrientation ?? 'N/A'}"),
          ],
        ),
      ),
    );
  }
}