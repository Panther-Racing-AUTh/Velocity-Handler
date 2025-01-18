import 'package:esp_v1/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_slider/flutter_multi_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

class MultiSliderExample extends StatefulWidget {
  const MultiSliderExample({super.key});

  @override
  _MultiSliderExampleState createState() => _MultiSliderExampleState();
}

class _MultiSliderExampleState extends State<MultiSliderExample> {
  List<double> sliderValues = [];
  double minSliderValue = 0;
  double maxSliderValue = 14000;
  final String espIp = "192.168.4.1";

  @override
  void initState() {
    super.initState();
    final rpmProvider=Provider.of<RPMRangeProvider>(context,listen: false);
    sliderValues= rpmProvider.ranges;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  // Update slider values to ensure exactly 4 ranges with no gaps
  void updateSliderValues(List<double> values) {
    setState(() {
      for (int i = 1; i < values.length - 1; i++) {
        // Clamp intermediate points only, ensuring no gaps or overlaps
        values[i] = values[i].clamp(values[i - 1] + 1, values[i + 1] - 1);
      }
      // Prevent modification of the first and last points
      values.first = minSliderValue;
      values.last = maxSliderValue;

      sliderValues = values;
    });
  }


  Future<void> saveAndSendRPMData() async {
    final rpmProvider=Provider.of<RPMRangeProvider>(context,listen: false);

    rpmProvider.updateAllRanges(sliderValues);
    Map<String, dynamic> jsonRanges = {
      "ranges": List.generate(
        sliderValues.length,
            (index) => sliderValues[index]
      )
    };
    print("Sending JSON to ESP: ${jsonEncode(jsonRanges)}");

    try {
      final response = await http.post(
        Uri.parse("http://$espIp/save_ranges"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(jsonRanges),
      );

      if (response.statusCode == 200) {
        print("Successfully sent RPM data to ESP8266!");
      } else {
        print("Failed to send RPM data. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending data to ESP: $e");
    }
  }

  String formatSliderValue(double value) {
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "MultiSlider - RPM Control",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Info"),
                  content: const Text("Adjust the RPM values using the sliders."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // MultiSlider Widget
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey[100],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    MultiSlider(
                      values: sliderValues,
                      min: minSliderValue,
                      max: maxSliderValue,
                      divisions: maxSliderValue.toInt() ~/ 100,
                      color: Colors.blueAccent,
                      onChanged: updateSliderValues,
                      selectedIndicator: (value) => IndicatorOptions(
                        formatter: (value) => formatSliderValue(value),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 15,
                      runSpacing: 10,
                      children: List.generate(
                        sliderValues.length - 1,
                            (index) {
                          double startValue = sliderValues[index];
                          double endValue = sliderValues[index + 1];

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Text(
                                    "${formatSliderValue(startValue)} - ${formatSliderValue(endValue)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                                ),
                                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                elevation: 2,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Range ${index + 1}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: () {
                  saveAndSendRPMData();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blueAccent,
                  elevation: 5,
                  shadowColor: Colors.blueAccent.withOpacity(0.5),
                ),
                child: const Text(
                  "Save RPM Ranges",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
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
