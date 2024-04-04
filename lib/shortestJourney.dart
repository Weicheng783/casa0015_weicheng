import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ShortestJourneyWidget extends StatefulWidget {
  final String startLat;
  final String startLong;
  final String endLat;
  final String endLong;

  const ShortestJourneyWidget({
    Key? key,
    required this.startLat,
    required this.startLong,
    required this.endLat,
    required this.endLong,
  }) : super(key: key);

  @override
  _ShortestJourneyWidgetState createState() => _ShortestJourneyWidgetState();
}

class _ShortestJourneyWidgetState extends State<ShortestJourneyWidget> {
  late Future<List<Journey>?> _journeysFuture;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _journeysFuture = fetchJourneys();
  }

  @override
  void didUpdateWidget(ShortestJourneyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startLat != widget.startLat ||
        oldWidget.startLong != widget.startLong ||
        oldWidget.endLat != widget.endLat ||
        oldWidget.endLong != widget.endLong) {
      // Parameters have changed, fetch new journeys
      _journeysFuture = fetchJourneys();
      setState(() {
        _currentIndex = 0; // Reset index when parameters change
      });
    }
  }


  Future<List<Journey>?> fetchJourneys() async {
    final response = await http.get(
      Uri.parse('https://api.tfl.gov.uk/journey/journeyresults/${widget.startLat},${widget.startLong}/to/${widget.endLat},${widget.endLong}?app_id=%201f3ca8e97dcc4ff2a4ddf9d41b79e6f2&app_key=0ff1ef54da914ef284f41357acc253b0'),
      // body: jsonEncode({
      //   'startLat': widget.startLat,
      //   'startLong': widget.startLong,
      //   'endLat': widget.endLat,
      //   'endLong': widget.endLong,
      // }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body)['journeys'];
      List<Journey> journeys = jsonList.map((json) => Journey.fromJson(json)).toList();
      return journeys;
    } else {
      throw Exception('Failed to load journeys');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Journey>?>(
      future: _journeysFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // return Center(child: Text('Error: ${snapshot.error}'));
          return Center(child: Text('No journeys found or destination selected.'));
        } else if (snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(child: Text('No journeys found.'));
        } else {
          List<Journey> journeys = snapshot.data!;
          return SizedBox(
            height: 400, // Adjust height as needed
            child: PageView.builder(
              itemCount: journeys.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildJourneyCard(journeys[index]);
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildJourneyCard(Journey journey) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Journey Option #${_currentIndex + 1}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Journey Start Time: ${journey.startDateTime}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Expected Arrival Time: ${journey.arrivalDateTime}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Total Journey Duration: ${journey.duration} minutes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: journey.legs.length,
                itemBuilder: (context, index) {
                  Leg leg = journey.legs[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text('Step Duration: ${leg.duration} minutes'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: leg.instructions.map((instruction) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Instruction:\n ${instruction.summary}'),
                              if(instruction.detailed != instruction.summary)
                                Text('(${instruction.detailed})'),
                            ],
                          )).toList(),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Journey {
  final String startDateTime;
  final String arrivalDateTime;
  final int duration;
  final List<Leg> legs;

  Journey({
    required this.startDateTime,
    required this.arrivalDateTime,
    required this.duration,
    required this.legs,
  });

  factory Journey.fromJson(Map<String, dynamic> json) {
    List<Leg> legs = [];
    dynamic jsonLegs = json['legs'];

    // If 'legs' is a List
    if (jsonLegs is List) {
      legs = jsonLegs.map((legJson) => Leg.fromJson(legJson)).toList();
    }
    // If 'legs' is a single object
    else if (jsonLegs is Map<String, dynamic>) {
      legs.add(Leg.fromJson(jsonLegs));
    }

    return Journey(
      startDateTime: json['startDateTime'],
      arrivalDateTime: json['arrivalDateTime'],
      duration: json['duration'],
      legs: legs,
    );
  }
}

class Leg {
  final int duration;
  final List<Instruction> instructions;

  Leg({
    required this.duration,
    required this.instructions,
  });

  factory Leg.fromJson(Map<String, dynamic> json) {
    List<Instruction> instructions = [];
    dynamic jsonInstructions = json['instruction'];

    // If 'instruction' is a List
    if (jsonInstructions is List) {
      instructions = jsonInstructions.map((instructionJson) => Instruction.fromJson(instructionJson)).toList();
    }
    // If 'instruction' is a single object
    else if (jsonInstructions is Map<String, dynamic>) {
      instructions.add(Instruction.fromJson(jsonInstructions));
    }

    return Leg(
      duration: json['duration'],
      instructions: instructions,
    );
  }
}

class Instruction {
  final String summary;
  final String detailed;

  Instruction({
    required this.summary,
    required this.detailed,
  });

  factory Instruction.fromJson(Map<String, dynamic> json) {
    return Instruction(
      summary: json['summary'],
      detailed: json['detailed'],
    );
  }
}