import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert'; // For decoding JSON
import 'package:http/http.dart' as http; // For making HTTP requests

class RPMTestPage extends StatefulWidget {
  const RPMTestPage({super.key});

  @override
  _RPMTestPageState createState() => _RPMTestPageState();
}

class _RPMTestPageState extends State<RPMTestPage> {
  int rpm = 0; // Default RPM value
  Timer? timer;

  // Replace with your ESP8266's IP address and endpoint
  final String esp8266Url = 'http://192.168.4.1/rpm';

  // Min and Max values for testing
  TextEditingController minController = TextEditingController();
  TextEditingController maxController = TextEditingController();
  int minRPM = 0;
  int maxRPM = 0;

  @override
  void initState() {
    super.initState();
    startFetchingRPM();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startFetchingRPM() {
    timer = Timer.periodic(Duration(seconds: 1), (_) async {
      try {
        final response = await http.get(Uri.parse(esp8266Url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            rpm = data['rpm'] ?? 0; // Assuming the ESP8266 sends {"rpm": value}
          });
        } else {
          throw Exception('Failed to fetch RPM');
        }
      } catch (e) {
        setState(() {
          rpm = 0; // Reset RPM on error
        });
        print('Error fetching RPM: $e');
      }
    });
  }

  void testMinMaxValues() {
    if (minController.text.isNotEmpty && maxController.text.isNotEmpty) {
      setState(() {
        minRPM = int.tryParse(minController.text) ?? 0;
        maxRPM = int.tryParse(maxController.text) ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWithinRange = rpm >= minRPM && rpm <= maxRPM;

    return Scaffold(
      appBar: AppBar(
        title: Text('RPM Tester with Min/Max'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Current RPM:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                '$rpm',
                style: TextStyle(
                  fontSize: 48,
                  color: isWithinRange ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(height: 40),
              TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Min RPM',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max RPM',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: testMinMaxValues,
                child: Text('Set Min/Max Values'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    rpm = 0; // Clear RPM display
                    minRPM = 0;
                    maxRPM = 0;
                    minController.clear();
                    maxController.clear();
                  });
                },
                child: Text('Reset Values'),
              ),
              SizedBox(height: 20),
              Text(
                isWithinRange
                    ? 'RPM is within the range!'
                    : 'RPM is out of range!',
                style: TextStyle(
                  fontSize: 18,
                  color: isWithinRange ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
