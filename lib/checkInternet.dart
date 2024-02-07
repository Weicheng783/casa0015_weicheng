import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InternetStatusButton extends StatefulWidget {
  @override
  _InternetStatusButtonState createState() => _InternetStatusButtonState();
}

// Check internet status when user entering the app
class _InternetStatusButtonState extends State<InternetStatusButton> {
  bool isOnline = true;
  bool canReachServer = true;

  @override
  void initState() {
    super.initState();

    // Subscribe to connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        isOnline = result != ConnectivityResult.none;
      });

      // Check server reachability when the connectivity changes
      _checkServerReachability();
    });
  }

  Future<void> _checkServerReachability() async {
    if (isOnline) {
      try {
        // Attempt to establish a connection to the server
        final response = await http.get(Uri.parse("https://weicheng.app"));

        // Update the canReachServer variable based on the response
        setState(() {
          canReachServer = response.statusCode == 200;
        });
      } catch (e) {
        // Unable to reach the server
        try {
          setState(() {
            canReachServer = false;
          });
        } catch(e){
          canReachServer = false;
        }
      }
    } else {
      // No internet connection
      try {
        setState(() {
          canReachServer = false;
        });
      } catch(e){
        canReachServer = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        // Handle button press if needed
        // You can add your own logic here
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline
                ? canReachServer
                ? Icons.wifi
                : Icons.private_connectivity_outlined
                : Icons.signal_wifi_off,
            color: isOnline
                ? canReachServer
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.error,
          ),
          SizedBox(width: 8),
          Text(
            isOnline
                ? canReachServer
                ? 'Server Connected'
                : 'Server unreachable or no login yet'
                : 'No WiFi Connection',
            style: TextStyle(
              color: isOnline
                  ? canReachServer
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}