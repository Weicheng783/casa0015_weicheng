import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

// This Class Serves as 'Sensors' Page
// Edited by Weicheng Mar.19, 24.
class TemperatureTable extends StatefulWidget {
  const TemperatureTable({super.key});

  @override
  _TemperatureTableState createState() => _TemperatureTableState();
}

// We create its states
class _TemperatureTableState extends State<TemperatureTable> {
  // We fetch: data points, threshold values and responses
  // Also doing two Boolean Values as declarative UI
  List<Map<String, dynamic>> temperatureData = [];
  double humidityThreshold = 0.0;
  double lastAlertValue = 0.0;
  TextEditingController inputController = TextEditingController();
  TextEditingController geminiInputController = TextEditingController();
  String geminiResponse = '';
  bool isSubmittingGeminiInput = false;
  bool isSubmittingGeminiInput_1 = false;

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchAlertData();
  }

  // Fetch Threshold Data from remote server via API
  Future<void> fetchData() async {
    final response = await http.post(
      Uri.parse('https://weicheng.app/baby_guardian/temp_humid.php'),
      body: {'device_serial': '1', 'mode': 'find'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      setState(() {
        temperatureData = jsonData.cast<Map<String, dynamic>>();
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  // Fetch Alert Data from remote server via API
  Future<void> fetchAlertData() async {
    final response = await http.post(
      Uri.parse('https://weicheng.app/baby_guardian/alert.php'),
      body: {
        'device_serial': '1',
        'mode': 'find',
        'status': 'u2d_received',
        'type': 'Humidifier Intensity',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      if (jsonData.isNotEmpty) {
        final lastEntry = jsonData.last;
        setState(() {
          lastAlertValue = double.parse(lastEntry['alert'].toString());
        });
      }
    } else {
      throw Exception('Failed to load alert data');
    }
  }

  // Alert Dialog Control (Declarative UI)
  Future<bool?> showAlertDialog(BuildContext context) async {
    return showDialog<bool?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm'),
          content: Text('Are you sure you want to submit the humidity threshold with that value?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // Write Threshold Data from remote server via API
  Future<void> submitAlert() async {
    final double inputValue = double.tryParse(inputController.text) ?? 0.0;

    if (inputValue < 1 || inputValue > 95) {
      // Show an error message if the entered value is not within the valid range.
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please enter a value between 1 and 95.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    final confirmed = await showAlertDialog(context);

    if (confirmed ?? false) {
      // User confirmed, make the HTTP POST request
      final response = await http.post(
        Uri.parse('https://weicheng.app/baby_guardian/alert.php'),
        body: {
          'device_serial': '1',
          'mode': 'insert',
          'alert': inputValue.toString(),
          'type': 'Humidifier Intensity',
          'status': 'u2d_sent',
          'addition': '',
        },
      );

      if (response.statusCode == 200) {
        // Successfully submitted
        fetchAlertData(); // Refresh the displayed data
      } else {
        // Handle error
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to submit alert value. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // Gemini User Input Submit and Feedback
  Future<void> submitGeminiInput() async {
    setState(() {
      isSubmittingGeminiInput = true; // Set the flag to true when submitting
    });

    final String inputValue = geminiInputController.text;

    final response = await http.post(
      Uri.parse('https://weicheng.app/baby_guardian/gemini_input.php'),
      body: {'mode': 'full', 'input': inputValue},
    );

    print('Gemini Input Response: ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        geminiResponse = response.body;
      });
    } else {
      // Handle error
      showGeminiErrorDialog();
    }

    setState(() {
      isSubmittingGeminiInput = false; // Set the flag back to false after submission
    });
  }

  // Gemini Sensor Info as Input Response
  Future<void> submitGeminiInput_1() async {
    setState(() {
      isSubmittingGeminiInput_1 = true; // Set the flag to true when submitting
    });

    final String inputValue = temperatureData.reversed.first.toString();

    print('Data Points: ${inputValue}');

    final response = await http.post(
      Uri.parse('https://weicheng.app/baby_guardian/gemini_input.php'),
      body: {'mode': 'full', 'input': 'Given the following data points of datetime, temperature and humidity data, please analyse the current weather condition and give people some advice when going outside: '+inputValue},
    );

    print('Gemini Input Response: ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        geminiResponse = response.body;
      });
    } else {
      // Handle error
      showGeminiErrorDialog();
    }

    setState(() {
      isSubmittingGeminiInput_1 = false; // Set the flag back to false after submission
    });
  }

  // When Gemini Error happens (failure to connect, codes other than 200 OK)
  void showGeminiErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('Failed to get Gemini input response. Please try again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // It then builds different widgets layout according to the Flutter UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.sensors),
            SizedBox(width: 8), // Adjust the space between the icon and text
            Text('Area Sensor Information'),
          ],
        ),
        backgroundColor: Platform.isIOS ? null : Theme.of(context).colorScheme.secondaryContainer,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Text('Area Humidity Threshold: $lastAlertValue %', style: TextStyle(fontSize: 20),),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: FocusNode(),
                      controller: inputController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'New Humidity Threshold (0-95)',
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: submitAlert,
                    child: Text('Submit'),
                  ),
                ],
              ),
            ),
            Text('We include such control for inclusivity and different users\' needs.', style: TextStyle(fontSize: 20), textAlign: TextAlign.center,),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    focusNode: FocusNode(),
                    controller: geminiInputController,
                    maxLines: null, // or a large value to allow automatic expansion
                    decoration: InputDecoration(
                      labelText: 'Ask/Enter Anything',
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isSubmittingGeminiInput ? null : submitGeminiInput,
                    child: isSubmittingGeminiInput
                        ? CircularProgressIndicator() // Show loading animation
                        : Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stars_sharp),
                        SizedBox(width: 8), // Adjust the space between the icon and text
                        Text('Submit Input to Gemini'),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isSubmittingGeminiInput_1 ? null : submitGeminiInput_1,
                    child: isSubmittingGeminiInput_1
                        ? CircularProgressIndicator() // Show loading animation
                        : Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome),
                        SizedBox(width: 8), // Adjust the space between the icon and text
                        Text('Get Data Insights'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Gemini Response is a decisive criteria for showing the following
            if(geminiResponse != "")
              Container(
                padding: EdgeInsets.all(16.0), // Adjust the padding as needed
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black), // Add a border for clarity
                  borderRadius: BorderRadius.circular(10.0), // Add rounded corners
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    geminiResponse,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            // DataTable
            // We need to grab a data table and loop through the data points
            DataTable(
              columns: [
                DataColumn(label: Text('DateTime')),
                DataColumn(label: Text('Temperature')),
                DataColumn(label: Text('Humidity')),
              ],
              rows: temperatureData.reversed.map((data) {
                return DataRow(
                  cells: [
                    DataCell(Text(data['datetime'])),
                    DataCell(Text(data['temp'].toString()+" °C")),
                    DataCell(Text(data['humid'].toString()+ " %")),
                  ],
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            Text('This feature page is available in public for beta testing. 240227.', style: TextStyle(fontSize: 10),),
          ],
        ),
      ),
    );
  }
}