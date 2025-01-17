import 'dart:async';
import 'package:esp_v1/provider.dart';
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
        title: const Text("Boolean to Integer Sequence", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            widget.onPopScreen(); // Call the callback when dialog is dismissed
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () {
                  sendBooleanToESP32(true); // Send boolean to ESP32
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blueAccent, // Button color
                  foregroundColor: Colors.white, // Text color
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text("Send Boolean to ESP32"),
              ),
              const SizedBox(height: 20),
              if (isProcessing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                const Text("Waiting for integer sequence from ESP32...",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 20),
              Text(
                "Received Sequence:",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8), // Adds some space between the title and sequence
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1), // Soft background color
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                  border: Border.all(color: Colors.blueAccent, width: 1.5), // Border around the container
                ),
                child: Text(
                  receivedSequence.isNotEmpty
                      ? receivedSequence.join(", ")
                      : "No sequence received yet", // Show a default message if the list is empty
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueAccent, // Blue color for the sequence
                  ),
                  textAlign: TextAlign.center, // Center the text
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}
