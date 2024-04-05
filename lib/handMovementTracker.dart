import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:sensors_plus/sensors_plus.dart';

class HandMovementTrackerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 350,
        child: HandMovementTracker(),
      ),
    );
  }
}

class HandMovementTracker extends StatefulWidget {
  @override
  _HandMovementTrackerState createState() => _HandMovementTrackerState();
}

class _HandMovementTrackerState extends State<HandMovementTracker> {
  List<Offset> _trajectory = [];
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isDrawing = true;
  double _displacementX = 0.0;
  double _displacementY = 0.0;
  Timer? _timer;
  int _luckyNumber = Random().nextInt(100); // Generate a random lucky number
  String _hashCode = '';

  @override
  void initState() {
    super.initState();

    _startTimer();

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      double threshold = 0.5;

      if (_isDrawing) {
        if (event.x.abs() > threshold || event.y.abs() > threshold) {
          _displacementX += event.y / 100;
          _displacementY += event.x / 100;
          _trajectory.add(Offset(_displacementX, _displacementY));
          setState(() {});
        }
      }
    });

    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      double movementSpeed = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (_isDrawing && movementSpeed > 1.0) {
        _trajectory.add(Offset(event.x / 5, -event.y / 5));
        setState(() {}); // Trigger repaint when a new point is added
      }
    });
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    const duration = Duration(seconds: 10);
    _timer = Timer(duration, _handleTimeout);
  }

  void _handleTimeout() {
    setState(() {
      _isDrawing = false;
    });

    // Encode trajectory into short text here
    String encodedTrajectory = _encodeTrajectory();
    String concatenatedString = '$encodedTrajectory$_luckyNumber'; // Concatenate with lucky number

    // Calculate hash code
    _hashCode = crypto.md5.convert(utf8.encode(concatenatedString)).toString();
  }

  String _encodeTrajectory() {
    // Encode the trajectory into a short text format
    // For example, you can use JSON encoding
    return _trajectory.map((offset) => [offset.dx, offset.dy]).toList().toString();
  }

  @override
  Widget build(BuildContext context) {
    final double size = MediaQuery.of(context).size.width * 0.9;

    return Column(
      children: [
        SizedBox(
          width: size,
          child: GestureDetector(
            onDoubleTap: () {
              setState(() {
                _trajectory.clear();
                _displacementX = 0.0;
                _displacementY = 0.0;
              });
            },
            child: CustomPaint(
              size: Size(size, 200),
              painter: HandMovementPainter(_trajectory),
            ),
          ),
        ),
        SizedBox(height: 10),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Hash Code:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _hashCode,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HandMovementPainter extends CustomPainter {
  final List<Offset> trajectory;

  HandMovementPainter(this.trajectory);

  @override
  void paint(Canvas canvas, Size size) {
    if (trajectory.isNotEmpty) {
      double minX = trajectory.map((offset) => offset.dx).reduce(min);
      double maxX = trajectory.map((offset) => offset.dx).reduce(max);
      double minY = trajectory.map((offset) => offset.dy).reduce(min);
      double maxY = trajectory.map((offset) => offset.dy).reduce(max);
      double scaleX = size.width / (maxX - minX);
      double scaleY = size.height / (maxY - minY);
      double scale = min(scaleX, scaleY);

      List<Color> colors = [Colors.blue, Colors.green, Colors.yellow, Colors.red];
      double gradientInterval = trajectory.length > 1 ? 1.0 / (trajectory.length - 1) : 1.0;

      for (int i = 0; i < trajectory.length - 1; i++) {
        double fraction = i * gradientInterval;
        Paint paint = Paint()
          ..color = Color.lerp(colors[i % colors.length], colors[(i + 1) % colors.length], fraction)!
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

        Offset scaledStart = Offset((trajectory[i].dx - minX) * scale, (trajectory[i].dy - minY) * scale);
        Offset scaledEnd = Offset((trajectory[i + 1].dx - minX) * scale, (trajectory[i + 1].dy - minY) * scale);
        try{
          canvas.drawLine(
            scaledStart,
            scaledEnd,
            paint,
          );
        }catch(e){}
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}