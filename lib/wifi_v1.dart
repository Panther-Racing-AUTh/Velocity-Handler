import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:esp_v1/console_screen.dart';
import 'package:esp_v1/drawer.dart';
import 'package:esp_v1/log_provider.dart';
import 'package:esp_v1/modify_rpm_screen.dart';
import 'package:esp_v1/provider.dart';
import 'package:esp_v1/test_page.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
void main() {
  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RPMRangeProvider()),

          ChangeNotifierProvider(create: (_) => LogProvider()),
        ],
        child: MyApp(),
      ),
    );
  }, (error, stackTrace) {
    // Capture uncaught errors
    developer.log("UNCAUGHT ERROR: $error\nSTACKTRACE: $stackTrace");
  });

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint("FLUTTER ERROR: ${details.exception}");
    developer.log("FLUTTER ERROR: ${details.exceptionAsString()}");
  };

  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      developer.log("DEBUG PRINT: $message");
    }
  };
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ESP8266ControlPage(),
    );
  }
}



final String espIp = "192.168.4.6";


class ESP8266ControlPage extends StatefulWidget {
  const ESP8266ControlPage({super.key});

  @override
  _ESP8266ControlPageState createState() => _ESP8266ControlPageState();
}

class _ESP8266ControlPageState extends State<ESP8266ControlPage> {
  String ssid = "";
  String mySsid = "ESP8266_AP";
  int rpmValue = 0; // Current RPM value
  int currentMode = 0; // Current mode (1-4)
  bool isConnectedToESP = false; // Wi-Fi connection status
  bool isSystemActive = false; // System activation status
  late Timer _timer; // Timer for checking network
  late Timer _timerPosition; // Timer for fetching data
  late Timer _timerTestCheck; // Timer for fetching data
  int check_loop=0;
  bool test_check=false;
  bool isSyncing=false;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
    ]);
    setNetwork();


    final rpmProvider=Provider.of<RPMRangeProvider>(context,listen: false);

    // Timer to check Wi-Fi connection
    _timer = Timer.periodic(Duration(seconds: 5), (timer) => setNetwork());

    // Timer to fetch data
    _timerPosition = Timer.periodic(Duration(milliseconds: rpmProvider.optionVals[rpmProvider.rpmFrequencyFetchIndex]), (timer) => getCurrentPosition());



  }

  @override
  void dispose() {
    _timer.cancel();
    _timerPosition.cancel();
    _timerTestCheck.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  String removeQuotes(String input) => input.replaceAll('"', '');

  void defaultValNotWifiConnected() {
    currentMode = 0;
    rpmValue = 0;
    isSystemActive = false;
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


  Future<void> sendBooleanToESP32(bool value) async {
    final logProvider = Provider.of<LogProvider>(context, listen: false);

    final String endpoint = "/test_check"; // Endpoint to handle boolean
      test_check=true;
      setState(() {
        
      });

    try {

      // Sending the boolean value directly as a query parameter
      final response = await http.post(
        Uri.parse(espIp + endpoint),
        body: {'value': value.toString()},
      );

      // Check if the response is successful
      if (response.statusCode == 200) {
        print("Successfully sent boolean to ESP32!");
      } else {
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) {
            logProvider.addLog("LOG: $message");
          }
        };

        FlutterError.onError = (FlutterErrorDetails details) {
          logProvider.addLog("ERROR: ${details.exception}");
        };
        test_check=false;
      
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
      test_check=false;
      
    }
  }
  Future<void> getBooleanFromESP32() async {
  final logProvider = Provider.of<LogProvider>(context, listen: false);

  final String endpoint = "/test_result"; // Endpoint to retrieve boolean
  check_loop++;
    setState(() {
      
    });
    print(check_loop);

  try {
    // Sending a GET request to fetch the boolean value
    final response = await http.get(Uri.parse(espIp + endpoint));
    
    if (response.statusCode == 200) {
      // Check the response body for boolean value ("true" or "false")
      final receivedValue = response.body;
      print("Received boolean value from ESP32: $receivedValue");
      test_check = false;
      Navigator.push(context, MaterialPageRoute(builder: (context) => TestSuccessWidget(successMessage: "Received boolean value from ESP32: $receivedValue",onContinue: () {
        Navigator.pop(context);
        check_loop=0;
      },)));

      // You can now use the receivedValue in your app logic
    } else {
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          logProvider.addLog("LOG: $message");
        }
      };

      FlutterError.onError = (FlutterErrorDetails details) {
        logProvider.addLog("ERROR: ${details.exception}");
      };
      // Wait for 60 seconds before going to the catch block (simulating retry or delay)
      
    }

    test_check = false;

  } catch (e) {
    // Wait for 60 seconds before handling the error in the catch block
    await Future.delayed(Duration(minutes: 1));
    test_check = false;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        logProvider.addLog("LOG: $message");
      }
    };

    FlutterError.onError = (FlutterErrorDetails details) {
      logProvider.addLog("ERROR: ${details.exception}");
    };
  }
}
  Future<void> initializePosition() async {
    final logProvider = Provider.of<LogProvider>(context, listen: false);

    RPMRangeProvider rangeProvider = Provider.of<RPMRangeProvider>(context,listen:false);

    if (!isConnectedToESP) return;
    try {
      final response = await http.get(Uri.parse("http://$espIp/data"));
      if (response.statusCode == 200) {
        setState(() {
          rpmValue = int.parse(response.body);
          currentMode=rangeProvider.getModeFromRPM(rpmValue);
        });
      }
    } catch (e) {
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          logProvider.addLog("LOG: $message");
        }
      };

      FlutterError.onError = (FlutterErrorDetails details) {
        logProvider.addLog("ERROR: ${details.exception}");
      };    }
  }

  Future<void> getCurrentPosition() async {
    final logProvider = Provider.of<LogProvider>(context, listen: false);

    RPMRangeProvider rangeProvider = Provider.of<RPMRangeProvider>(context,listen:false);

    if (!isConnectedToESP) return;

    try {
      final response = await http.get(Uri.parse("http://$espIp/data"));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          rpmValue = data['rpm'] ?? 0;
          currentMode=rangeProvider.getModeFromRPM(rpmValue);
        });
      }
    } catch (e) {
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          logProvider.addLog("LOG: $message");
        }
      };

      FlutterError.onError = (FlutterErrorDetails details) {
        logProvider.addLog("ERROR: ${details.exception}");
      };    }
  }

  Widget _statusColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 18, color: color,fontWeight: FontWeight.bold)),
      ],
    );
  }
  Widget OvalSegmentSelector() {
    final rpmProvider = Provider.of<RPMRangeProvider>(context, listen: false);

    // Segment width
    final double segmentWidth = 100.0; // Width of each segment
    double segmentSpacing = 20.0; // Padding on left and right edges
    if(rpmProvider.rpmFrequencyFetchIndex == 0){
      segmentSpacing =20.0;
    }else if(rpmProvider.rpmFrequencyFetchIndex == 1){
      segmentSpacing=28.0;
    }else{
      segmentSpacing=36.0;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Oval Shape Container
        Container(
          width: segmentWidth * rpmProvider.options.length + segmentSpacing,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[300]!, Colors.grey[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(40), // Oval Shape
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Highlighted Section (Animated)
              AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: rpmProvider.rpmFrequencyFetchIndex * segmentWidth + segmentSpacing / 2,
                top: 10,
                child: Container(
                  width: segmentWidth - 10,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.blueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              // Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(rpmProvider.options.length, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        rpmProvider.updateSelectedIndex(index);
                        _timerPosition.cancel();
                        _timerPosition = Timer.periodic(
                          Duration(milliseconds: rpmProvider.optionVals[rpmProvider.rpmFrequencyFetchIndex]),
                              (timer) => getCurrentPosition(),
                        );
                      });
                    },
                    child: Container(
                      width: segmentWidth,
                      alignment: Alignment.center,
                      child: Text(
                        rpmProvider.options[index],
                        style: TextStyle(
                          fontSize: 16,
                          color: rpmProvider.rpmFrequencyFetchIndex == index
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Alignment _getAlignmentForIndex(int index) {
    switch (index) {
      case 0:
        return Alignment.centerLeft;
      case 1:
        return Alignment.center;
      case 2:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
  Widget modeText(int mode, int currentMode) {
    return Text(
      "$mode",
      style: TextStyle(
        fontSize: currentMode == mode ? 35 : 30,
        color: currentMode == mode ? Colors.green : Colors.grey,
        fontWeight: currentMode == mode ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
  Future<void> handleSync() async {
    await syncAndFetchData(espIp, isConnectedToESP, isSyncing,(fetchedRanges) {
      // Provide the fetched ranges to the callback
      updateRanges(fetchedRanges.cast<int>());
    });
    setState(() {

    });
    // Optionally display a success message
    print('Sync Complete!');
  }
@override
Widget build(BuildContext context) {
  final rpmProvider=Provider.of<RPMRangeProvider>(context,listen: false);

  return Scaffold(
    drawer: CustomDrawer(),
    key: scaffoldKey, // Assign the global key here
    backgroundColor: Colors.grey[100], 
    body: Stack(
      children: [

        SafeArea(
          child: test_check ? ProcessingPage(testCheck: test_check,) : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [


                  const SizedBox(height: 30),

                  // Wi-Fi Status Card
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            "Wi-Fi Status",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isConnectedToESP ? Icons.wifi : Icons.wifi_off,
                                color: isConnectedToESP ? Colors.green : Colors.red,
                                size: 26,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isConnectedToESP ? "Connected" : "Disconnected",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isConnectedToESP ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  OvalSegmentSelector(),


                  const SizedBox(height: 15),
                  // RPM Display
                  Container(
                    width: MediaQuery.of(context).size.width * .6,
                    child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          const Text(
                            "RPM",
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                            child: Text(
                              rpmValue.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 50,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                  const SizedBox(height: 25),

                  // Mode Selection
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text(
                            "Mode",
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(rpmProvider.ranges.length - 1, (index) => modeText(index + 1, currentMode),)
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // CHANGE Button (Gradient)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SyncButtonScreen(isConnectedToESP: isConnectedToESP,syncButton: syncButton(
                        isConnectedToESP: isConnectedToESP,
                        onRangesFetched: updateRanges,
                      ),),
                      GestureDetector(
                        onTap: isConnectedToESP ? () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => MultiSliderExample()));
                          print(rpmProvider.ranges);
                        } : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 6),
                            ],
                          ),
                          child: const Text(
                            "CHANGE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // TEST Button (Elevated)
                  ElevatedButton(
                    onPressed: isConnectedToESP ? () {
                      _timerPosition.cancel();
                      Navigator.push(context, MaterialPageRoute(builder: (context) => BooleanToIntegerSequence(modes: rpmProvider.ranges.length-1,onPopScreen: () {
                        setState(() {
                          _timerPosition = Timer.periodic(Duration(milliseconds: rpmProvider.optionVals[rpmProvider.rpmFrequencyFetchIndex]), (timer) => getCurrentPosition());

                          print("object");

                        });
                      },),));
                    } : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 10,
                      minimumSize: Size(MediaQuery.of(context).size.width, 50),
                    ),
                    child: const Text(
                      "TEST",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ConsoleLogPage()),
                      );
                    },
                    child: Text("Open Console"),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
            top: 30,
            left: 10,
            child: IconButton(
                onPressed: () {
                //  scaffoldKey.currentState?.openDrawer();  // Opens the drawer

                },
                style: ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.all(2)),
                  backgroundColor: WidgetStatePropertyAll(Colors.grey.withOpacity(0.3))
                ),
                icon: Icon(Icons.menu)
            )
        ),
      ],
    ),
  );
}

  Future<void> initializeSync() async {
    // Cancel any existing timer before initializing sync
    _timerPosition.cancel();

    if (!isConnectedToESP) return; // Check if connected to ESP

    setState(() {
      isSyncing = true;
    });

    try {
      // Sending the sync status
      final response = await http.post(
        Uri.parse("http://$espIp/sync"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"sync": true}),
      );

      if (response.statusCode == 200) {
        print("Sync status sent successfully");

        // Fetch RPM ranges after syncing
        final rangeResponse = await http.get(Uri.parse("http://$espIp/ranges"));
        if (rangeResponse.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(rangeResponse.body);
          List<int> rpmRanges = [];
          print(data);
          for (int i = 0; i < data['ranges'].length; i++) {
            rpmRanges.add(int.parse(data['ranges'][i][0].toString()));
            if (i == data['ranges'].length - 1) {
              rpmRanges.add(int.parse(data['ranges'][i][1].toString()));
            }
          }

          // Call the callback with the fetched RPM ranges
          updateRanges(rpmRanges);
        } else {
          print("Failed to fetch ranges");
        }
      } else {
        print("Failed to send sync status");
      }
    } catch (e) {
      print("Error in sync or fetching data: $e");
    } finally {
      // Using Provider to access rpmFrequencyFetchIndex and set the timer
      final rpmProvider = Provider.of<RPMRangeProvider>(context, listen: false);
      _timerPosition = Timer.periodic(
        Duration(milliseconds: rpmProvider.optionVals[rpmProvider.rpmFrequencyFetchIndex]),
            (timer) => getCurrentPosition(),
      );

      setState(() {
        isSyncing = false;
      });
    }
  }

// Function to handle sending sync data and fetching ranges
  Future<void> syncAndFetchData(String espIp, bool isConnectedToESP,bool isSyncing, Function(List<int>) onRangesFetched) async {
    _timerPosition.cancel();
    if (!isConnectedToESP) return;

    setState(() {
      isSyncing = true;

    });
    try {
      // Sending the sync status
      final response = await http.post(
        Uri.parse("http://$espIp/sync"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"sync": true}),
      );

      if (response.statusCode == 200) {
        print("Sync status sent successfully");

        // Fetch RPM ranges after syncing
        final rangeResponse = await http.get(Uri.parse("http://$espIp/ranges"));
        if (rangeResponse.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(rangeResponse.body);
          List<int> rpmRanges = [];
          print(data);
          for(int i=0;i<data['ranges'].length;i++){
            rpmRanges.add(int.parse(data['ranges'][i][0].toString()));
            if(i == data['ranges'].length - 1){
              rpmRanges.add(int.parse(data['ranges'][i][1].toString()));
            }
          }

          // Call the callback with the fetched RPM ranges
          onRangesFetched(rpmRanges);
        } else {
          print("Failed to fetch ranges");
        }
      } else {
        print("Failed to send sync status");
      }

    } catch (e) {
      print("Error in sync or fetching data: $e");
    } finally {
      final rpmProvider=Provider.of<RPMRangeProvider>(context,listen: false);
      _timerPosition = Timer.periodic(Duration(milliseconds: rpmProvider.optionVals[rpmProvider.rpmFrequencyFetchIndex]), (timer) => getCurrentPosition());

      setState(() {
        isSyncing = false;
      });
    }
  }
  void updateRanges(List<int> fetchedRanges) {
    final rpmProvider=Provider.of<RPMRangeProvider>(context,listen: false);
    setState(() {
       rpmProvider.updateAllRanges(fetchedRanges);
    });
  }
// Sync button widget function
  Widget syncButton(
      {required bool isConnectedToESP,
        required Function(List<int>) onRangesFetched}) {
    bool isSyncing = false;

    // Function to trigger sync operation
    void handleSync() async {
      isSyncing = true;

      await syncAndFetchData(espIp, isConnectedToESP, isSyncing,(fetchedRanges) {
        // Provide the fetched ranges to the callback
        onRangesFetched(fetchedRanges.cast<int>());
      });

      // Optionally display a success message
      print('Sync Complete!');
    }

    return ElevatedButton(
      onPressed: isConnectedToESP
          ? () {
        handleSync();
      }
          : null,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      child: isSyncing
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(width: 10),
          Text("Syncing...", style: TextStyle(color: Colors.white)),
        ],
      )
          : Text("Sync"),
    );
  }

}


class SyncButtonScreen extends StatefulWidget {
  final bool isConnectedToESP;
  final Widget syncButton;
  SyncButtonScreen({required this.isConnectedToESP,required this.syncButton});

  @override
  _SyncButtonScreenState createState() => _SyncButtonScreenState();
}

class _SyncButtonScreenState extends State<SyncButtonScreen> {
  List<int> rpmRanges = []; // To store the fetched RPM ranges


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.syncButton,
          SizedBox(height: 20),
          if (rpmRanges.isNotEmpty)
            Text(
              "RPM Ranges: ${rpmRanges.join(", ")}",
              style: TextStyle(fontSize: 16),
            ),
        ],
      ),
    );
  }
}
class TestSuccessWidget extends StatelessWidget {
  final String successMessage; // Optional message to show the success reason
  final VoidCallback onContinue; // Callback function to proceed after success

  const TestSuccessWidget({
    Key? key,
    required this.successMessage,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 50,
            color: Colors.greenAccent,
          ),
          const SizedBox(height: 10),
          Text(
            successMessage,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onContinue, // Trigger the continue callback
            child: const Text("Continue"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProcessingPage extends StatefulWidget {
  final bool testCheck;

  ProcessingPage({Key? key, required this.testCheck}) : super(key: key);

  @override
  _ProcessingPageState createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],  // Light background color
      
      body: Center(
        child: ProcessingPageIndicator(
          isProcessing: widget.testCheck,
          message: "Please wait while processing test...", // Clear and friendly message
        ),
      ),
    );
  }
}

class ProcessingPageIndicator extends StatelessWidget {
  final bool isProcessing;
  final String message;

  const ProcessingPageIndicator({
    Key? key,
    required this.isProcessing,
    this.message = "Processing...",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isProcessing
          ? _buildProcessingView(context)
          : const SizedBox.shrink(), // If not processing, show nothing
    );
  }

  Widget _buildProcessingView(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * .4,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 4), // Soft shadow
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 6,  // Thicker loading circle
            valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 33, 21, 146)),
          ),
          const SizedBox(height: 30),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}




class TestFailedWidget extends StatelessWidget {
  final String errorMessage; // Optional message to show the reason for failure
  final VoidCallback onRetry; // Callback function to retry the operation

  const TestFailedWidget({
    Key? key,
    required this.errorMessage,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 15),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onRetry, // Trigger the retry callback
                  child: const Text(
                    "Retry",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
