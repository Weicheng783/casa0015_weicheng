import 'dart:math';
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:story.trail/shortestJourney.dart';
import 'package:story.trail/submitTrail.dart';
import 'package:story.trail/temperature_table.dart';
import 'package:story.trail/userDetails.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'checkInternet.dart';
import 'dataFetcher.dart';
import 'emergencyButton.dart';
import 'feedbackPage.dart';
import 'getPhoto.dart';
import 'handMovementTracker.dart';
import 'mainHelpers.dart';
import 'package:location/location.dart';
import 'mapHelper.dart';
import 'navigation.dart';
import 'login.dart'; // Import the login screen file

// App version information
String revision_ver = "5.4";
String build_ver = "240422";

// App Device Locker (240405)
// Implementation: https://stackoverflow.com/questions/61889443/flutter-app-ability-to-turn-off-the-screen
const platform = MethodChannel('flutter.native/powerOff');
Future<void> responseFromNativeCode() async {
  try {
    await platform.invokeMethod('powerOff');
  } on PlatformException catch (e) {
    print("Failed to Invoke: '${e.message}'.");
  }
}

// Main entry point of the application
void main() {
  runApp(const MyApp());
}

// MyApp class, which represents the overall application
class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  // Default color schemes for light and dark themes
  static final _defaultLightColorScheme =
  ColorScheme.fromSwatch(primarySwatch: Colors.grey);

  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, brightness: Brightness.dark);

  @override
  Widget build(BuildContext context) {
    // Determine current brightness and platform (iOS or not)
    Brightness currentBrightness = MediaQuery.of(context).platformBrightness;
    bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    // Build the MaterialApp with dynamic color schemes
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
        title: 'Story Trail',
        theme: isIOS
            ? ThemeData(
          cupertinoOverrideTheme: CupertinoThemeData(
            brightness: currentBrightness == Brightness.dark
                ? Brightness.dark
                : Brightness.light,
            // Add iOS-specific styles here
            primaryColor: Colors.deepPurpleAccent, // Adjust iOS primary color
            barBackgroundColor: currentBrightness == Brightness.dark
                ? Colors.grey[900] // Adjust background color for dark mode
                : null, // Use default background color for light mode
            // Add more iOS-specific styles here
          ),
        )
            : ThemeData(
          useMaterial3: true,
          colorScheme: lightColorScheme ??
              _defaultLightColorScheme.copyWith(
                  background: lightColorScheme?.primaryContainer ??
                      Colors.white),
          scaffoldBackgroundColor:
          lightColorScheme?.primaryContainer ?? Colors.white,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: darkColorScheme ??
              _defaultDarkColorScheme.copyWith(
                  background: darkColorScheme?.primaryContainer ??
                      Colors.black),
          scaffoldBackgroundColor:
          darkColorScheme?.secondaryContainer ?? Colors.black,
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
        // It can also use a different color for dark mode if needed
      );
    });
  }

  // Check if the user is logged in
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    fetchPreferences();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}

// MyHomePage class, representing the main content of the app
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Variables to store logged-in username and fetch user preferences
String loggedInUsername = '';
bool dataSaver = false;
bool friendMode = false;
bool londonTflHelper = false;
bool showEasterEgg = false;

String startLat = "";
String startLong = "";
String endLat = "";
String endLong = "";
String emergencyId = "";
String emergencyLat = "";
String emergencyLong = "";

dynamic emergencyTappedMarker;

List<Marker> emergencyPlaces = [];
List<String> emergencyPeople = [];

Future<void> getLoggedInUsername() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? username = prefs.getString('username');
  if (username != null) {
    loggedInUsername = username;
  }
}

Future<void> getEmergencyId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? temp = prefs.getString('emergencyId');
  if (temp != null && temp != "") {
    emergencyId = temp;
  }else{
    emergencyId = "";
  }
}

Future<void> getDataSaverMode() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? saverString = prefs.getString('datasaver');
  if (saverString != null && saverString != "") {
    dataSaver = true;
  }else{
    dataSaver = false;
  }
}

Future<void> getFriendMode() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? saverString = prefs.getString('friendMode');
  if (saverString != null && saverString != "") {
    friendMode = true;
  }else{
    friendMode = false;
  }
}

Future<void> getLondonTflMode() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? temp = prefs.getString('tflMode');
  if (temp != null && temp != "") {
    londonTflHelper = true;
  }else{
    londonTflHelper = false;
  }
}

Future<void> getEasterEggMode() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? temp = prefs.getString('showEasterEgg');
  if (temp != null && temp != "") {
    showEasterEgg = true;
  }else{
    showEasterEgg = false;
  }
}

Future<void> setVariableModes(String variable, String setter) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(variable, setter);
  if(variable == "datasaver"){
    if(setter != ""){
      dataSaver = true;
    }else{
      dataSaver = false;
    }
  }else if(variable == "friendMode"){
    if(setter != ""){
      friendMode = true;
    }else{
      friendMode = false;
    }
  }else if(variable == "tflMode"){
    if(setter != ""){
      londonTflHelper = true;
    }else{
      londonTflHelper = false;
    }
  }else if(variable == "showEasterEgg"){
    if(setter != ""){
      showEasterEgg = true;
    }else{
      showEasterEgg = false;
    }
  }else if(variable == "emergencyId"){
    if(setter != ""){
      emergencyId = variable;
    }else{
      emergencyId = "";
    }
  }
}

// State class for MyHomePage
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool isLoggedIn = false;
  String username = 'Guest'; // Default username when not logged in

  @override
  void initState() {
    super.initState();
    _loadLoggedInUsername();
    getEmergencyId();
    getDataSaverMode();
    getFriendMode();
    getLondonTflMode();
    getEasterEggMode();
    fetchPreferences();
  }

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    _loadLoggedInUsername();
  }

  Future<void> _loadLoggedInUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    if (username != null) {
      fetchPreferences();
      setState(() {
        loggedInUsername = username;
      });
    }
  }

  // Increment the counter
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
    bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    // Set the system UI overlay style in the main build method
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor:
        Theme.of(context).colorScheme.secondaryContainer,
        statusBarColor: Theme.of(context).colorScheme.secondaryContainer,
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
      child: Scaffold( // Bottom Navigation Bar of the screen
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
              // Add logic for LoginScreen navigation here
              if (currentPageIndex == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(),
                  ),
                );
              }else if(currentPageIndex == 1){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserDetailsPage(username: loggedInUsername,)),
                );
              }else if(currentPageIndex == 3){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TemperatureTable()),
                );
              }
            });
          },
          height: 70,
          backgroundColor: isIOS ? null : color_sec,
          surfaceTintColor: isIOS ? null : color_sec,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              selectedIcon: Icon(Icons.home),
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.perm_contact_cal),
              icon: Icon(Icons.perm_contact_cal),
              label: 'My Trail',
            ),
            // NavigationDestination(
            //   icon: Badge(child: Icon(Icons.notifications_sharp)),
            //   label: 'Notifications',
            // ),
            // NavigationDestination(
            //   icon: Badge(
            //     label: Text('1'),
            //     child: Icon(Icons.messenger_sharp),
            //   ),
            //   label: 'Messages',
            // ),
            NavigationDestination(
              icon: Icon(Icons.account_circle),
              label: 'Account',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.sensors),
              icon: Icon(Icons.sensors),
              label: 'Sensors',
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
                        DataFetcher(),
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
                            style: Platform.isIOS? null : ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).colorScheme.primaryContainer,
                              ),
                            ),
                            onPressed: () {
                              loggedInUsername = '';
                              logoutUser();
                              _loadLoggedInUsername();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Logged out successfully!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              fetchPreferences();
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InternetStatusButton(),
                            if(Platform.isAndroid)
                              ElevatedButton(
                                style: Platform.isIOS? null : ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all<Color>(
                                    Theme.of(context).colorScheme.primaryContainer,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_outline_rounded),
                                  ]
                                  ,),
                                onPressed: responseFromNativeCode,
                              ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onLongPress: () {
                                fetchPreferences();
                                setState(() {
                                  // Toggle the state of the button
                                  dataSaver = !dataSaver;

                                  // Depending on the state, call the appropriate function
                                  if (dataSaver) {
                                    setVariableModes("datasaver", "On");
                                  } else {
                                    setVariableModes("datasaver", "");
                                  }
                                  getDataSaverMode();
                                });
                              },
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("To turn on/off data saver, long press it."),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(dataSaver ? Icons.data_saver_on_rounded : Icons.data_saver_off_rounded), // Change the icon based on the state
                                  SizedBox(width: 8),
                                  Text(dataSaver ? 'Data Saver On' : 'Data Saver Off'), // Change the text based on the state
                                ],
                              ),
                            ),
                            SizedBox(width: 5,),
                            EmergencyAlertButton(),
                          ],
                        ),
                        // The button for enabling friend mode
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:[
                              Icon(Icons.people_alt_rounded),
                              SizedBox(height: 16.0, width: 15,),
                              // Switch widget to toggle automatic calls
                              Text("Allow Friend Mode"),
                              SizedBox(width: 15,),
                              Switch(
                                value: friendMode,
                                onChanged: (value) {
                                  setState(() {
                                    friendMode = value;
                                    if (friendMode) {
                                      // _findNearestUnexploredEntry();
                                      setVariableModes("friendMode", "On");
                                    }else{
                                      setVariableModes("friendMode", "");
                                    }
                                  });
                                  getFriendMode();
                                },
                              ),
                            ]
                        ),
                        if (loggedInUsername.isEmpty)
                          ElevatedButton(
                            style: Platform.isIOS? null : ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).colorScheme.primaryContainer,
                              ),
                            ),
                            onPressed: () {
                              fetchPreferences();
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
                        SizedBox(
                          child: SizedBox(
                            width: null,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {

                                  });
                                },
                                child: SizedBox(
                                  height: size.height,
                                  width: size.width * 0.95,
                                  child: MapSample(),
                                ),
                              ),
                            ),
                          ),
                        ),

                        if(emergencyPlaces.isNotEmpty && emergencyTappedMarker != null)
                          Card(
                            elevation: 5.0,
                            margin: EdgeInsets.all(16.0),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Only display details for the first tapped marker
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.warning_amber_rounded, size: 50,),
                                      SizedBox(width: 15,),
                                      Icon(Icons.emergency_share, size: 50,),
                                      SizedBox(width: 15,),
                                      Icon(Icons.emergency, size: 50,),
                                    ],
                                  ),
                                  Text('${(emergencyTappedMarker['sender'] != "" && emergencyTappedMarker['sender'] != null)  ? emergencyTappedMarker['sender'] : ""} has initiated an Emergency Service, please check out if possible.'),
                                  Text('At Time: ${emergencyTappedMarker['time']}'),
                                  Text('Latitude: ${emergencyLat}'),
                                  Text('Longitude: ${emergencyLong}'),
                                  Text('Content: ${emergencyTappedMarker['message']}'),
                                  Text('Message ID: ${emergencyTappedMarker['id']}'),
                                ],
                              ),
                            ),
                          ),

                        if(londonTflHelper)
                          ShortestJourneyWidget(startLat: startLat, endLat: endLat, startLong: startLong, endLong: endLong),

                        if(londonTflHelper)
                          SizedBox(height: 30,),

                        // Auxiliary information such as Author info, etc.
                        Center(
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
                              Center(
                                child: Text(
                                  "Weicheng Project No.240109",
                                  style: const TextStyle(
                                    fontFamily: 'caveat',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                      onPressed: () {
                                        // Handle button press, e.g., open the GitHub project
                                        launchUrl(Uri.parse('https://github.com/Weicheng783/casa0015_weicheng/releases'));
                                      },
                                      style: Platform.isIOS? null : ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all<Color>(
                                          Theme.of(context).colorScheme.secondaryContainer,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.code),
                                          SizedBox(width: 8),
                                          Text('GitHub Project'),
                                        ],
                                      )
                                  ),
                                  SizedBox(width: 10),
                                  ElevatedButton(
                                      onPressed: () {
                                        // Handle button press, e.g., open the GitHub project
                                        launchUrl(Uri.parse('https://github.com/Weicheng783'));
                                      },
                                      style: Platform.isIOS? null : ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all<Color>(
                                          Theme.of(context).colorScheme.secondaryContainer,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.account_circle),
                                          SizedBox(width: 8),
                                          Text('My GitHub'),
                                        ],
                                      )
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Center(
                                child: Text(
                                  "Open Sourced Under The MIT License",
                                  style: const TextStyle(
                                    fontFamily: 'caveat',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Center(
                                child: Text(
                                  "Always making stuff with U & Heart💕",
                                  style: const TextStyle(
                                    fontFamily: 'caveat',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Center(
                                child: Text(
                                  "You are running revision $revision_ver, build $build_ver.",
                                  style: const TextStyle(
                                    fontFamily: 'caveat',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              SizedBox(height: 30),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children:[
                                    SizedBox(height: 16.0),
                                    // Switch widget to toggle automatic calls
                                    Text("Show Easter Egg "),
                                    Switch(
                                      value: showEasterEgg,
                                      onChanged: (value) {
                                        setState(() {
                                          showEasterEgg = value;
                                          if(showEasterEgg){
                                            setVariableModes("showEasterEgg", "On");
                                          }else{
                                            setVariableModes("showEasterEgg", "");
                                          }
                                        });
                                        getEasterEggMode();
                                      },
                                    ),
                                  ]
                              ),
                              if(showEasterEgg)
                                HandMovementTrackerCard(),
                              SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                );
              });
            },
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SubmitTrailPage()),
            );
          },
          tooltip: 'Submit Trail',
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

// Log out logic
void logoutUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('username', '');
}

// Entry Details Constructor
class EntryDetailsWidget extends StatelessWidget {
  final EntryMarker entryMarker;

  EntryDetailsWidget({required this.entryMarker});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Entry ID: ${entryMarker.toMarker().markerId.value}'),
        Text('Latitude: ${entryMarker.latitude}'),
        Text('Longitude: ${entryMarker.longitude}'),
        Text('Time: ${entryMarker.time}'),
        Text('Date: ${entryMarker.date}'),
        Text('Content: ${entryMarker.content}'),
      ],
    );
  }
}