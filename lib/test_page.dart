import 'dart:async';
import 'dart:math';
import 'package:flutter_application_1/provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

class BooleanToIntegerSequence extends StatefulWidget {
  final VoidCallback onPopScreen; // Accepting a callback

  const BooleanToIntegerSequence({super.key, required this.onPopScreen});

  @override
  _BooleanToIntegerSequenceState createState() =>
      _BooleanToIntegerSequenceState();
}

class _BooleanToIntegerSequenceState extends State<BooleanToIntegerSequence> {
  final String espIp = "http://192.168.4.1";
  final String sendEndpoint = "/save_test_check"; // Remove extra space
  final String receiveEndpoint = "/test_result";
  bool isProcessing = false;
  bool testCheck = false;
  List<int> receivedSequence = [];
  Timer? pollingTimer;

  // Function to send a boolean to ESP32
  Future<void> sendBooleanToESP32(bool value) async {
    setState(() {
      isProcessing = true;
      testCheck = true;
    });

    try {
      // Send the boolean value as a JSON object in the body
      final response = await http.post(
        Uri.parse(espIp + sendEndpoint),
        headers: {'Content-Type': 'application/json'}, // Ensure correct header
        body: jsonEncode({'value': value}), // Send as JSON
      );

      if (response.statusCode == 200) {
        print("Successfully sent boolean to ESP32!");
        startPolling(); // Start polling if request is successful
      } else {
        print("Failed to send data. Status code: ${response.statusCode}");
        setState(() {
          testCheck = false;
        });
      }
    } catch (e) {
      print("Error sending boolean: $e");
      setState(() {
        testCheck = false;
      });
    }
  }

  // Function to start polling for the result from ESP32
  void startPolling() {
    final rpmProvider=Provider.of<RPMRangeProvider>(context,listen: false);
    pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final response = await http.get(Uri.parse(espIp + receiveEndpoint));

        if (response.statusCode == 200) {
          // Parse the response body as a JSON object
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          // Extract the mode_path array from the response
          final List<dynamic> modePath = responseData['mode_path'];

          if (modePath != null) {
            setState(() {
              receivedSequence.clear();
              receivedSequence.addAll(modePath.map((e) => e as int)); // Add the mode_path sequence
              rpmProvider.updateModePath(receivedSequence);
            });
            print("Received mode_path: $modePath");

            // Check if sequence is complete (i.e., [1, 2, 3, 4, 3, 2, 1])
            if (receivedSequence.length >= 7) {
              timer.cancel();
              setState(() {
                sendBack();
                isProcessing = false;
              });
              showCompletionDialog();
            }
          } else {
            print("Invalid data received from ESP32.");
          }
        } else {
          print("Failed to receive data. Status code: ${response.statusCode}");
        }
      } catch (e) {
        print("Error polling mode path: $e");
      }
    });
  }

  void sendBack() async {
    try {
      // Send the boolean value as a JSON object in the body
      final response = await http.post(
        Uri.parse(espIp + sendEndpoint),
        headers: {'Content-Type': 'application/json'}, // Ensure correct header
        body: jsonEncode({'value': false}), // Send as JSON
      );

      if (response.statusCode == 200) {
        print("Successfully sent boolean to ESP32!");
      } else {
        print("Failed to send data. Status code: ${response.statusCode}");
        setState(() {
          testCheck = false;
        });
      }
    } catch (e) {
      print("Error sending boolean: $e");
      setState(() {
        testCheck = false;
      });
    }
  }

  // Show dialog when sequence is complete
  void showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sequence Complete", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("The integer sequence is complete.", style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              widget.onPopScreen(); // Call the callback when dialog is dismissed
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text("OK", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Boolean to Integer Sequence",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            widget.onPopScreen(); // Callback when dialog is dismissed
            Navigator.of(context).pop(); // Close the dialog
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section Title
              const Text(
                "Actions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 16),
              // Send Boolean Button
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () {
                  sendBooleanToESP32(true); // Send boolean to ESP32
                },
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.send_rounded),
                    SizedBox(width: 8),
                    Text("Send Boolean to ESP32"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Loading Indicator
              if (isProcessing) ...[
                const CircularProgressIndicator(
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Waiting for integer sequence from ESP32...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              // Sequence Display Section
              const Text(
                "Received Sequence:",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  receivedSequence.isNotEmpty
                      ? receivedSequence.join(", ")
                      : "No sequence received yet.",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // SequenceAnimationScreen(sequence: [1,2,3,4,5,6,5,4,3,2,1])
            ],
          ),
        ),
      ),
    );
  }

}

class SequenceAnimationScreen extends StatefulWidget {
  final List<int> sequence;

  const SequenceAnimationScreen({Key? key, required this.sequence})
      : super(key: key);

  @override
  _SequenceAnimationScreenState createState() =>
      _SequenceAnimationScreenState();
}

class _SequenceAnimationScreenState extends State<SequenceAnimationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final double _canvasSize = 300.0;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.sequence.length * 2),
    );

    // Linear animation
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Generate points along a circular path
  List<Offset> _generateCircularPath(int points, double radius) {
    final List<Offset> path = [];
    for (int i = 0; i < points; i++) {
      double angle = (2 * pi * i) / points;
      double x = _canvasSize / 2 + radius * cos(angle);
      double y = _canvasSize / 2 + radius * sin(angle);
      path.add(Offset(x, y));
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    // Generate the circular path for sequence
    final path = _generateCircularPath(widget.sequence.length, 100.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sequence Animation"),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width: _canvasSize,
          height: _canvasSize,
          color: Colors.grey.shade200,
          child: Stack(
            children: [
              // Custom Painter to draw the lines
              CustomPaint(
                size: Size(_canvasSize, _canvasSize),
                painter: PathPainter(path, _animation.value),
              ),
              // Draw the points
              for (int i = 0; i < widget.sequence.length; i++)
                Positioned(
                  left: path[i].dx - 10,
                  top: path[i].dy - 10,
                  child: Opacity(
                    opacity: _animation.value >= i / widget.sequence.length
                        ? 1.0
                        : 0.0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.sequence[i].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final List<Offset> path;
  final double progress;

  PathPainter(this.path, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final pathProgress = (path.length - 1) * progress;

    for (int i = 0; i < pathProgress.floor(); i++) {
      canvas.drawLine(path[i], path[i + 1], paint);
    }

    if (pathProgress.floor() < path.length - 1) {
      final remainingProgress = pathProgress - pathProgress.floor();
      final start = path[pathProgress.floor()];
      final end = path[pathProgress.floor() + 1];
      final animatedPoint = Offset(
        start.dx + (end.dx - start.dx) * remainingProgress,
        start.dy + (end.dy - start.dy) * remainingProgress,
      );
      canvas.drawLine(start, animatedPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
