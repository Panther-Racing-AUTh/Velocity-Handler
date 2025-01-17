import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usb_serial/usb_serial.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  UsbPort? _port;
  String _status = "Disconnected";
  String _receivedData = "";
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listDevices();
  }

  void _listDevices() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();

    if (devices.isNotEmpty) {
      _connectToDevice(devices.first);
    } else {
      setState(() {
        _status = "No devices found";
      });
    }
  }

  void _connectToDevice(UsbDevice device) async {
    _port = await device.create();
    if (await _port?.open() ?? false) {
      setState(() {
        _status = "Connected to ${device.deviceId}";
      });

      _port?.setDTR(true);
      _port?.setRTS(true);
      _port?.setPortParameters(115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

      _port?.inputStream?.listen((data) {
        setState(() {
          _receivedData += String.fromCharCodes(data);
        });
      });
    } else {
      setState(() {
        _status = "Failed to connect";
      });
    }
  }

  void _sendMessage() async {
    if (_port != null && _messageController.text.isNotEmpty) {
      String message = '${_messageController.text}\n';
      _port?.write(Uint8List.fromList(message.codeUnits));
    }
  }

  @override
  void dispose() {
    _port?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('ESP32 Serial Communication'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text("Status: $_status"),
              const SizedBox(height: 10),
              Text("Received Data: $_receivedData"),
              const SizedBox(height: 20),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(labelText: "Enter Message"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _sendMessage,
                child: Text("Send Message"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
