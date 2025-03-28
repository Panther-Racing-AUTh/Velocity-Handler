import 'dart:async';
import 'dart:math';
import 'package:esp_v1/log_provider.dart';
import 'package:esp_v1/provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

class BooleanToIntegerSequence extends StatefulWidget {
  final VoidCallback onPopScreen;
  final int modes;
  BooleanToIntegerSequence({super.key, required this.onPopScreen,required this.modes});

  @override
  _BooleanToIntegerSequenceState createState() =>
      _BooleanToIntegerSequenceState();
}

class _BooleanToIntegerSequenceState extends State<BooleanToIntegerSequence> {
  final String espIp = "http://192.168.4.6";
  final String sendEndpoint = "/save_test_check";
  final String receiveEndpoint = "/test_result";
  final String receiveCurrentPosition = "/current_position";
  bool isConnectedToESP = false; // Wi-Fi connection status
  String ssid = "";
  String mySsid = "ESP8266_AP";
  late Timer _timer; // Timer for checking network
  // late Timer _timerPosition;
  bool currentPositionProcessing = false;

  bool checkProcessing = false;
  List<int> receivedSequence = [];
  int? currentPosition;
  int selectedPosition = 1;
  Timer? pollingTimer;


  @override
  void initState(){
    super.initState();
    setNetwork();
    // Timer to check Wi-Fi connection
    _timer = Timer.periodic(Duration(seconds: 5), (timer) => setNetwork());
    currentPositionProcessing = true; // Set processing state to false

    getCurrentPostion();

  }

  @override
  void dispose() {

    super.dispose();
    // _timerPosition.cancel();
    _timer.cancel();
    pollingTimer?.cancel();
  }


  void defaultValNotWifiConnected() {

    setState(() {});
  }

  Future<void> setNetwork() async {
    final info = NetworkInfo();
    if (await Permission.location.request().isGranted) {
      ssid = removeQuotes(await info.getWifiName() ?? 'None');
      setState(() {
        isConnectedToESP = (ssid == mySsid);
        if (!isConnectedToESP) defaultValNotWifiConnected();
      });
    }
  }
  String removeQuotes(String input) => input.replaceAll('"', '');

  Future<void> sendBooleanToESP32(int value) async {
    final logProvider = Provider.of<LogProvider>(context, listen: false);

    setState(() {
      checkProcessing = true;
    });

    try {
      final response = await http.post(
        Uri.parse(espIp + sendEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'position': value}),
      );

      if (response.statusCode == 200) {
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) {
            logProvider.addLog("LOG: $message");
          }
        };

        FlutterError.onError = (FlutterErrorDetails details) {
          logProvider.addLog("ERROR: ${details.exception}");
        };
        startPolling();
      } else {
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) {
            logProvider.addLog("LOG: $message");
          }
        };

        FlutterError.onError = (FlutterErrorDetails details) {
          logProvider.addLog("ERROR: ${details.exception}");
        };
      }
    } catch (e) {
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          logProvider.addLog("LOG: $message");
        }
      };

      FlutterError.onError = (FlutterErrorDetails details) {
        logProvider.addLog("ERROR: ${details.exception}");
      };
      setState(() {
        checkProcessing = false;
      });
    }
  }

  Future<void> sendPositionToESP32(int position) async {
    final logProvider = Provider.of<LogProvider>(context, listen: false);

    setState(() {
      checkProcessing = true;
    });
    try {
      final response = await http.post(
        Uri.parse(espIp + sendEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'position': position}),
      );

      if (response.statusCode == 200) {
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) {
            logProvider.addLog("LOG: $message");
          }
        };

        FlutterError.onError = (FlutterErrorDetails details) {
          logProvider.addLog("ERROR: ${details.exception}");
        };
        startPolling();

      } else {
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) {
            logProvider.addLog("LOG: $message");
          }
        };

        FlutterError.onError = (FlutterErrorDetails details) {
          logProvider.addLog("ERROR: ${details.exception}");
        };      }

    } catch (e) {

      print("Error sending position: $e");
    }
  }

  void startPolling() {
    final rpmProvider = Provider.of<RPMRangeProvider>(context, listen: false);
    pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final response = await http.get(Uri.parse(espIp + receiveEndpoint));

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final List<dynamic> modePath = responseData['mode_path'];
          currentPosition = responseData['current_position'];

          if (modePath != null) {
            setState(() {
              receivedSequence.clear();
              receivedSequence.addAll(modePath.map((e) => e as int));
              rpmProvider.updateModePath(receivedSequence);
            });
            print("Received mode_path: $modePath");
            print("Current Position: $currentPosition");

            if (receivedSequence.length >= 7) {
              timer.cancel();
              setState(() {
                sendBack();
                currentPositionProcessing = false;
              });
              showCompletionDialog();
            }
          } else {
            print("Invalid data received from ESP32.");
          }
        } else {
          print("Failed to receive data. Status code: ${response.statusCode}");
        }
        setState(() {
          checkProcessing = false;
        });
      } catch (e) {
        print("Error polling mode path: $e");
      }
    });
  }
  void getCurrentPostion() {
    final rpmProvider = Provider.of<RPMRangeProvider>(context, listen: false);


    pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final response = await http.get(Uri.parse(espIp + receiveCurrentPosition));

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          currentPosition = responseData['current_position'];

          setState(() {
            selectedPosition = currentPosition ?? 1;
          });

          print("Current Position: $currentPosition");

          // Stop polling since we got a valid position
          timer.cancel();
          pollingTimer = null; // Clear the reference

          setState(() {
            currentPositionProcessing = false; // Set processing state to false
          });

          return; // Exit the function
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
      final response = await http.post(
        Uri.parse(espIp + sendEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'value': false}),
      );

      if (response.statusCode == 200) {
        print("Successfully sent boolean to ESP32!");
      } else {
        print("Failed to send data. Status code: ${response.statusCode}");
        setState(() {
          checkProcessing = false;
        });
      }
    } catch (e) {
      print("Error sending boolean: $e");
      setState(() {
        checkProcessing = false;
      });
    }
  }

  void showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sequence Complete", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("The integer sequence is complete.", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onPopScreen();
              Navigator.of(context).pop();
            },
            child: const Text("OK", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    // if(isConnectedToESP && !_timerPosition.isActive){
    //   _timerPosition = Timer.periodic(Duration(seconds: 5), (timer) => getCurrentPostion(),);
    // }else{
    //   if(!isConnectedToESP){
    //     _timerPosition.cancel();
    //   }
    // }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Servo Motor Check"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          "Servo Motor Control",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: isConnectedToESP ? currentPositionProcessing || checkProcessing ? null : () => sendBooleanToESP32(180) : null,
                          icon: const Icon(Icons.settings),
                          label: const Text("Full Servo Position Check"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14,horizontal: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          "Select Position: $selectedPosition",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Slider(
                          value: selectedPosition.toDouble(),
                          min: 1.0,
                          max: widget.modes.toDouble(),
                          divisions: widget.modes - 1,
                          label: "$selectedPosition",
                          activeColor: Colors.deepPurple,
                          onChanged: isConnectedToESP ? (value) {
                            setState(() {
                              selectedPosition = value.toInt();
                            });
                          } : null,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: isConnectedToESP ? currentPositionProcessing || checkProcessing ? null : () => sendPositionToESP32(selectedPosition) : null,
                          icon: const Icon(Icons.send,color: Colors.white,),
                          label: const Text("Send Position",style: TextStyle(color: Colors.white),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 14,horizontal: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          currentPositionProcessing || checkProcessing ? Container(
          height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.black45,
            child: Center(
              child: Container(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  color: Colors.deepPurple.shade800,

                ),
              ),
            ),
          ) : SizedBox.shrink()
        ],
      ),
    );
  }
}
