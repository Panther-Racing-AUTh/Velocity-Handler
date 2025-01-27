import 'package:flutter/material.dart';

class SyncButtonScreen extends StatefulWidget {
  final bool isConnectedToESP;
  final Widget syncButton;
  SyncButtonScreen({required this.isConnectedToESP,required this.syncButton});

  @override
  _SyncButtonScreenState createState() => _SyncButtonScreenState();
}

class _SyncButtonScreenState extends State<SyncButtonScreen> {
  List<double> rpmRanges = []; // To store the fetched RPM ranges


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
