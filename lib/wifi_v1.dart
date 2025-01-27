import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_application_1/drawer.dart';
import 'package:flutter_application_1/model/progres_model.dart';
import 'package:flutter_application_1/model/sync_model.dart';
import 'package:flutter_application_1/model/test_model.dart';
import 'package:flutter_application_1/modify_rpm_screen.dart';
import 'package:flutter_application_1/provider.dart';
import 'package:flutter_application_1/test_page.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';


class ESP8266ControlPage extends StatefulWidget {
  const ESP8266ControlPage({super.key});

  @override
  _ESP8266ControlPageState createState() => _ESP8266ControlPageState();
}

class _ESP8266ControlPageState extends State<ESP8266ControlPage> {
  final String espIp = "192.168.4.1"; // ESP8266 IP address
  String ssid = "";
  String mySsid = "ESP8266_AP";
  double rpmValue = 0.0; // Current RPM value
  int currentMode = 0; // Current mode (1-4)
  bool isConnectedToESP = false; // Wi-Fi connection status
  bool isSystemActive = false; // System activation status
  late Timer _timer; // Timer for checking network
  late Timer _timerPosition; // Timer for fetching data
  late Timer _timerTestCheck; // Timer for fetching data
  int check_loop=0;
  bool test_check=false;
  bool _isAnimating=false;
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
    initializePosition();
    final rpmProvider=Provider.of<RPMRangeProvider>(context,listen: false);
    rpmProvider.initializeAppIndex(getPlatformValue());
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
    rpmValue = 0.0;
    isSystemActive = false;
    setState(() {});
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final rpmProvider = Provider.of<RPMRangeProvider>(context,listen: false);
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white54,
      ),
      title: rpmProvider.isMenuVisible
          ? Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
              ),
            )
          : null,
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: Colors.blueGrey[700],
      hoverColor: Colors.blueGrey[800],
    );
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
    final String espIp = "http://192.168.4.1"; // Your ESP32's IP
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
        print("Failed to send data. Status code: ${response.statusCode}");
        test_check=false;
      
      }
      
    } catch (e) {
      print("Error: $e");
      test_check=false;
      
    }
  }
  Future<void> getBooleanFromESP32() async {
  final String espIp = "http://192.168.4.1"; // Your ESP32's IP
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
      print("Failed to receive data. Status code: ${response.statusCode}");
      
      // Wait for 60 seconds before going to the catch block (simulating retry or delay)
      
    }

    test_check = false;

  } catch (e) {
    // Wait for 60 seconds before handling the error in the catch block
    await Future.delayed(Duration(minutes: 1));
    test_check = false;
    print("Error: $e");
  }
}
  Future<void> initializePosition() async {
    RPMRangeProvider rangeProvider = Provider.of<RPMRangeProvider>(context,listen:false);

    if (!isConnectedToESP) return;
    try {
      final response = await http.get(Uri.parse("http://$espIp/data"));
      if (response.statusCode == 200) {
        setState(() {
          rpmValue = double.parse(response.body);
          currentMode=rangeProvider.getModeFromRPM(rpmValue);
        });
      }
    } catch (e) {
      print("Error initializing position: $e");
    }
  }

  Future<void> getCurrentPosition() async {
    RPMRangeProvider rangeProvider = Provider.of<RPMRangeProvider>(context,listen:false);

    if (!isConnectedToESP) return;

    try {
      final response = await http.get(Uri.parse("http://$espIp/data"));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          rpmValue = data['rpm']?.toDouble() ?? 0.0;
          currentMode=rangeProvider.getModeFromRPM(rpmValue);
        });
      }
    } catch (e) {
      print("Error fetching current position: $e");
    }
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
@override
Widget build(BuildContext context) {
  final rpmProvider = Provider.of<RPMRangeProvider>(context, listen: false);

  if (rpmProvider.appIndex == 2 || rpmProvider.appIndex == 3) {
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
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => MultiSliderExample()));
                          print(rpmProvider.ranges);
                        },
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
                    onPressed: () {
                      _timerPosition.cancel();
                      Navigator.push(context, MaterialPageRoute(builder: (context) => BooleanToIntegerSequence(onPopScreen: () {
                        _timerPosition = Timer.periodic(Duration(milliseconds: rpmProvider.optionVals[rpmProvider.rpmFrequencyFetchIndex]), (timer) => getCurrentPosition());
                        setState(() {
                          print("object");

                        });
                      },),));
                    },
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => SequenceAnimationScreen(sequence: [1,2,3,4,5,6]),));
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

  }else if(rpmProvider.appIndex == 4 || rpmProvider.appIndex == 5 || rpmProvider.appIndex == 6){
      final rpmProvider = Provider.of<RPMRangeProvider>(context, listen: false);

     return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Main Content Area
          Row(
            children: [
              // Collapsible Side Menu
              AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: rpmProvider.isMenuVisible ? 250 : 70,
            color: Colors.blueGrey[900],
            child: Column(
              children: [
                // App Logo or Header
                Container(
                  height: 80,
                  alignment: Alignment.center,
                  color: Colors.blueGrey[800],
                  child: rpmProvider.isMenuVisible
                      ? const Text(
                          "MyApp",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
                const Divider(color: Colors.white54),
                // Menu Items
                Expanded(
                  child: ListView(
                    children: [
                      _buildMenuItem(
                          icon: Icons.home,
                          title: "Home",
                          isSelected: rpmProvider.isMenuVisible == "Home",
                          onTap: () {
                          }),
                       _buildMenuItem(
                          icon: Icons.home,
                          title: "Home",
                          isSelected: rpmProvider.isMenuVisible == "Home",
                          onTap: () {
                          }),
                           _buildMenuItem(
                          icon: Icons.home,
                          title: "Home",
                          isSelected: rpmProvider.isMenuVisible == "Home",
                          onTap: () {
                          }),
                           _buildMenuItem(
                          icon: Icons.home,
                          title: "Home",
                          isSelected: rpmProvider.isMenuVisible == "Home",
                          onTap: () {
                          }),
                           _buildMenuItem(
                          icon: Icons.home,
                          title: "Home",
                          isSelected: rpmProvider.isMenuVisible == "Home",
                          onTap: () {
                          }),
                    ],
                  ),
                ),
                // Collapse/Expand Button
                IconButton(
                  icon: Icon(
                    rpmProvider.isMenuVisible ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      rpmProvider.updateMenuVisible(rpmProvider.isMenuVisible);
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
// Main Content
              Expanded(
                child: Stack(
                  children: [
                    SafeArea(
                      child: test_check
                          ? ProcessingPage(testCheck: test_check)
                          : SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40.0, vertical: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 30),
                                    // Wi-Fi Status Card
                                    Card(
                                      margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width* .2),
                                      elevation: 6,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const Text(
                                              "Wi-Fi Status",
                                              style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 10),
                                            Center(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  isConnectedToESP
                                                      ? Icons.wifi
                                                      : Icons.wifi_off,
                                                  color: isConnectedToESP
                                                      ? Colors.green
                                                      : Colors.red,
                                                  size: 26,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  isConnectedToESP
                                                      ? "Connected"
                                                      : "Disconnected",
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: isConnectedToESP
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            )
                                            ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 25),
                                    // RPM Display
                                    Center(
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.4,
                                        child: Card(
                                          elevation: 8,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 24),
                                            child: Column(
                                              children: [
                                                const Text(
                                                  "RPM",
                                                  style: TextStyle(
                                                      fontSize: 26,
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                                const SizedBox(height: 10),
                                                AnimatedSwitcher(
                                                  duration: const Duration(
                                                      milliseconds: 500),
                                                  transitionBuilder: (child,
                                                          animation) =>
                                                      ScaleTransition(
                                                          scale: animation,
                                                          child: child),
                                                  child: Text(
                                                    rpmValue.toStringAsFixed(0),
                                                    style: const TextStyle(
                                                      fontSize: 50,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.blueAccent,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 25),
                                    // Mode Selection
                                    Card(
                                      elevation: 8,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          children: [
                                            const Text(
                                              "Mode",
                                              style: TextStyle(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                            const SizedBox(height: 15),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: List.generate(
                                                rpmProvider.ranges.length - 1,
                                                (index) => modeText(
                                                    index + 1, currentMode),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    // Change Button
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SyncButtonScreen(
                                          isConnectedToESP: isConnectedToESP,
                                          syncButton: syncButton(
                                            isConnectedToESP: isConnectedToESP,
                                            onRangesFetched: updateRanges,
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    MultiSliderExample(),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 40, vertical: 16),
                                            backgroundColor: Colors.blueAccent,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                          ),
                                          child: const Text(
                                            "CHANGE",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 30),
                                    // Test Button
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _timerPosition.cancel();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BooleanToIntegerSequence(
                                                onPopScreen: () {
                                                  _timerPosition =
                                                      Timer.periodic(
                                                    Duration(
                                                        milliseconds: rpmProvider
                                                                .optionVals[
                                                            rpmProvider
                                                                .rpmFrequencyFetchIndex]),
                                                    (timer) =>
                                                        getCurrentPosition(),
                                                  );
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 40, vertical: 16),
                                          backgroundColor: Colors.blueAccent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          elevation: 10,
                                        ),
                                        child: const Text(
                                          "TEST",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Menu Toggle Button
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              icon: Icon(
                rpmProvider.isMenuVisible ? Icons.close : Icons.menu,
                size: 30,
                color: Colors.black54,
              ),
              onPressed: () {
                setState(() {
                  rpmProvider.updateMenuVisible(rpmProvider.isMenuVisible);
                });
                
              },

            ),
          ),
        ],
      ),
    );


  }else{
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
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => MultiSliderExample()));
                          print(rpmProvider.ranges);
                        },
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
                    onPressed: () {
                      _timerPosition.cancel();
                      Navigator.push(context, MaterialPageRoute(builder: (context) => BooleanToIntegerSequence(onPopScreen: () {
                        _timerPosition = Timer.periodic(Duration(milliseconds: rpmProvider.optionVals[rpmProvider.rpmFrequencyFetchIndex]), (timer) => getCurrentPosition());
                        setState(() {
                          print("object");

                        });
                      },),));
                    },
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => SequenceAnimationScreen(sequence: [1,2,3,4,5,6]),));
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
  
}

// Function to handle sending sync data and fetching ranges
  Future<void> syncAndFetchData(String espIp, bool isConnectedToESP, Function(List<double>) onRangesFetched) async {
    _timerPosition.cancel();
    if (!isConnectedToESP) return;

    bool isSyncing = true;

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
          List<double> rpmRanges = [];
          for(int i=0;i<data['ranges'].length;i++){
            rpmRanges.add(double.parse(data['ranges'][i].toString()));
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

      isSyncing = false;
    }
  }
  void updateRanges(List<double> fetchedRanges) {
    final rpmProvider=Provider.of<RPMRangeProvider>(context,listen: false);
    setState(() {
       rpmProvider.updateAllRanges(fetchedRanges);
    });
  }
// Sync button widget function
  Widget syncButton(
      {required bool isConnectedToESP,
        required Function(List<double>) onRangesFetched}) {
    bool isSyncing = false;
    String espIp = "192.168.4.1"; // ESP8266 IP address

    // Function to trigger sync operation
    Future<void> handleSync() async {
      isSyncing = true;

      await syncAndFetchData(espIp, isConnectedToESP, (fetchedRanges) {
        isSyncing = false;
        // Provide the fetched ranges to the callback
        onRangesFetched(fetchedRanges);
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







