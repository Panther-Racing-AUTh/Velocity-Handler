import 'package:flutter_application_1/provider.dart';
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
  List<Color> sliderColors= [];
  double minSliderValue = 0;
  double maxSliderValue = 14000;
  final String espIp = "192.168.4.1";

  @override
  void initState() {
    super.initState();
    final rpmProvider = Provider.of<RPMRangeProvider>(context, listen: false);
    sliderValues = rpmProvider.ranges;
    sliderColors=generateHeaterGradientColors(sliderValues);
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

  // Update slider values to ensure proper sorting and constraints
  void updateSliderValues(List<double> values) {
    setState(() {
      for (int i = 1; i < values.length - 1; i++) {
        values[i] = values[i].clamp(values[i - 1] + 1, values[i + 1] - 1);
      }
      values.first = minSliderValue;
      values.last = maxSliderValue;

      sliderValues = values;

    });
  }

  Future<void> saveAndSendRPMData() async {
    final rpmProvider = Provider.of<RPMRangeProvider>(context, listen: false);
    final tempSliderValues=[];
    tempSliderValues.addAll(sliderValues);
    tempSliderValues.remove(tempSliderValues.first);
    tempSliderValues.remove(tempSliderValues.last);
    rpmProvider.updateAllRanges(sliderValues);
    Map<String, dynamic> jsonRanges = {
      "ranges": List.generate(tempSliderValues.length, (index) => tempSliderValues[index])
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

  Future<void> addSliderPoint() async {
    double? newValue = await showDialog<double>(
      context: context,
      builder: (context) {
        double tempValue = (minSliderValue + maxSliderValue) / 2;
        return AlertDialog(
          title: const Text("Add Slider Point"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter the value for the new slider point:"),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  tempValue = double.tryParse(value) ?? tempValue;
                },
                decoration: const InputDecoration(hintText: "Enter value"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(tempValue);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );

    if (newValue != null) {
      if (sliderValues.contains(newValue)) {
        // Show an error message if the value already exists
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("The value $newValue already exists!"),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (newValue > minSliderValue && newValue < maxSliderValue) {
        setState(() {
          sliderValues.add(newValue);
          sliderValues.sort();
          sliderColors.clear();
          sliderColors = generateHeaterGradientColors(sliderValues);
        });
      }
    }
  }

  Future<void> removeSliderPoint() async {
    double? selectedValue = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade200,
          title: const Text(
            "Remove Slider Point",
            style: TextStyle(color: Colors.black),
          ),
          contentPadding: const EdgeInsets.only(top: 10, left: 10, right: 10),
          content: Container(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select a slider point to remove:",
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: sliderValues
                          .where((value) => value != minSliderValue && value != maxSliderValue)
                          .map((value) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop(value);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                )
                              ],
                            ),
                            child: Text(
                              formatSliderValue(value),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 10),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );

    if (selectedValue != null) {
      setState(() {
        sliderValues.remove(selectedValue);
        sliderColors.clear();
        sliderColors = generateHeaterGradientColors(sliderValues);
      });
    }
  }
  List<Color> generateHeaterGradientColors(List<double> values) {
    if (values.isEmpty) return [];
    final int length = values.length;
    return List<Color>.generate(
      length,
          (index) {
        final double t = index / (length - 1);
        if (t < 0.5) {
          // Interpolate from blue to yellow
          return Color.lerp(Colors.blue, Colors.yellow, t * 2) ?? Colors.blueAccent;
        } else {
          // Interpolate from yellow to red
          return Color.lerp(Colors.yellow, Colors.red, (t - 0.5) * 2) ?? Colors.yellowAccent;
        }
      },
    );
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
                      rangeColors: sliderColors,
                      activeTrackSize: 6,
                      inactiveTrackSize: 6,
                      onChanged: updateSliderValues,
                      selectedIndicator: (value) => IndicatorOptions(
                        formatter: (value) => formatSliderValue(value),
                      ),

                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          sliderValues.length - 1,
                              (index) {
                            double startValue = sliderValues[index];
                            double endValue = sliderValues[index + 1];

                            return Row(
                              children: [
                                Column(
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
                                ),
                                SizedBox(width: 30,)
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Add and Remove Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: addSliderPoint,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.greenAccent,
                    ),
                    child: const Text("Add Point"),
                  ),
                  ElevatedButton(
                    onPressed: removeSliderPoint,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text("Remove Point"),
                  ),
                ],
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
