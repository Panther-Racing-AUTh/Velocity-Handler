import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_slider/flutter_multi_slider.dart';

class RPMVisualizer extends StatefulWidget {
  const RPMVisualizer({super.key});

  @override
  _RPMVisualizerState createState() => _RPMVisualizerState();
}

class _RPMVisualizerState extends State<RPMVisualizer> {
  // RPM values for 8 sliding points
  List<double> rpmValues = List.generate(8, (index) => (index + 1) * 1750.0); // 8 sliders, starting from 1750 and incrementing
  bool sliderEnabled = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  // Ensure continuous RPM values without overlaps or gaps
  List<double> _adjustThumbs(List<double> values) {
    values.sort();
    for (int i = 1; i < values.length - 1; i++) {
      if (values[i] <= values[i - 1]) {
        values[i] = values[i - 1] + 1;
      }
    }
    return values;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RPM Visualizer'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Enable RPM Adjustment',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      value: sliderEnabled,
                      onChanged: (value) {
                        setState(() {
                          sliderEnabled = value;
                        });
                      },
                      activeColor: Colors.blueAccent,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MultiSlider(
                            values: rpmValues,
                            onChanged: sliderEnabled
                                ? (value) => setState(() {
                              rpmValues = _adjustThumbs(value);
                            })
                                : null,
                            min: 0,
                            max: 14000,
                            divisions: 140, // Steps of 100 RPM
                            thumbColor: Colors.blueAccent,

                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('0 RPM', style: TextStyle(fontSize: 16)),
                              Text('7000 RPM', style: TextStyle(fontSize: 16)),
                              Text('14000 RPM', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'RPM Ranges:',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          // Display each RPM range
                          for (int i = 0; i < rpmValues.length - 1; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                'Mode ${i + 1}: ${rpmValues[i].toStringAsFixed(0)} - ${rpmValues[i + 1].toStringAsFixed(0)} RPM',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Center(
              child: Text(
                'Please rotate your device to landscape mode.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
